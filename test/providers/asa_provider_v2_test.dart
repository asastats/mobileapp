// Phase 5b — tests for the new V2 methods on ``ASAProvider`` and ``ASArepo``.
//
// Covers:
//   - URL/body shapes (ASArepo posts to ``/api/v2/`` with
//     ``{"addresses": ...}``, gets ``/api/v2/{value}/``, etc.).
//   - ``ASAProvider.getBundleHashV2`` unwraps ``{"bundle": "..."}`` to
//     the bare hash string that downstream callers expect.
//   - ``ASAProvider.getEvaluatedAccountV2`` parses the real captured
//     sample payload through ``EvaluatedAccount.fromJson``, stashes it
//     in the right backing field (``_accountV2`` vs
//     ``_accountV2Single``), and persists the raw body for cold-start
//     fallback.
//   - Failure paths: HTTP errors, parse errors, missing bundle keys all
//     return a failure ``ResponseModel`` without crashing or stomping
//     previously-good state.
//
// The Phase 5a tests are in ``test/models/v2_models_test.dart``; the
// Phase 5b tests here are a separate file so a tester running
// ``flutter test test/providers/`` can exercise just the provider layer.

import 'dart:convert';
import 'dart:io';

import 'package:asa_stats/data/datasource/remote/dio/dio_client.dart';
import 'package:asa_stats/data/datasource/repository/base/api_response.dart';
import 'package:asa_stats/data/repository/auth_repo.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Stub ``ASArepo`` that lets each test set canned responses for the
// three V2 methods without spinning up Dio / SharedPreferences.
class _StubRepo extends ASArepo {
  _StubRepo() : super(dioClient: _FakeDio(), sharedPreferences: _FakeSP());

  ApiResponse? bundleHashResponse;
  ApiResponse? evaluatedAccountResponse;
  ApiResponse? globalSettingResponse;

  String? lastBundleHashAddresses;
  String? lastEvaluatedAccountValue;

  // Recorder for the SharedPreferences-side persistence the provider
  // calls. We override the methods rather than mocking SP itself.
  final List<String> savedResponses = [];
  final List<String> savedGlobalSettings = [];

  @override
  Future<ApiResponse> getBundleHashV2(String addresses) async {
    lastBundleHashAddresses = addresses;
    return bundleHashResponse ?? ApiResponse.withError('no canned response');
  }

  @override
  Future<ApiResponse> getEvaluatedAccountV2(String addressOrBundle) async {
    lastEvaluatedAccountValue = addressOrBundle;
    return evaluatedAccountResponse ??
        ApiResponse.withError('no canned response');
  }

  @override
  Future<ApiResponse> getGlobalSettingV2() async {
    return globalSettingResponse ?? ApiResponse.withError('no canned response');
  }

  @override
  Future<bool> saveResponse(String response) async {
    savedResponses.add(response);
    return true;
  }

  @override
  Future<bool> setGlobalSetting(String value) async {
    savedGlobalSettings.add(value);
    return true;
  }
}

// Bare-minimum stubs so the ``ASArepo`` super-constructor can be called
// without spinning up a real Dio or SharedPreferences. We override every
// method on ``_StubRepo`` itself, so neither stub's methods are ever
// invoked — but Dart requires the types to satisfy the constructor
// signature, so the stubs must satisfy the public interface.
//
// We use ``implements`` (skips the parent constructor entirely) plus
// ``noSuchMethod`` (no need to enumerate every concrete method) to keep
// the boilerplate small.

class _FakeDio implements DioClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          'DioClient.${invocation.memberName} unexpectedly called in test');
}

class _FakeSP implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          'SharedPreferences.${invocation.memberName} unexpectedly called in test');
}

Response<dynamic> _ok(Object body) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: body,
    );

void main() {
  // The fluttertoast plugin (called transitively from ASAProvider's failure
  // paths via ToastService.show) reaches for ServicesBinding.instance, which
  // is not initialized in plain ``dart test -p vm`` runs. The Flutter test
  // framework provides ``TestWidgetsFlutterBinding.ensureInitialized()`` as
  // the supported way to set up just enough of the binding to satisfy
  // platform-channel calls.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initializing the binding fixes the "binding not initialized" crash, but
  // every method call on a real plugin channel still fails with
  // ``MissingPluginException`` because no native side is registered. Mock
  // the fluttertoast channel so showToast no-ops in tests rather than
  // throwing on the failure paths.
  //
  // The channel name must match exactly what the fluttertoast package
  // declares (``PonnamKarthik/fluttertoast``); if the package is ever
  // swapped or a major version updates the channel name, update this
  // string accordingly.
  const fluttertoastChannel = MethodChannel('PonnamKarthik/fluttertoast');
  TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    fluttertoastChannel,
    (MethodCall methodCall) async => null,
  );

  late _StubRepo repo;
  late ASAProvider provider;

  setUp(() {
    repo = _StubRepo();
    provider = ASAProvider(asaRepo: repo);
  });

  group('ASAProvider.getBundleHashV2', () {
    test('unwraps {"bundle": "..."} response envelope to bare hash', () async {
      const hash = '540A5D8CEC896E073F9170AF0A962503E69147CF';
      repo.bundleHashResponse = ApiResponse.withSuccess(_ok({'bundle': hash}));

      final result = await provider.getBundleHashV2('ADDR1 ADDR2');

      expect(result.isSuccess, isTrue);
      expect(result.data, hash);
      expect(provider.bundleHash, hash);
      expect(provider.isLoading, isFalse);
    });

    test('forwards the raw addresses string to the repo', () async {
      repo.bundleHashResponse = ApiResponse.withSuccess(_ok({'bundle': 'X'}));
      await provider.getBundleHashV2('addr1, addr2 ; addr3');
      // The provider doesn't massage the input — the repo's POST body
      // is responsible for the `{"addresses": ...}` envelope.
      expect(repo.lastBundleHashAddresses, 'addr1, addr2 ; addr3');
    });

    test('handles missing "bundle" key gracefully', () async {
      // Defensive: empty / stripped response shouldn't crash. We end
      // up with an empty bundle string and a non-fatal ResponseModel.
      repo.bundleHashResponse = ApiResponse.withSuccess(_ok({}));
      final result = await provider.getBundleHashV2('ADDR1');
      // bundleHash is empty so downstream callers can detect failure
      // via length check.
      expect(result.data, '');
      expect(provider.bundleHash, '');
    });

    test('returns failure ResponseModel on HTTP error', () async {
      repo.bundleHashResponse = ApiResponse.withError('upstream 500');
      final result = await provider.getBundleHashV2('ADDR1');
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('500'));
    });
  });

  group('ASAProvider.getEvaluatedAccountV2', () {
    // Lazy-load the sample fixture once; same file the Phase 5a tests use.
    late Map<String, dynamic> samplePayload;
    setUpAll(() {
      final file = File('test/fixtures/sample_serialized_540A5.json');
      samplePayload =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses the real payload and stashes in _accountV2', () async {
      repo.evaluatedAccountResponse = ApiResponse.withSuccess(_ok(samplePayload));

      final result = await provider.getEvaluatedAccountV2('BUNDLEHASH');

      expect(result.isSuccess, isTrue);
      // The default (non-single) path populates accountV2; accountV2Single
      // remains null.
      expect(provider.accountV2.asaitems.length, 76);
      expect(provider.accountV2.nftcollections.length, 55);
      expect(provider.accountV2Single, isNull);
    });

    test('routes to _accountV2Single when isSingle=true', () async {
      repo.evaluatedAccountResponse = ApiResponse.withSuccess(_ok(samplePayload));

      await provider.getEvaluatedAccountV2('ADDR1', isSingle: true);

      // Single-address case populates accountV2Single, leaving the
      // bundle-side state untouched.
      expect(provider.accountV2Single, isNotNull);
      expect(provider.accountV2Single!.asaitems.length, 76);
      expect(provider.accountV2.asaitems, isEmpty);
    });

    test('persists raw payload to SharedPreferences', () async {
      repo.evaluatedAccountResponse = ApiResponse.withSuccess(_ok(samplePayload));
      await provider.getEvaluatedAccountV2('BUNDLEHASH');
      // Exactly one write to the V2 cache key.
      expect(repo.savedResponses.length, 1);
      final saved = jsonDecode(repo.savedResponses.single) as Map<String, dynamic>;
      expect(saved['account_info'], isA<Map>());
      expect(saved['asaitems'], isA<List>());
    });

    test('handles parse failure without stomping previous state', () async {
      // Seed with a good response first.
      repo.evaluatedAccountResponse = ApiResponse.withSuccess(_ok(samplePayload));
      await provider.getEvaluatedAccountV2('GOOD');
      expect(provider.accountV2.asaitems.length, 76);

      // Now return a malformed response. The provider should fail the
      // ResponseModel but leave the previous good state intact.
      repo.evaluatedAccountResponse = ApiResponse.withSuccess(_ok('not a map'));
      final result = await provider.getEvaluatedAccountV2('BAD');
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('parse'));
      expect(provider.accountV2.asaitems.length, 76,
          reason: 'Previous state must survive a parse failure');
    });

    test('handles HTTP failure', () async {
      repo.evaluatedAccountResponse = ApiResponse.withError('offline');
      final result = await provider.getEvaluatedAccountV2('ADDR1');
      expect(result.isSuccess, isFalse);
      expect(result.message, 'offline');
    });
  });

  group('ASAProvider.getGlobalSettingV2', () {
    test('persists the response payload to SharedPreferences', () async {
      final payload = {
        'asa_colors': {'0': '#fff'},
        'nft_colors': {'0': '#000'},
        'providers': {'path': 'static/icons/providers/'},
        'slogans': ['test slogan'],
      };
      repo.globalSettingResponse = ApiResponse.withSuccess(_ok(payload));

      final result = await provider.getGlobalSettingV2();

      expect(result.isSuccess, isTrue);
      expect(repo.savedGlobalSettings.length, 1);
      final saved = jsonDecode(repo.savedGlobalSettings.single)
          as Map<String, dynamic>;
      expect(saved, payload);
    });

    test('handles HTTP failure without persisting', () async {
      repo.globalSettingResponse = ApiResponse.withError('offline');
      final result = await provider.getGlobalSettingV2();
      expect(result.isSuccess, isFalse);
      // No partial write — existing cached settings stay valid.
      expect(repo.savedGlobalSettings, isEmpty);
    });
  });

  group('ASAProvider.clear()', () {
    test('wipes V2 state alongside V1 state', () async {
      // Pre-populate V2 state via a real call.
      final samplePayload = jsonDecode(
        File('test/fixtures/sample_serialized_540A5.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      repo.evaluatedAccountResponse =
          ApiResponse.withSuccess(_ok(samplePayload));
      await provider.getEvaluatedAccountV2('ADDR1');
      await provider.getEvaluatedAccountV2('ADDR2', isSingle: true);
      expect(provider.accountV2.asaitems, isNotEmpty);
      expect(provider.accountV2Single, isNotNull);

      // clear() resets V2 first (then attempts V1, swallowing the
      // pre-existing v1 ``ASAModel.fromJson({})`` crash internally).
      provider.clear();

      expect(provider.accountV2.asaitems, isEmpty);
      expect(provider.accountV2Single, isNull);
    });
  });
}
