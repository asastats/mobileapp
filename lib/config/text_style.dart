import 'package:flutter/material.dart';
import 'dimensions.dart';

class TextStyles {
  static Text normal({required String text, required Color color}) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: null,
      style: TextStyle(
        fontSize: Dimensions.FONT_SIZE_DEFAULT,
        color: color,
      ),
    );
  }

  static Text heading({required String text, required Color color}) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: Dimensions.FONT_SIZE_MAX_26,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  static TextStyle bodyText() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_DEFAULT,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle headline1() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_15,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headline2() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_LARGE,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headline3() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_LARGE_18,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headline4() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_LARGE_24,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headline5() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_MAX_26,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headline6() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_MAX_28,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headlineLarge() {
    return const TextStyle(
      fontSize: Dimensions.FONT_SIZE_MAX,
      fontWeight: FontWeight.w600,
    );
  }
}
