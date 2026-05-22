// AccountInfo — basic addresses/bundle info for the queried account.
//
// Mirrors `api.serializers.AccountInfoSerializer`.

import '_json.dart';

class AccountInfo {
  /// Public Algorand addresses associated with the account. Always non-null
  /// and non-empty for a successful response (single address: 1 element;
  /// bundle: 2-5 elements).
  final List<String> addresses;

  /// 40-char SHA1 hash identifying the bundle. Set even for a single
  /// address (it's the lookup key into the bundle cache).
  final String? bundle;

  /// Currency that ``value`` fields throughout the payload are denominated
  /// in. Currently always ``"ALGO"`` since `core.views.BaseAddressView`
  /// doesn't expose the USD setting yet, but the field is part of the API
  /// contract so we surface it.
  final String? valuesIn;

  /// True if any address in the bundle participates in Algorand consensus.
  final bool? online;

  /// Total Algoland points across the bundle.
  final int? points;

  AccountInfo({
    this.addresses = const [],
    this.bundle,
    this.valuesIn,
    this.online,
    this.points,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'];
    return AccountInfo(
      addresses: rawAddresses is List
          ? rawAddresses.whereType<String>().toList(growable: false)
          : const [],
      bundle: parseString(json['bundle']),
      valuesIn: parseString(json['values_in']),
      online: parseBool(json['online']),
      points: parseInt(json['points']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'addresses': addresses};
    if (bundle != null) map['bundle'] = bundle;
    if (valuesIn != null) map['values_in'] = valuesIn;
    if (online != null) map['online'] = online;
    if (points != null) map['points'] = points;
    return map;
  }
}
