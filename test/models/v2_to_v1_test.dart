// Phase 5c — tests for the V2 -> V1 ASAModel shim.
//
// The shim is a pure function so the tests are pure too — feed in a
// parsed ``EvaluatedAccount``, assert structural properties of the
// returned ``ASAModel``. Loads the same captured sample payload the
// Phase 5a and 5b tests use.

import 'dart:convert';
import 'dart:io';

import 'package:asa_stats/models/v2/v2.dart' as v2;
import 'package:asa_stats/models/v2_to_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('v2ToV1ASAModel against real sample payload', () {
    late v2.EvaluatedAccount realAccount;

    setUpAll(() {
      final raw = jsonDecode(
        File('test/fixtures/sample_serialized_540A5.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      realAccount = v2.EvaluatedAccount.fromJson(raw);
    });

    test('returns a non-null ASAModel with top-level fields populated', () {
      final result = v2ToV1ASAModel(realAccount);
      expect(result, isNotNull);
      expect(result.addresses, hasLength(2));
      // ``online`` defaults to false; sample payload may or may not set
      // it, but the field must be non-null on the result.
      expect(result.online, isNotNull);
    });

    test('preserves total values', () {
      final result = v2ToV1ASAModel(realAccount);
      expect(result.total, isNotNull);
      expect(result.total!.priceusdc, realAccount.total!.priceusdc);
      expect(result.total!.totalusdc, realAccount.total!.totalusdc);
    });

    test('translates asaitems to values 1:1', () {
      final result = v2ToV1ASAModel(realAccount);
      expect(result.values, hasLength(76));
      final first = result.values!.first;
      expect(first.asa, isNotNull);
      expect(first.asa!.id, isNotNull);
      expect(first.amount, isNotNull);
      // int -> double conversion.
      expect(first.amount, isA<double>());
    });

    test('ALGO asaitem keeps unit "ALGO" (non-empty stays non-null)', () {
      final result = v2ToV1ASAModel(realAccount);
      final algo = result.values!.firstWhere(
        (v) => v.asa?.id == 0,
        orElse: () => fail('No ALGO asaitem in sample'),
      );
      expect(algo.asa!.unit, 'ALGO');
    });

    test('translates programs into V1 Dapps with type-derived dapp label', () {
      final result = v2ToV1ASAModel(realAccount);
      final algo = result.values!.firstWhere((v) => v.asa?.id == 0);
      expect(algo.dapps, isNotEmpty);
      // First ALGO program is "Balance" (type="Balance", no name/code).
      expect(algo.dapps!.first.dapp, 'Balance');
    });

    test('multi-token program produces "Type Name" dapp label', () {
      // Find any program with both type and name set; verify the shim
      // concatenates them with a space.
      final result = v2ToV1ASAModel(realAccount);
      String? found;
      for (final v in result.values!) {
        for (final d in v.dapps ?? const []) {
          if (d.dapp != null && d.dapp!.contains(' ')) {
            found = d.dapp;
            break;
          }
        }
        if (found != null) break;
      }
      expect(found, isNotNull);
      // E.g. "Added Liquidity", "Locked Liquidity".
      final parts = found!.split(' ');
      expect(parts.length, greaterThanOrEqualTo(2));
      expect(parts.every((p) => p.isNotEmpty), isTrue);
    });

    test('flattens v2.Distribution.link to v1.text/link scalars', () {
      final result = v2ToV1ASAModel(realAccount);
      var found = false;
      for (final v in result.values!) {
        for (final d in v.dapps ?? const []) {
          for (final dist in d.distribution ?? const []) {
            if (dist.text != null && dist.link != null) {
              found = true;
              break;
            }
          }
          if (found) break;
        }
        if (found) break;
      }
      expect(found, isTrue,
          reason: 'Expected at least one distribution with text+link');
    });

    test('translates nftcollections to nft_values', () {
      final result = v2ToV1ASAModel(realAccount);
      expect(result.nftValues, hasLength(55));
      final first = result.nftValues!.first;
      expect(first.collection, isNotNull);
      expect(first.nfts, isNotEmpty);
    });

    test('NFT image paths land in v1 path/tpath fields', () {
      final result = v2ToV1ASAModel(realAccount);
      final firstNft = result.nftValues!.first.nfts!.first.nft!;
      expect(firstNft.path, isNotNull);
      expect(firstNft.tpath, isNotNull);
    });

    test('NFT urls collapse from list to dict keyed by typ', () {
      final result = v2ToV1ASAModel(realAccount);
      // Find an NFT with non-empty urls.
      Map? withUrls;
      for (final coll in result.nftValues!) {
        for (final n in coll.nfts ?? const []) {
          if (n.nft?.urls != null && (n.nft!.urls as Map).isNotEmpty) {
            withUrls = n.nft!.urls as Map;
            break;
          }
        }
        if (withUrls != null) break;
      }
      expect(withUrls, isNotNull);
      expect(withUrls, isA<Map<String, dynamic>>());
    });

    test('notevals translate with asa and amount', () {
      final result = v2ToV1ASAModel(realAccount);
      expect(result.notEval, hasLength(1));
      final ne = result.notEval!.first;
      expect(ne.asa, isNotNull);
      expect(ne.amount, isNotNull);
    });

    test('color map assigns sequential slots modulo palette size', () {
      final result = v2ToV1ASAModel(realAccount);
      // First asaitem gets slot "0", second "1", etc.
      final firstId = result.values!.first.asa!.id!.toString();
      expect(result.colors![firstId], '0');
      // After 18 items the slot wraps to "0" again.
      if (result.values!.length > 18) {
        final nineteenthId = result.values![18].asa!.id!.toString();
        expect(result.colors![nineteenthId], '0');
      }
    });

    test('chart fields are left null per B8 (computed in widget later)', () {
      final result = v2ToV1ASAModel(realAccount);
      expect(result.asaChart, isNull);
      expect(result.nftChart, isNull);
      expect(result.ratioChart, isNull);
    });
  });

  group('v2ToV1ASAModel defensive cases', () {
    test('empty EvaluatedAccount yields a well-formed empty ASAModel', () {
      final result = v2ToV1ASAModel(v2.EvaluatedAccount());
      expect(result.addresses, isEmpty);
      expect(result.online, isFalse);
      expect(result.values, isEmpty);
      expect(result.nftValues, isEmpty);
      expect(result.notEval, isEmpty);
      expect(result.colors, isEmpty);
      expect(result.nftColors, isEmpty);
      // Total is built as an empty Total (all fields null) rather than
      // null itself — keeps the consumer's null-defenses simpler.
      expect(result.total, isNotNull);
    });

    test('asaitem with empty unit string maps to null unit (v1 nullable)', () {
      final account = v2.EvaluatedAccount(asaitems: [
        v2.AsaItem(
          asset: v2.Asa(id: 999, unit: ''),
          value: 1.0,
          amount: 0,
        ),
      ]);
      final result = v2ToV1ASAModel(account);
      expect(result.values!.first.asa!.unit, isNull,
          reason: 'Empty v2 unit should round-trip to null in v1');
    });

    test('color map skips entries with null id', () {
      // Synthetic: 3 asaitems, middle one has null id. Slot indices
      // count across all positions so the third asset still gets "2".
      final account = v2.EvaluatedAccount(asaitems: [
        v2.AsaItem(asset: v2.Asa(id: 100), value: 1.0, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: null), value: 0.5, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: 300), value: 0.1, amount: 0),
      ]);
      final result = v2ToV1ASAModel(account);
      expect(result.colors!['100'], '0');
      expect(result.colors!['300'], '2');
      // Two entries (the null-id one is skipped).
      expect(result.colors!.length, 2);
    });
  });
}
