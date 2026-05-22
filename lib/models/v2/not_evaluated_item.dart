// NotEvaluatedItem — an asset the user holds whose value the pricing
// pipeline couldn't determine. Same general structure as [AsaItem] but
// without ``value`` and ``price`` fields, since those are unknown by
// definition.
//
// Mirrors `api.serializers.NotevalItemSerializer`. Sits at
// ``EvaluatedAccount.notevals``.

import '_json.dart';
import 'asa.dart';
import 'program.dart';

class NotEvaluatedItem {
  final Asa? asset;

  /// User's total holding in micro-units.
  final int? amount;

  /// Programs that reference this asset. Often empty — most non-evaluated
  /// assets are just sitting in a wallet, not deposited anywhere. Surfaced
  /// for the rare cases (e.g. an unrecognised LP token sitting in a vault).
  final List<UserAsaProgram> programs;

  NotEvaluatedItem({this.asset, this.amount, this.programs = const []});

  factory NotEvaluatedItem.fromJson(Map<String, dynamic> json) =>
      NotEvaluatedItem(
        asset: parseObject(json['asset'], Asa.fromJson),
        amount: parseInt(json['amount']),
        programs: parseList(json['programs'], UserAsaProgram.fromJson),
      );

  Map<String, dynamic> toJson() => {
        if (asset != null) 'asset': asset!.toJson(),
        'amount': amount,
        'programs': programs.map((p) => p.toJson()).toList(),
      };
}
