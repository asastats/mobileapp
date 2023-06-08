import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_constants.dart';

enum Currency { algo, usd }

class AppSettingRepo {
  final SharedPreferences sharedPreferences;

  AppSettingRepo({required this.sharedPreferences});

  Future<bool> setCurrency(Currency currency) {
    return sharedPreferences.setString(AppConstants.CURRENCY, currency.name);
  }

  Currency getCurrency() {
    return ((sharedPreferences.getString(AppConstants.CURRENCY) ??
                Currency.algo.name)) ==
            Currency.algo.name
        ? Currency.algo
        : Currency.usd;
  }

  Future<bool> clearData(String key) {
    return sharedPreferences.remove(key);
  }

  Future<bool> clearSharedData() {
    return sharedPreferences.clear();
  }
}
