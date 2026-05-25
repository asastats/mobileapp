import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asa_stats/config/app_constants.dart';
import 'package:flutter/cupertino.dart';

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
        bodyLarge: TextStyles.bodyText(), // bodyText1 -> bodyLarge
        displayLarge: TextStyles.headline1(), // headline1 -> displayLarge
        displayMedium: TextStyles.headline2(), // headline2 -> displayMedium
        displaySmall: TextStyles.headline3(), // headline3 -> displaySmall
        headlineMedium: TextStyles.headline4(), // headline4 -> headlineMedium
        headlineSmall: TextStyles.headline5(), // headline5 -> headlineSmall
        titleLarge: TextStyles.headline6(), // headline6 -> titleLarge
        headlineLarge: TextStyles.headlineLarge(), // remains the same
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
