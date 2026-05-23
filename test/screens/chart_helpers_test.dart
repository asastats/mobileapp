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
}
