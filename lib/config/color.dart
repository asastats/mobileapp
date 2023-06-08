import 'package:asa_stats/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ColorResources {
  // Theme color - Fixed Color
  static const Color primaryColor = Color(0xff00C896);
  static const Color secondaryColor = Color(0xFF575757);

  static Color backgroundColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xFF2B2B2B)
        : const Color(0xffffffff);
  }

  // Other Colors
  static const Color blackColor = Color(0xff000000);
  static const Color textColor = Color(0xff888888);
  static const Color greyDarkColor = Color.fromRGBO(171, 171, 171, 1);
  static const Color darkBlackColor = Color(0xff181A1C);
  static const Color secondaryDarkBlackColor = Color(0xff323436);
  static const Color borderColor = Color(0xffD9D9D9);
  static const Color redColor = Color(0xffFF3769);

  static const Color warningColor = Color(0xffff3769);
  static const Color infoColor = Color(0xff005a34);

  static Color themeTextColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xffffffff)
        : const Color(0xFF575757);
  }

  static Color themeTextColorReverse(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xFF575757)
        : const Color(0xffffffff);
  }

  static Color themeGrayWhiteColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xff888888)
        : const Color(0xFFFFFFFF);
  }

  static Color themeLightGrayWhiteColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xFFFFFFFF)
        : const Color(0xff777777);
  }

  static Color themeDataBgColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).darkTheme
        ? const Color(0xff2B2B2B)
        : const Color(0xFFF9F9F9);
  }

  static const Color whiteColor = Color(0xffffffff);
  static const Color lightBlackColor = Color(0xFF2B2B2B);

  static const Color secondaryWhiteColor = Color(0xffECEBED);

  static const Color greyColor = Color(0xffC5C6D0);
  static const Color dataBgColor = Color(0xffD3D1D8);
  static const Color defaultColor = Color(0xffababab);

  static const Color transparent = Colors.transparent;
}
