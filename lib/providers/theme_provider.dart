import 'package:asa_stats/config/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences? sharedPreferences;
  ThemeProvider({required this.sharedPreferences}) {
    _loadCurrentTheme();
  }

  bool _darkTheme = true;
  bool get darkTheme => _darkTheme;

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    sharedPreferences?.setBool(AppConstants.THEME, _darkTheme) ?? false;
    notifyListeners();
  }

  void _loadCurrentTheme() async {
    _darkTheme = sharedPreferences?.getBool(AppConstants.THEME) ?? false;
    notifyListeners();
  }
}
