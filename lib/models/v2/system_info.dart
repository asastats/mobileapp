// SystemInfo — operator-facing messages attached to the account.
//
// Mirrors `api.serializers.SystemInfoSerializer`. Both fields are
// dropped from the payload when null by the serializer's
// `to_representation`, so an "no warning, no information" payload will
// have system_info absent entirely from the JSON, not present-but-empty.

import '_json.dart';

class SystemInfo {
  /// User-visible warning (e.g. "Cache stale, retry in 5 minutes"). Empty
  /// or null in the happy path.
  final String? warning;

  /// User-visible informational message (e.g. promotional banner text).
  final String? information;

  SystemInfo({this.warning, this.information});

  factory SystemInfo.fromJson(Map<String, dynamic> json) => SystemInfo(
        warning: parseString(json['warning']),
        information: parseString(json['information']),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (warning != null) map['warning'] = warning;
    if (information != null) map['information'] = information;
    return map;
  }
}
