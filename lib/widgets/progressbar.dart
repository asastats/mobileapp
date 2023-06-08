import 'package:asa_stats/config/color.dart';
import 'package:flutter/material.dart';

class ThemeLinearProgressBar extends StatelessWidget {
  final bool visible;
  const ThemeLinearProgressBar({
    Key? key,
    required this.visible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return visible
        ? LinearProgressIndicator(
            color: ColorResources.primaryColor,
            backgroundColor: ColorResources.themeDataBgColor(context),
          )
        : Container();
  }
}
