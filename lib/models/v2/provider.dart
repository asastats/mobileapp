// Provider — a third-party platform/protocol entity (e.g. Tinyman, Vestige,
// AlgoExplorer, CoinMarketCap). Used in many places: program providers,
// NFT market sources, asset-page link destinations, distribution-link
// sources, etc.
//
// Mirrors `api.serializers.ProviderSerializer`. Both fields are stripped
// when null by `to_representation`, so a Provider with only ``name`` set
// will arrive as ``{"name": "..."}`` rather than ``{"name": "...", "info": null}``.

import '_json.dart';

class Provider {
  final String? name;
  final String? info;

  Provider({this.name, this.info});

  factory Provider.fromJson(Map<String, dynamic> json) => Provider(
        name: parseString(json['name']),
        info: parseString(json['info']),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (info != null) map['info'] = info;
    return map;
  }

  /// Convenience: slug for ``static/icons/providers/<slug>.png`` matching
  /// the website's ``provider_icon`` template filter. ``"Live Coin Watch"``
  /// becomes ``livecoinwatch``, not ``live-coin-watch``.
  ///
  /// Returns ``null`` when the provider has no name; callers should
  /// handle this rather than producing a broken URL.
  String? get iconSlug {
    final n = name;
    if (n == null || n.isEmpty) return null;
    return n.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }
}
