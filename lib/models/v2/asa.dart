// Asa — an Algorand Standard Asset's static metadata.
//
// Mirrors `api.serializers.AsaSerializer`.

import '_json.dart';
import 'program.dart' show OffchainLink;

class Asa {
  /// Asset id. ``0`` is the special ALGO id; everything else is an ASA.
  final int? id;

  final String? name;

  /// Asset's display unit (e.g. "ALGO", "USDC", "YLDY"). May be empty.
  /// We surface it as a non-null empty string because the website treats
  /// the missing-unit case the same as the empty-unit case.
  final String unit;

  /// Asset's total supply as declared by the API (decimals already
  /// baked in — same semantics as v1). E.g. an 18-billion supply
  /// asset comes through as ``18000000000``, not ``18000000000_000000``.
  /// Surfaced as ``int`` not ``double`` because some totals exceed
  /// ``2^53``.
  final int? total;

  final int? decimals;

  /// The asset creator's declared URL. May not begin with "http" — the
  /// website prepends "https://" in that case (see meta.html template).
  final String? url;

  /// Off-chain price-screener links (CoinMarketCap, Vestige, etc.).
  /// May be empty.
  final List<OffchainLink> links;

  Asa({
    this.id,
    this.name,
    this.unit = '',
    this.total,
    this.decimals,
    this.url,
    this.links = const [],
  });

  factory Asa.fromJson(Map<String, dynamic> json) => Asa(
        id: parseInt(json['id']),
        name: parseString(json['name']),
        // unit gets surfaced as the empty string when missing or null.
        // The website's templates rely on ``{{ asset.unit }}`` always
        // being safe to render directly.
        unit: parseString(json['unit']) ?? '',
        total: parseInt(json['total']),
        decimals: parseInt(json['decimals']),
        url: parseString(json['url']),
        links: parseList(json['links'], OffchainLink.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        'unit': unit,
        if (total != null) 'total': total,
        if (decimals != null) 'decimals': decimals,
        if (url != null) 'url': url,
        'links': links.map((l) => l.toJson()).toList(),
      };

  /// Convenience: is this the ALGO native asset?
  bool get isAlgo => id == 0;
}
