// AsaItem — the user's holding of one ASA, plus all the programs that
// reference that ASA. One AsaItem per asset id, ordered by ``value``
// descending. The list lives at ``EvaluatedAccount.asaitems``.
//
// Mirrors `api.serializers.AsaItemSerializer`.

import '_json.dart';
import 'asa.dart';
import 'program.dart';

class AsaItem {
  /// Asset's total value across the bundle in ALGO.
  final double? value;

  final Asa? asset;

  /// User's total holding in micro-units. Sum across programs and bare
  /// balance.
  final int? amount;

  /// Per-unit ALGO price for this asset. ``null`` for tokens with no
  /// known market price (those land in the ``notevals`` list instead,
  /// though some priced tokens may still have price=null if they're
  /// priced by aggregate).
  final double? price;

  final List<UserAsaProgram> programs;

  AsaItem({
    this.value,
    this.asset,
    this.amount,
    this.price,
    this.programs = const [],
  });

  factory AsaItem.fromJson(Map<String, dynamic> json) => AsaItem(
        value: parseDouble(json['value']),
        asset: parseObject(json['asset'], Asa.fromJson),
        amount: parseInt(json['amount']),
        price: parseDouble(json['price']),
        programs: parseList(json['programs'], UserAsaProgram.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        if (asset != null) 'asset': asset!.toJson(),
        'amount': amount,
        'price': price,
        'programs': programs.map((p) => p.toJson()).toList(),
      };
}
