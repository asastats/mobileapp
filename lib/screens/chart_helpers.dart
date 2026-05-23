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
