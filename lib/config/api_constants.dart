// ignore_for_file: constant_identifier_names

class APIConstants {
  // V1 — kept until Phase 5d cleanup so any unmigrated code still works.
  static const String BASE_URL = "https://www.asastats.com/api/";
  static const String GLOBAL_SETTING_URL = "https://www.asastats.com/api/settings/";

  // V2 — used by the new repo / provider methods.
  // The mobile app's data layer migrates piecewise (Phase 5b adds the new
  // methods; Phase 5c migrates screens; Phase 5d deletes V1). Until then,
  // both base URLs coexist.
  static const String BASE_URL_V2 = "https://www.asastats.com/api/v2/";
  static const String SETTINGS_URL_V2 =
      "https://www.asastats.com/api/v2/settings/";
}

