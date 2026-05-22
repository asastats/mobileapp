// Total — portfolio-wide ALGO and USD aggregates.
//
// Mirrors `api.serializers.TotalSerializer`. All values are six-decimal
// DRF DecimalFields, which the renderer emits as JSON strings; we parse
// them to ``double`` to match the v1 model conventions and the widget
// arithmetic that does ``total.priceusdc * value`` etc.

import '_json.dart';

class Total {
  /// Sum of plain ALGO balance across the bundle.
  final double? algo;

  /// Sum of ASA value (in ALGO) across the bundle.
  final double? asa;

  /// Sum of NFT estimated value (in ALGO) across the bundle.
  final double? nft;

  /// Total portfolio value in ALGO (``algo + asa + nft``).
  final double? total;

  /// Total portfolio value in USDC.
  final double? totalusdc;

  /// Current ALGO price quoted in USDC (i.e. "X USDC per 1 ALGO").
  ///
  /// Note: the field name predates the USDC/USD disambiguation. Numeric
  /// value equals ``1 / pricealgo``.
  final double? priceusdc;

  /// Current USDC price quoted in ALGO (i.e. "Y ALGO per 1 USDC").
  ///
  /// This is the field the website uses for its "USD/ALGO" display in
  /// the per-ALGO Balance row. Same number as ``priceusdc`` inverted.
  final double? pricealgo;

  /// Number of assets in the account that couldn't be priced (and are
  /// therefore in ``EvaluatedAccount.notevals``, not ``asaitems``).
  final int? noteval;

  /// Portfolio total in ALGO with NFTs excluded.
  final double? totalwonft;

  /// Portfolio total in USDC with NFTs excluded.
  final double? totalwonftusdc;

  Total({
    this.algo,
    this.asa,
    this.nft,
    this.total,
    this.totalusdc,
    this.priceusdc,
    this.pricealgo,
    this.noteval,
    this.totalwonft,
    this.totalwonftusdc,
  });

  factory Total.fromJson(Map<String, dynamic> json) => Total(
        algo: parseDouble(json['algo']),
        asa: parseDouble(json['asa']),
        nft: parseDouble(json['nft']),
        total: parseDouble(json['total']),
        totalusdc: parseDouble(json['totalusdc']),
        priceusdc: parseDouble(json['priceusdc']),
        pricealgo: parseDouble(json['pricealgo']),
        noteval: parseInt(json['noteval']),
        totalwonft: parseDouble(json['totalwonft']),
        totalwonftusdc: parseDouble(json['totalwonftusdc']),
      );

  Map<String, dynamic> toJson() => {
        'algo': algo,
        'asa': asa,
        'nft': nft,
        'total': total,
        'totalusdc': totalusdc,
        'priceusdc': priceusdc,
        'pricealgo': pricealgo,
        'noteval': noteval,
        'totalwonft': totalwonft,
        'totalwonftusdc': totalwonftusdc,
      };
}
