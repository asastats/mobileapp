// BundleHash — the JSON object returned by ``POST /api/v2/``.
//
// Mirrors `api.serializers.BundleHashSerializer`. The wire shape is
// ``{"bundle": "<40-char hex>"}``, which differs from the v1 response
// (a bare JSON string ``"<hash>"``).

import '_json.dart';

class BundleHash {
  /// 40-character SHA1 hash identifying the bundle. Pass this as the
  /// next ``GET /api/v2/{bundle}/`` lookup key.
  final String? bundle;

  BundleHash({this.bundle});

  factory BundleHash.fromJson(Map<String, dynamic> json) =>
      BundleHash(bundle: parseString(json['bundle']));

  Map<String, dynamic> toJson() => {if (bundle != null) 'bundle': bundle};
}
