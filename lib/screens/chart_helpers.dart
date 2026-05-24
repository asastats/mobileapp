// Phase 5c-3 / B8 — chart data helpers computed inline from V2 models.
//
// These helpers replace the v1-backend-computed ``ratioChart`` /
// ``asaChart`` / ``nftChart`` fields by deriving the same chart data
// directly from a parsed ``EvaluatedAccount`` on the client.
//
// Each function returns a ``List<ChartData>`` ready to feed into the
// existing ``Chart`` widget — same shape the v1 path produced after
// the screen's ``updateASAdata`` post-processing, so the chart widget
// itself doesn't change.
//
// Kept as top-level functions (not methods on the screen state) so
// they're trivially unit-testable without spinning up a widget tree.

import 'package:flutter/material.dart' show Color;

import '../config/color.dart';
import '../config/enums.dart';
import '../config/hex_color.dart';
import '../models/body/chart_data_model.dart';
import '../models/v2/v2.dart' as v2;

/// Colors for the ALGO/ASA/NFT segments of the consolidated ratio chart.
/// Lifted verbatim from the v1 website's ``ASASTATS_COLORS`` indices
/// ``[2, 0, 3]`` (see ``utils/constants/charts.py``) so mobile and
/// website show identical colors for the same chart.
const String _ratioColorAlgo = '#005a34';
const String _ratioColorAsa = '#575757';
const String _ratioColorNft = '#ababab';

/// Color slot used to bucket low-percentage and overflow rows in the
/// asa/nft per-item charts. Matches the website's
/// ``ASASTATS_COLOR_OTHERS = ASASTATS_COLORS[-1]`` ("#ababab").
const String _othersColor = '#ababab';

/// Max distinct per-item segments before bucketing into "others".
/// Matches the website's ``PIE_CHART_MAXIMUM_ITEMS``.
const int _maxItems = 15;

/// Hide-from-chart cumulative threshold: once the running total exceeds
/// ``(1 - this) * grand_total``, the rest bucket into "others". Matches
/// the website's ``HIDE_LAST_PERCENT = 0.005`` (0.5% tail collapse).
const double _hideLastPercent = 0.005;

/// Build the 3-segment ALGO/ASA/NFT ratio chart for the "All" tab.
///
/// Returns an empty list when the account total is zero or the category
/// type isn't ``CategoryType.all`` — both cases mean "don't render a
/// chart", matching the v1 backend's "skip if total==0" behavior.
///
/// Matches the v1 backend's ``_ratio_chart_data(total)`` output 1:1:
/// labels ``["ALGO", "ASA", "NFT"]``, data ``[100*algo/total,
/// 100*asa/total, 100*nft/total]``, colors above.
List<ChartData> buildRatioChartData(
    v2.EvaluatedAccount account, CategoryType type) {
  if (type != CategoryType.all) return const [];
  final total = account.total;
  // Use ``0.0`` (not ``0``) for the fallback so all locals stay
  // ``double``. With ``0`` (int), the ``??`` result type widens to
  // ``num``, and ``num`` can't be assigned to ``ChartData.y`` (which
  // is ``double?``) without an explicit cast.
  final t = total?.total ?? 0.0;
  if (t <= 0) return const [];
  final algo = total?.algo ?? 0.0;
  final asa = total?.asa ?? 0.0;
  final nft = total?.nft ?? 0.0;
  return [
    // ``100.0`` (not ``100``) so the multiplication's return type is
    // ``double`` not ``num`` — ``num`` can't be assigned to
    // ``ChartData.y`` (a ``double?`` field) without a cast.
    ChartData(color: HexColor(_ratioColorAlgo), title: 'ALGO', y: 100.0 * (algo / t)),
    ChartData(color: HexColor(_ratioColorAsa), title: 'ASA', y: 100.0 * (asa / t)),
    ChartData(color: HexColor(_ratioColorNft), title: 'NFT', y: 100.0 * (nft / t)),
  ];
}

/// Build the per-asset distribution chart for the ASA tab.
///
/// Iterates ``account.asaitems`` in declared order (which is value-desc
/// from the backend) and produces one segment per asset until either:
///   - the cumulative percentage exceeds ``1 - _hideLastPercent``
///     (matches the website's tail-collapse behavior), OR
///   - the segment count reaches ``_maxItems - 1`` (with the last slot
///     reserved for an "others" bucket).
///
/// When either limit fires, all remaining asaitems are summed into a
/// single ``"others"`` segment.
///
/// Colors come from the bundled ``assets/json/global_settings.json``
/// ``asa_colors`` palette (18 entries) indexed by segment position.
/// Per A7, that's the simplest "compute at render time" approach — no
/// reliance on a v1-style precomputed slot mapping.
///
/// Returns an empty list when the asaitem sum is zero (matches the
/// website's "skip if asasum == 0" behavior).
List<ChartData> buildAsaChartData(
  v2.EvaluatedAccount account,
  Map<String, dynamic> palette,
) {
  return _buildItemsChart(
    items: account.asaitems
        .map((i) => (label: i.asset?.unit ?? 'ALGO', value: i.value ?? 0.0))
        .toList(growable: false),
    palette: palette,
  );
}

/// Generic per-item pie-chart builder reused by buildAsaChartData and
/// (in Phase 5c-5) buildNftChartData. Takes a list of ``(label, value)``
/// records sorted descending by value and a hex-color palette dict
/// (slot index as decimal-string → hex color).
List<ChartData> _buildItemsChart({
  required List<({String label, double value})> items,
  required Map<String, dynamic> palette,
}) {
  // Sum positive values only — the website's chart skips zero-valued
  // items. Items with value=0 still appear in the source list (so
  // they can show in the row view), but the chart ignores them.
  final positive = items.where((it) => it.value > 0).toList(growable: false);
  if (positive.isEmpty) return const [];
  final sum = positive.fold<double>(0.0, (a, it) => a + it.value);
  if (sum <= 0) return const [];

  final limit = (1.0 - _hideLastPercent) * sum;
  final result = <ChartData>[];
  double running = 0.0;
  final count = positive.length;

  for (int i = 0; i < count; i++) {
    final it = positive[i];
    final color = _paletteColor(palette, i);
    result.add(ChartData(
      color: color,
      title: it.label,
      y: 100.0 * (it.value / sum),
    ));
    running += it.value;
    if (i == count - 1) break;
    // Tail-collapse: once we've hit either the percentage cap or the
    // item-count cap, sum every remaining item into a single "others"
    // bucket and stop. Matches the website's logic in
    // ``utils.charts._base_chart_data`` 1:1.
    if (i < count - 2 && (running > limit || i > _maxItems - 2)) {
      final remaining = sum - running;
      result.add(ChartData(
        color: HexColor(_othersColor),
        title: 'others',
        y: 100.0 * (remaining / sum),
      ));
      break;
    }
  }
  return result;
}

/// Resolve a palette slot to a Flutter Color. Wraps via modulo so a
/// chart with more items than palette slots still renders (the modulo
/// happens here rather than at the call site so the caller doesn't
/// need to know the palette size). Falls back to
/// ``ColorResources.defaultColor`` for invalid palette entries — a
/// missing/malformed bundled JSON shouldn't crash the chart.
Color _paletteColor(Map<String, dynamic> palette, int index) {
  if (palette.isEmpty) return ColorResources.defaultColor;
  final slot = (index % palette.length).toString();
  final hex = palette[slot];
  if (hex is! String || hex.isEmpty) return ColorResources.defaultColor;
  return HexColor(hex);
}
