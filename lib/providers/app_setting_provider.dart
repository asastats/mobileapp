import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:flutter/material.dart';

class AppSettingProvider with ChangeNotifier {
  final AppSettingRepo appSettingRepo;
  late Currency _currency;
  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  Currency get currency => _currency;

  AppSettingProvider({required this.appSettingRepo}) {
    updateCurrency();
  }

  void updateCurrency() {
    _currency = appSettingRepo.getCurrency();
    notifyListeners();
  }

  void setCurrency(Currency currency) async {
    final updated = await appSettingRepo.setCurrency(currency);
    if (updated) {
      updateCurrency();
    }
  }

  void setValue(bool value){
    _isExpanded = value;
    notifyListeners();
  }

  Future<bool> clearData(key) {
    return appSettingRepo.clearData(key);
  }
}
