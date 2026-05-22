// Program/distribution/linked-data models that hang off each AsaItem.
//
// These five small classes are grouped in one file because they're tightly
// coupled (each refers to the others) and small enough not to warrant
// per-class files. Mirrors a corresponding cluster in
// `api.serializers.py`: AsaProgramSerializer, AsaLinkSerializer,
// DistributionLinkSerializer, LinkedDataSerializer, DistributionSerializer,
// AsaItemProgramSerializer.

import '_json.dart';
import 'provider.dart';

/// A dApp program — the identity/metadata of a program-level entry
/// (e.g. "Tinyman2 Liquidity", "Folks Finance Lending"). The user-specific
/// numbers (value, amount, distribution) live on [UserAsaProgram].
///
/// Mirrors `api.serializers.AsaProgramSerializer`.
class AsaProgram {
  /// Program category — "Balance", "Added", "Locked", "Staked", "Deposited",
  /// "Collateral", "Supplied", "Delegated", "Withdrawal", "Borrowed",
  /// "Amount", "Committed" (governance), "Max stake" (consensus), etc.
  /// The website dispatches its per-program rendering on this field;
  /// the mobile app currently dispatches on the legacy ``dapp`` code, so
  /// the migration moves it to this field instead.
  final String? type;

  /// Display name — "Tinyman2 LP", "Folks Finance", "Algorand Governance".
  final String? name;

  final Provider? provider;

  /// URL to the dApp's own page for this program.
  final String? url;

  /// Internal program code — same code used internally on the backend
  /// (e.g. "tm2lp", "ffl"). Surfaced for analytics / debug; never user-facing.
  final String? code;

  AsaProgram({this.type, this.name, this.provider, this.url, this.code});

  factory AsaProgram.fromJson(Map<String, dynamic> json) => AsaProgram(
        type: parseString(json['type']),
        name: parseString(json['name']),
        provider: parseObject(json['provider'], Provider.fromJson),
        url: parseString(json['url']),
        code: parseString(json['code']),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (type != null) map['type'] = type;
    if (name != null) map['name'] = name;
    if (provider != null) map['provider'] = provider!.toJson();
    if (url != null) map['url'] = url;
    if (code != null) map['code'] = code;
    return map;
  }
}

/// An off-chain link advertised for an asset (CoinMarketCap, DEX Screener,
/// Live Coin Watch, Vestige, Haystack).
///
/// Mirrors `api.serializers.AsaLinkSerializer` (component_name `OffchainLink`).
class OffchainLink {
  final Provider? provider;
  final String? link;
  final String? title;

  OffchainLink({this.provider, this.link, this.title});

  factory OffchainLink.fromJson(Map<String, dynamic> json) => OffchainLink(
        provider: parseObject(json['provider'], Provider.fromJson),
        link: parseString(json['link']),
        title: parseString(json['title']),
      );

  Map<String, dynamic> toJson() => {
        if (provider != null) 'provider': provider!.toJson(),
        if (link != null) 'link': link,
        if (title != null) 'title': title,
      };
}

/// The link inside a distribution row — points to the AMM pool, the
/// lending pool, etc. as a clickable destination.
///
/// Mirrors `api.serializers.DistributionLinkSerializer`.
class DistributionLink {
  final Provider? provider;
  final String? text;
  final String? url;

  DistributionLink({this.provider, this.text, this.url});

  factory DistributionLink.fromJson(Map<String, dynamic> json) =>
      DistributionLink(
        provider: parseObject(json['provider'], Provider.fromJson),
        text: parseString(json['text']),
        url: parseString(json['url']),
      );

  Map<String, dynamic> toJson() => {
        if (provider != null) 'provider': provider!.toJson(),
        if (text != null) 'text': text,
        if (url != null) 'url': url,
      };
}

/// One row of a per-program distribution breakdown — e.g. one pool that
/// holds part of a Tinyman LP position.
///
/// Mirrors `api.serializers.DistributionSerializer`.
class Distribution {
  final double? value;
  final int? amount;
  final DistributionLink? link;

  Distribution({this.value, this.amount, this.link});

  factory Distribution.fromJson(Map<String, dynamic> json) => Distribution(
        value: parseDouble(json['value']),
        amount: parseInt(json['amount']),
        link: parseObject(json['link'], DistributionLink.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'amount': amount,
        if (link != null) 'link': link!.toJson(),
      };
}

/// An auxiliary linked datum next to a program row — e.g. "Available: X"
/// next to an ALGO Balance row, "Property page" link on a Lofty asset's
/// Balance row, "App ID" identifier on a Folks Finance program row.
///
/// Mirrors `api.serializers.LinkedDataSerializer`. ``to_representation``
/// strips null fields, so a payload like ``{"text": "Available", "value": "23.13"}``
/// is normal and complete — the missing ``link``/``amount``/etc. just
/// means those didn't apply.
class LinkedData {
  final Provider? provider;
  final String? text;
  final String? link;
  final double? value;
  final int? amount;
  final int? balance;
  final String? info;

  /// Identifier (numeric). Note: this is ``int`` on the wire even though
  /// it shares a name with the asset id field used elsewhere; safe to
  /// surface as-is because no consumer treats it as an asset reference.
  final int? id;

  LinkedData({
    this.provider,
    this.text,
    this.link,
    this.value,
    this.amount,
    this.balance,
    this.info,
    this.id,
  });

  factory LinkedData.fromJson(Map<String, dynamic> json) => LinkedData(
        provider: parseObject(json['provider'], Provider.fromJson),
        text: parseString(json['text']),
        link: parseString(json['link']),
        value: parseDouble(json['value']),
        amount: parseInt(json['amount']),
        balance: parseInt(json['balance']),
        info: parseString(json['info']),
        id: parseInt(json['id']),
      );

  Map<String, dynamic> toJson() => {
        if (provider != null) 'provider': provider!.toJson(),
        if (text != null) 'text': text,
        if (link != null) 'link': link,
        if (value != null) 'value': value,
        if (amount != null) 'amount': amount,
        if (balance != null) 'balance': balance,
        if (info != null) 'info': info,
        if (id != null) 'id': id,
      };
}

/// One per-program entry under an AsaItem. Carries the user-specific value
/// and amount, plus optional breakdown (distribution) and side-channel
/// labels (linked).
///
/// Mirrors `api.serializers.AsaItemProgramSerializer` (component_name
/// `UserAsaProgram`).
class UserAsaProgram {
  final AsaProgram? program;
  final double? value;
  final int? amount;

  /// Reserved for future use. Currently `StringRelatedField(many=True)`
  /// on the backend, which serializes to ``List<String>`` if populated.
  /// Always an empty list in production today, but the field is part of
  /// the wire contract.
  final List<String> proxy;

  final List<Distribution> distribution;
  final List<LinkedData> linked;

  UserAsaProgram({
    this.program,
    this.value,
    this.amount,
    this.proxy = const [],
    this.distribution = const [],
    this.linked = const [],
  });

  factory UserAsaProgram.fromJson(Map<String, dynamic> json) {
    final rawProxy = json['proxy'];
    return UserAsaProgram(
      program: parseObject(json['program'], AsaProgram.fromJson),
      value: parseDouble(json['value']),
      amount: parseInt(json['amount']),
      proxy: rawProxy is List
          ? rawProxy.whereType<String>().toList(growable: false)
          : const [],
      distribution: parseList(json['distribution'], Distribution.fromJson),
      linked: parseList(json['linked'], LinkedData.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        if (program != null) 'program': program!.toJson(),
        'value': value,
        'amount': amount,
        'proxy': proxy,
        'distribution': distribution.map((d) => d.toJson()).toList(),
        'linked': linked.map((l) => l.toJson()).toList(),
      };

  /// Convenience: true when this program has a multi-row breakdown.
  /// Mirrors the website's ``has_breakdown`` check used to decide
  /// whether to render the toggle-able panel.
  bool get hasBreakdown => distribution.isNotEmpty;
}
