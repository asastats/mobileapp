import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:flutter/material.dart';

class ThemeButton extends StatelessWidget {
  final String title;
  final double buttonHeight;
  final Color color;
  final Color textColor;
  final Function() onTap;
  const ThemeButton({
    Key? key,
    this.buttonHeight = 50,
    required this.onTap,
    required this.title,
    this.color = ColorResources.primaryColor,
    this.textColor = ColorResources.whiteColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
        color: color,
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 4),
            color: ColorResources.blackColor.withOpacity(0.05),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
          splashColor: ColorResources.secondaryColor,
          child: Container(
            width: double.maxFinite,
            height: buttonHeight,
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: Dimensions.FONT_SIZE_LARGE),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeTextButton extends StatelessWidget {
  final String title;
  final double buttonHeight;
  final Color textColor;
  final Function() onTap;
  const ThemeTextButton({
    Key? key,
    this.buttonHeight = 50,
    required this.onTap,
    required this.title,
    this.textColor = ColorResources.darkBlackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
          splashColor: ColorResources.secondaryColor,
          child: Container(
            width: double.maxFinite,
            height: buttonHeight,
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: Dimensions.FONT_SIZE_LARGE,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
