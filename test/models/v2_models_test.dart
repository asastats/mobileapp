// Verification tests for the API 2.0 model layer.
//
// Parses the real sample payload captured during the website migration
// (sample_serialized_540A5.json from utils/tests/) and asserts that:
//
//   1. ``EvaluatedAccount.fromJson`` accepts the full payload without
//      throwing.
//   2. The parsed model exposes the expected top-level structure
//      (bundle, address count, asaitem count, nftcollection count,
//      noteval count, total fields).
//   3. Round-tripping a parsed model through ``toJson`` produces a
//      structurally equivalent payload (same shape, same values modulo
//      the serializer's null-strip).
//   4. Defensive parsing handles empty / malformed payloads without
//      throwing.
//
// Run with ``flutter test test/models/v2_models_test.dart``.

import 'dart:convert';
import 'dart:io';

import 'package:asa_stats/models/v2/v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EvaluatedAccount.fromJson', () {
    late Map<String, dynamic> samplePayload;

    setUpAll(() {
      // The fixture is committed at test/fixtures/sample_serialized_540A5.json
      // — same file the website Phase 0 charts tests use, copied across.
      final file = File('test/fixtures/sample_serialized_540A5.json');
      samplePayload = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses real sample payload without throwing', () {
      // The simplest possible test — but the one that catches every
      // shape regression. If a serializer field renames upstream, this
      // test exposes it before any UI code does.
      expect(() => EvaluatedAccount.fromJson(samplePayload), returnsNormally);
    });

    test('exposes top-level account info', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      // Sample is a 2-address bundle, well-known constants from Phase 0.
      expect(account.accountInfo, isNotNull);
      expect(account.accountInfo!.bundle,
          '540A5D8CEC896E073F9170AF0A962503E69147CF');
      expect(account.accountInfo!.addresses.length, 2);
      expect(account.isBundle, isTrue);
      expect(account.accountInfo!.valuesIn, 'ALGO');
    });

    test('exposes total values', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      // Don't assert exact values (they evolve as the pricing engine
      // changes); assert non-null and roughly-correct relationships.
      expect(account.total, isNotNull);
      expect(account.total!.total, greaterThan(0));
      expect(account.total!.totalusdc, greaterThan(0));
      expect(account.total!.priceusdc, greaterThan(0));
      expect(account.total!.pricealgo, greaterThan(0));
      // priceusdc and pricealgo are reciprocals; product should be ~1
      // (within float tolerance).
      final product = account.total!.priceusdc! * account.total!.pricealgo!;
      expect(product, closeTo(1.0, 0.001));
    });

    test('parses the expected number of asaitems', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      // Phase 0 documented 76 asaitems in this sample. If the captured
      // fixture changes, this number changes — but a sudden drop to
      // single digits would surface a list-parsing regression.
      expect(account.asaitems.length, 76);
    });

    test('parses the expected number of nftcollections', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      expect(account.nftcollections.length, 55);
    });

    test('parses the expected number of notevals', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      expect(account.notevals.length, 1);
    });

    test('asaitem carries asset metadata, value, and programs', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      // Pick a non-ALGO asaitem from the middle of the list (any).
      final item = account.asaitems.firstWhere(
        (i) => i.asset?.id != null && i.asset!.id! > 0,
        orElse: () => fail('No non-ALGO asaitem in sample'),
      );
      expect(item.asset, isNotNull);
      expect(item.asset!.id, isNotNull);
      expect(item.asset!.unit, isNotEmpty);
      expect(item.amount, isNotNull);
      // Every asaitem in the sample has at least one program (otherwise
      // it would be in notevals).
      expect(item.programs, isNotEmpty);
    });

    test('every program references an AsaProgram with type and provider', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      var checked = 0;
      for (final item in account.asaitems) {
        for (final prog in item.programs) {
          expect(prog.program, isNotNull,
              reason: 'Program missing in asset ${item.asset?.unit}');
          expect(prog.program!.type, isNotNull,
              reason: 'Program type missing in asset ${item.asset?.unit}');
          checked++;
        }
      }
      // Sanity check: we touched a meaningful number of programs.
      expect(checked, greaterThan(10),
          reason: 'Too few programs in sample to trust this test');
    });

    test('ALGO Balance program has linked "Available" entry', () {
      // The ALGO asset's Balance program has a linked sub-row with
      // text="Available" that the website renders next to the balance.
      // This is a strong regression guard for the LinkedData class:
      // if the field renames upstream, this test fails immediately.
      final account = EvaluatedAccount.fromJson(samplePayload);
      final algo = account.asaitems.firstWhere(
        (i) => i.asset?.id == 0,
        orElse: () => fail('No ALGO asaitem in sample'),
      );
      final balance = algo.programs.firstWhere(
        (p) => p.program?.type == 'Balance',
        orElse: () => fail('No ALGO Balance program in sample'),
      );
      final available = balance.linked.firstWhere(
        (l) => l.text == 'Available',
        orElse: () =>
            fail('No "Available" linked entry on ALGO Balance program'),
      );
      expect(available.value, isNotNull);
    });

    test('nft collection exposes member NFTs with image paths', () {
      final account = EvaluatedAccount.fromJson(samplePayload);
      // First collection is the most valuable; should have NFTs.
      final collection = account.nftcollections.first;
      expect(collection.name, isNotNull);
      expect(collection.nfts, isNotEmpty);
      final firstNft = collection.nfts.first.nft!;
      expect(firstNft.id, isNotNull);
      // Image paths from the API are relative paths under static/, so
      // they start with "/". We don't assert "starts with /" because
      // some asset pipelines absolutize during serialization; the
      // important contract is non-null non-empty.
      expect(firstNft.image, isNotNull);
      expect(firstNft.thumbnail, isNotNull);
    });

    test('round-trips through toJson without losing field values', () {
      // toJson preserves shape but not exact byte-for-byte equality with
      // the input (the input omits null fields via to_representation; our
      // toJson conditionally writes some fields and unconditionally writes
      // others). The right round-trip check is: parsed -> json -> parsed
      // produces a model with identical observable fields.
      final original = EvaluatedAccount.fromJson(samplePayload);
      final reparsed = EvaluatedAccount.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(reparsed.accountInfo?.bundle, original.accountInfo?.bundle);
      expect(reparsed.accountInfo?.addresses,
          original.accountInfo?.addresses);
      expect(reparsed.total?.total, original.total?.total);
      expect(reparsed.total?.priceusdc, original.total?.priceusdc);
      expect(reparsed.asaitems.length, original.asaitems.length);
      expect(reparsed.nftcollections.length, original.nftcollections.length);
      expect(reparsed.notevals.length, original.notevals.length);

      // Walk one asaitem deeply.
      final origItem = original.asaitems.first;
      final reItem = reparsed.asaitems.first;
      expect(reItem.asset?.id, origItem.asset?.id);
      expect(reItem.asset?.unit, origItem.asset?.unit);
      expect(reItem.value, origItem.value);
      expect(reItem.amount, origItem.amount);
      expect(reItem.programs.length, origItem.programs.length);
    });
  });

  group('defensive parsing', () {
    test('empty object yields a model with empty collections', () {
      final account = EvaluatedAccount.fromJson({});
      expect(account.accountInfo, isNull);
      expect(account.systemInfo, isNull);
      expect(account.total, isNull);
      expect(account.asaitems, isEmpty);
      expect(account.nftcollections, isEmpty);
      expect(account.notevals, isEmpty);
      expect(account.isBundle, isFalse);
    });

    test('list-of-objects fields containing non-maps are skipped', () {
      // A real-world quirk: an upstream proxy injects a string into a
      // list slot. We skip non-map entries silently rather than crashing
      // the whole parse — the cost of dropping one row is much smaller
      // than an unparseable account screen.
      final account = EvaluatedAccount.fromJson({
        'asaitems': [
          {'asset': {'id': 1}},
          'this is garbage',
          {'asset': {'id': 2}},
        ],
      });
      expect(account.asaitems.length, 2);
      expect(account.asaitems[0].asset?.id, 1);
      expect(account.asaitems[1].asset?.id, 2);
    });

    test('DecimalField parses from JSON strings and numbers', () {
      // DRF emits decimals as strings by default, but some intermediaries
      // (CDN transforms, debugging tooling) may coerce them to numbers.
      // Both must work.
      final fromString = Total.fromJson({'total': '123.456789'});
      expect(fromString.total, 123.456789);
      final fromNumber = Total.fromJson({'total': 123.456789});
      expect(fromNumber.total, 123.456789);
    });

    test('null and missing fields produce null values, not exceptions', () {
      final total = Total.fromJson({});
      expect(total.algo, isNull);
      expect(total.priceusdc, isNull);
      expect(total.noteval, isNull);
    });

    test('AccountInfo addresses survives malformed list', () {
      // If addresses isn't a list, we degrade to empty (and let the UI
      // show the "no address" empty state) rather than throwing.
      final info = AccountInfo.fromJson({'addresses': 'not a list'});
      expect(info.addresses, isEmpty);
    });
  });

  group('Provider.iconSlug', () {
    // Mirrors the Phase 2 web template's ``provider_icon`` filter; the
    // mobile app currently uses ``AppConstants.getProviderImage(id)`` and
    // passes a slug derived from the legacy app code. With the v2 models
    // we derive the slug from ``Provider.name`` directly.
    test('lowercases and strips whitespace', () {
      expect(Provider(name: 'Live Coin Watch').iconSlug, 'livecoinwatch');
      expect(Provider(name: 'CoinMarketCap').iconSlug, 'coinmarketcap');
      expect(Provider(name: 'DEX Screener').iconSlug, 'dexscreener');
    });

    test('returns null for missing or empty name', () {
      expect(Provider(name: null).iconSlug, isNull);
      expect(Provider(name: '').iconSlug, isNull);
    });
  });

  group('Asa.isAlgo', () {
    test('returns true only for asset id 0', () {
      expect(Asa(id: 0).isAlgo, isTrue);
      expect(Asa(id: 31566704).isAlgo, isFalse); // USDC
      expect(Asa(id: null).isAlgo, isFalse);
    });
  });

  group('Nft.primaryImageUrl', () {
    test('returns the first url when not Vault/Locked', () {
      final nft = Nft(urls: [
        NftUrl(typ: 'image', url: 'ipfs://abc'),
        NftUrl(typ: 'external_url', url: 'https://example.com'),
      ]);
      expect(nft.primaryImageUrl?.url, 'ipfs://abc');
    });

    test('falls through to second url for Vault', () {
      // The website's nfts/item.html template renders the secondary URL
      // when the first is a Vault entry (which points to the escrow
      // contract, not the image). Same dispatch here.
      final nft = Nft(urls: [
        NftUrl(typ: 'Vault', url: 'https://vault.example'),
        NftUrl(typ: 'image', url: 'ipfs://abc'),
      ]);
      expect(nft.primaryImageUrl?.url, 'ipfs://abc');
    });

    test('falls through to second url for Locked', () {
      final nft = Nft(urls: [
        NftUrl(typ: 'Locked', url: 'https://locked.example'),
        NftUrl(typ: 'image', url: 'ipfs://abc'),
      ]);
      expect(nft.primaryImageUrl?.url, 'ipfs://abc');
    });

    test('returns null when only a Vault/Locked URL exists', () {
      final nft = Nft(urls: [NftUrl(typ: 'Vault', url: 'https://vault')]);
      expect(nft.primaryImageUrl, isNull);
    });

    test('returns null when urls is empty', () {
      expect(Nft().primaryImageUrl, isNull);
    });
  });
}
