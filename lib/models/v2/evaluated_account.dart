// API 2.0 model layer — top-level EvaluatedAccount.
//
// This file (and its siblings in lib/models/v2/) defines Dart classes that
// mirror the DRF serializers in api/serializers.py 1:1. They live in a
// parallel directory so the legacy v1 models in lib/models/response/ keep
// working unchanged during the migration. Once all screens are migrated
// off v1, the v1 models are deleted.
//
// Conventions copied from the v1 models for consistency:
//   - Hand-rolled fromJson / toJson on every class (no code generation).
//   - Nullable fields throughout; defensive parsing on every read.
//   - `double` for currency amounts (matches v1 widget arithmetic),
//     `int` for asset-amount micro-units.
//   - JSON keys match the DRF serializer field names verbatim, so a
//     payload that flows through `EvaluatedAccountSerializer` can be
//     round-tripped through `EvaluatedAccount.fromJson(...).toJson()`
//     with structural equality (modulo `to_representation`'s null-strip).

import '_json.dart';
import 'account_info.dart';
import 'asa_item.dart';
import 'nft_collection.dart';
import 'not_evaluated_item.dart';
import 'system_info.dart';
import 'total.dart';

/// Top-level response shape returned by `GET /api/v2/{address}/`,
/// `GET /api/v2/{bundle}/`, and `GET /api/v2/{nfd_name}/`.
///
/// Mirrors `api.serializers.EvaluatedAccountSerializer`.
class EvaluatedAccount {
  final AccountInfo? accountInfo;
  final SystemInfo? systemInfo;
  final Total? total;
  final List<AsaItem> asaitems;
  final List<NftCollection> nftcollections;
  final List<NotEvaluatedItem> notevals;

  EvaluatedAccount({
    this.accountInfo,
    this.systemInfo,
    this.total,
    this.asaitems = const [],
    this.nftcollections = const [],
    this.notevals = const [],
  });

  factory EvaluatedAccount.fromJson(Map<String, dynamic> json) {
    return EvaluatedAccount(
      accountInfo: parseObject(json['account_info'], AccountInfo.fromJson),
      systemInfo: parseObject(json['system_info'], SystemInfo.fromJson),
      total: parseObject(json['total'], Total.fromJson),
      asaitems: parseList(json['asaitems'], AsaItem.fromJson),
      nftcollections: parseList(json['nftcollections'], NftCollection.fromJson),
      notevals: parseList(json['notevals'], NotEvaluatedItem.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (accountInfo != null) map['account_info'] = accountInfo!.toJson();
    if (systemInfo != null) map['system_info'] = systemInfo!.toJson();
    if (total != null) map['total'] = total!.toJson();
    map['asaitems'] = asaitems.map((e) => e.toJson()).toList();
    map['nftcollections'] = nftcollections.map((e) => e.toJson()).toList();
    map['notevals'] = notevals.map((e) => e.toJson()).toList();
    return map;
  }

  /// Convenience: same as ``accountInfo.addresses.length > 1`` but defends
  /// against a missing ``account_info`` block. Mirrors the Phase 1 view's
  /// ``is_bundle`` derived flag.
  bool get isBundle => (accountInfo?.addresses.length ?? 0) > 1;
}
