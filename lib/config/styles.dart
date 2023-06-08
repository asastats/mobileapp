import 'package:asa_stats/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asa_stats/config/app_constants.dart';
import 'package:provider/provider.dart';

import 'color.dart';
import 'text_style.dart';

class Style {
  static ThemeData appTheme(BuildContext context) {
    return ThemeData(
      primaryColor: ColorResources.primaryColor,
      scaffoldBackgroundColor: ColorResources.backgroundColor(context),
      fontFamily: AppConstants.FONT_FAMILY,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorResources.transparent,
        foregroundColor: ColorResources.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: ColorResources.primaryColor,
        ),
        titleTextStyle: TextStyle(
          color: ColorResources.primaryColor,
        ),
      ),
      iconTheme: const IconThemeData(
        color: ColorResources.darkBlackColor,
      ),
      textTheme: TextTheme(
        bodyText1: TextStyles.bodyText(),
        headline1: TextStyles.headline1(),
        headline2: TextStyles.headline2(),
        headline3: TextStyles.headline3(),
        headline4: TextStyles.headline4(),
        headline5: TextStyles.headline5(),
        headline6: TextStyles.headline6(),
        headlineLarge: TextStyles.headlineLarge(),
      ),
    );
  }

  static SystemUiOverlayStyle systemUiOverlayStyle(BuildContext context) =>
      SystemUiOverlayStyle(
        systemNavigationBarColor: ColorResources.backgroundColor(context),
        statusBarColor: ColorResources.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,

        // Status bar brightness (optional)
        statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
        statusBarBrightness: Brightness.dark, // For iOS (dark icons)
      );

  static SystemUiOverlayStyle systemUiOverlayStyleManual(
          BuildContext context, Brightness brightness) =>
      SystemUiOverlayStyle(
        systemNavigationBarColor: brightness == Brightness.light
            ? ColorResources.blackColor
            : ColorResources.whiteColor,
        statusBarColor: ColorResources.transparent,
        systemNavigationBarIconBrightness: brightness,

        // Status bar brightness (optional)
        statusBarIconBrightness: brightness, // For Android (dark icons)
        statusBarBrightness: brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light, // For iOS (dark icons)
      );
}
