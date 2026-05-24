// Phase 5c-3 — tests for the V2 chart-data helpers.
//
// Pure-function tests over real captured payloads. The helpers return
// fl_chart-ready ``ChartData`` lists; we assert the structural shape
// (segment count, ordering, titles, color hex, percentage values) and
// the boundary cases (empty account, zero total, non-"all" type).

import 'dart:convert';
import 'dart:io';

import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/models/v2/v2.dart' as v2;
import 'package:asa_stats/screens/chart_helpers.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildRatioChartData against the real sample payload', () {
    late v2.EvaluatedAccount realAccount;

    setUpAll(() {
      final raw = jsonDecode(
        File('test/fixtures/sample_serialized_540A5.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      realAccount = v2.EvaluatedAccount.fromJson(raw);
    });

    test('returns 3 segments for CategoryType.all', () {
      final data = buildRatioChartData(realAccount, CategoryType.all);
      expect(data, hasLength(3));
    });

    test('segments are labelled ALGO / ASA / NFT in order', () {
      final data = buildRatioChartData(realAccount, CategoryType.all);
      expect(data.map((d) => d.title).toList(), ['ALGO', 'ASA', 'NFT']);
    });

    test('segment percentages sum to ~100', () {
      final data = buildRatioChartData(realAccount, CategoryType.all);
      // ``ChartData.y`` is ``double?`` — coerce nulls to 0 inside the
      // fold so the accumulator stays non-nullable. None of the
      // happy-path segments produce null y values, but the type system
      // doesn't know that.
      final sum = data.fold<double>(0, (s, d) => s + (d.y ?? 0));
      // Allow a tiny float tolerance — sum of three divisions can
      // round to 99.999… or 100.000…1.
      expect(sum, closeTo(100.0, 0.0001));
    });

    test('segment percentages match total.algo/asa/nft proportions', () {
      final data = buildRatioChartData(realAccount, CategoryType.all);
      final t = realAccount.total!.total!;
      expect(data[0].y, closeTo(100 * (realAccount.total!.algo! / t), 0.0001));
      expect(data[1].y, closeTo(100 * (realAccount.total!.asa! / t), 0.0001));
      expect(data[2].y, closeTo(100 * (realAccount.total!.nft! / t), 0.0001));
    });

    test('segments carry the expected hex colors', () {
      final data = buildRatioChartData(realAccount, CategoryType.all);
      // Hex colors are read via HexColor wrapper; compare via Color.value
      // since HexColor extends Color.
      expect(data[0].color, isA<Color>());
      expect(data[1].color, isA<Color>());
      expect(data[2].color, isA<Color>());
      // Spot-check ALGO segment alpha+RGB packs to the expected value.
      // HexColor('#005a34') => 0xFF005A34 (full alpha + RGB).
      expect((data[0].color as Color).value, 0xFF005A34);
      expect((data[1].color as Color).value, 0xFF575757);
      expect((data[2].color as Color).value, 0xFFABABAB);
    });

    test('returns empty list for CategoryType.asa', () {
      // Phase 5c-3 only implements the "all" chart; asa/nft per-asset
      // charts get their own helpers in 5c-4/5c-5. Until then,
      // requesting them produces an empty chart (the screen renders no
      // chart, which is preferable to a crash).
      expect(buildRatioChartData(realAccount, CategoryType.asa), isEmpty);
    });

    test('returns empty list for CategoryType.nft', () {
      expect(buildRatioChartData(realAccount, CategoryType.nft), isEmpty);
    });
  });

  group('buildRatioChartData boundary cases', () {
    test('empty account returns empty list', () {
      // ``EvaluatedAccount()`` has total=null, so total.total is null
      // → 0 → "skip the chart".
      expect(
        buildRatioChartData(v2.EvaluatedAccount(), CategoryType.all),
        isEmpty,
      );
    });

    test('zero total returns empty list', () {
      final account = v2.EvaluatedAccount(
        total: v2.Total(algo: 0, asa: 0, nft: 0, total: 0),
      );
      expect(buildRatioChartData(account, CategoryType.all), isEmpty);
    });

    test('only ALGO present produces 100/0/0 split', () {
      final account = v2.EvaluatedAccount(
        total: v2.Total(algo: 10.0, asa: 0, nft: 0, total: 10.0),
      );
      final data = buildRatioChartData(account, CategoryType.all);
      expect(data, hasLength(3));
      expect(data[0].y, 100.0);
      expect(data[1].y, 0.0);
      expect(data[2].y, 0.0);
    });

    test('null per-segment values default to 0', () {
      // Total is non-zero, but the per-segment fields are null. The
      // helper should treat them as 0, producing 0/0/0 segments rather
      // than throwing on null arithmetic.
      final account = v2.EvaluatedAccount(
        total: v2.Total(total: 10.0),
      );
      final data = buildRatioChartData(account, CategoryType.all);
      expect(data, hasLength(3));
      expect(data.every((d) => d.y == 0.0), isTrue);
    });
  });

  group('buildAsaChartData against the real sample payload', () {
    late v2.EvaluatedAccount realAccount;
    // Use a palette of 18 slots like the bundled JSON, with synthetic
    // colors so the test assertions are deterministic regardless of
    // what the production palette becomes.
    final palette = <String, dynamic>{
      for (var i = 0; i < 18; i++)
        i.toString(): '#${(0x100000 + i * 0x010101).toRadixString(16).padLeft(6, '0')}',
    };

    setUpAll(() {
      final raw = jsonDecode(
        File('test/fixtures/sample_serialized_540A5.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      realAccount = v2.EvaluatedAccount.fromJson(raw);
    });

    test('produces 16 segments for the 76-asaitem fixture', () {
      // 15 real items + "others" bucket — the website's
      // PIE_CHART_MAXIMUM_ITEMS=15 limit kicks in well before the
      // hide-last-percent threshold for this account.
      final data = buildAsaChartData(realAccount, palette);
      expect(data, hasLength(16));
    });

    test('percentages sum to ~100', () {
      final data = buildAsaChartData(realAccount, palette);
      final sum = data.fold<double>(0, (s, d) => s + (d.y ?? 0));
      expect(sum, closeTo(100.0, 0.0001));
    });

    test('last segment is the "others" bucket', () {
      final data = buildAsaChartData(realAccount, palette);
      expect(data.last.title, 'others');
    });

    test('segments before "others" are in descending order by y-value', () {
      final data = buildAsaChartData(realAccount, palette);
      final real = data.sublist(0, data.length - 1); // drop "others"
      for (var i = 1; i < real.length; i++) {
        expect(real[i].y, lessThanOrEqualTo(real[i - 1].y ?? double.infinity),
            reason: 'segment $i (${real[i].title}) > previous '
                '(${real[i - 1].title}) — backend should return '
                'asaitems sorted descending');
      }
    });
  });

  group('buildAsaChartData boundary cases', () {
    final palette = <String, dynamic>{
      '0': '#ff0000',
      '1': '#00ff00',
      '2': '#0000ff',
    };

    test('empty account returns empty list', () {
      expect(buildAsaChartData(v2.EvaluatedAccount(), palette), isEmpty);
    });

    test('account with only zero-value items returns empty list', () {
      final account = v2.EvaluatedAccount(asaitems: [
        v2.AsaItem(asset: v2.Asa(id: 1, unit: 'A'), value: 0, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: 2, unit: 'B'), value: 0, amount: 0),
      ]);
      expect(buildAsaChartData(account, palette), isEmpty);
    });

    test('three positive items produce three segments, no "others"', () {
      // Below the max-items and the hide-last-percent thresholds; the
      // tail-collapse branch should not fire.
      final account = v2.EvaluatedAccount(asaitems: [
        v2.AsaItem(asset: v2.Asa(id: 1, unit: 'A'), value: 50.0, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: 2, unit: 'B'), value: 30.0, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: 3, unit: 'C'), value: 20.0, amount: 0),
      ]);
      final data = buildAsaChartData(account, palette);
      expect(data, hasLength(3));
      expect(data.map((d) => d.title), ['A', 'B', 'C']);
      expect(data.map((d) => d.y), [50.0, 30.0, 20.0]);
      expect(data.any((d) => d.title == 'others'), isFalse);
    });

    test('items beyond max-items - 1 collapse into "others"', () {
      // 17 items at equal value — exceeds max_items - 2 = 13 at i=14,
      // so the loop adds the 15th item then breaks into "others".
      final items = List<v2.AsaItem>.generate(
        17,
        (i) => v2.AsaItem(
          asset: v2.Asa(id: i + 100, unit: 'A$i'),
          value: 10.0,
          amount: 0,
        ),
      );
      final data = buildAsaChartData(v2.EvaluatedAccount(asaitems: items), palette);
      // 15 real + 1 "others" = 16 total. Matches website behavior.
      expect(data, hasLength(16));
      expect(data.last.title, 'others');
    });

    test('hide-last-percent threshold fires before max-items count', () {
      // One huge item plus many tiny ones — once the huge one is
      // counted, running > limit immediately and the tail collapses.
      final items = [
        v2.AsaItem(
            asset: v2.Asa(id: 1, unit: 'BIG'), value: 99999.0, amount: 0),
        for (var i = 0; i < 10; i++)
          v2.AsaItem(
              asset: v2.Asa(id: i + 100, unit: 'tiny$i'),
              value: 0.001,
              amount: 0),
      ];
      final data = buildAsaChartData(v2.EvaluatedAccount(asaitems: items), palette);
      // After BIG is added (i=0), running (99999) > limit (~99499.5),
      // so the condition fires on the post-add check and "others"
      // captures the 10 tinies. Result: BIG + others = 2 segments.
      expect(data, hasLength(2));
      expect(data.first.title, 'BIG');
      expect(data.last.title, 'others');
    });

    test('palette wraps via modulo when items exceed palette size', () {
      // Synthetic 2-slot palette + 3 items: 3rd item gets slot 0 again.
      // Since these are real segments (not "others"), the wrap behavior
      // is observable via the segment colors.
      final smallPalette = <String, dynamic>{'0': '#ff0000', '1': '#00ff00'};
      final account = v2.EvaluatedAccount(asaitems: [
        v2.AsaItem(asset: v2.Asa(id: 1, unit: 'A'), value: 30.0, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: 2, unit: 'B'), value: 20.0, amount: 0),
        v2.AsaItem(asset: v2.Asa(id: 3, unit: 'C'), value: 10.0, amount: 0),
      ]);
      final data = buildAsaChartData(account, smallPalette);
      expect(data, hasLength(3));
      // First and third items should both have the red color (slot 0).
      expect((data[0].color as Color).value, (data[2].color as Color).value);
      // Second should differ.
      expect((data[0].color as Color).value,
          isNot((data[1].color as Color).value));
    });

    test('empty palette falls back to default color without crashing', () {
      final account = v2.EvaluatedAccount(asaitems: [
        v2.AsaItem(asset: v2.Asa(id: 1, unit: 'A'), value: 10.0, amount: 0),
      ]);
      final data = buildAsaChartData(account, <String, dynamic>{});
      expect(data, hasLength(1));
      // Color exists (the default fallback), so the chart still renders.
      expect(data.first.color, isNotNull);
    });
  });
}
