// Shared JSON parsing helpers for the v2 model layer.
//
// Every model file in lib/models/v2/ uses these to keep its fromJson
// implementations short, consistent, and defensive against the DRF
// serializer's "drop None fields" behaviour. The serializers we mirror
// use `to_representation` to strip fields whose value is null, so
// production payloads have keys missing-by-design (not null-valued).
// All these helpers treat "key missing" and "value is null" identically.

/// Read a list-of-objects JSON field and map each element through ``factory``.
///
/// Returns ``const []`` when the field is missing, null, or not a list.
/// Non-map elements inside the list are silently skipped so a server-side
/// quirk in one row can't crash the whole parse.
List<T> parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) factory,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map<T>(factory)
      .toList(growable: false);
}

/// Read a JSON object field and pass it through ``factory``, or return null.
T? parseObject<T>(Object? raw, T Function(Map<String, dynamic>) factory) {
  if (raw is! Map<String, dynamic>) return null;
  return factory(raw);
}

/// Read a JSON field as a Dart [double].
///
/// Handles four shapes that DRF can emit for a [DecimalField]:
///   - JSON number  (rare with default settings, accepted for robustness)
///   - JSON string  (default DRF behaviour, e.g. ``"115.533581"``)
///   - JSON null    (field omitted entirely by serializer ``to_representation``)
///   - missing key  (same as null)
///
/// Returns ``null`` only when the value is genuinely absent. An unparseable
/// string returns ``null`` too rather than throwing, on the grounds that a
/// single bad field shouldn't kill the whole account parse.
double? parseDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

/// Read a JSON field as a Dart [int].
///
/// Asset ``amount`` fields are micro-units (often >2^31), so we deliberately
/// take the [num].toInt path rather than ``int.parse`` to handle both
/// JSON int and JSON string inputs.
int? parseInt(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

/// Read a JSON field as a Dart [String], returning null for anything not
/// stringy. We don't coerce numbers to strings on read — that hides type
/// regressions in the API that we'd rather surface during testing.
String? parseString(Object? raw) {
  if (raw is String) return raw;
  return null;
}

/// Read a JSON field as a Dart [bool], returning null for non-bool inputs.
bool? parseBool(Object? raw) {
  if (raw is bool) return raw;
  return null;
}
