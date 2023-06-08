import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/utility/screen.dart';
import 'package:expand_tap_area/expand_tap_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeAppBar {
  static PreferredSizeWidget build(
    BuildContext context, {
    required double height,
    required String slogan,
    required Function() onMenuTap,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        padding: EdgeInsets.only(
          top: 50.h,
          left: Dimensions.PADDING_SIZE_LARGE,
          right: Dimensions.PADDING_SIZE_LARGE,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(Dimensions.RADIUS_SIZE_LARGE20),
              bottomRight: Radius.circular(Dimensions.RADIUS_SIZE_LARGE20)),
          color: ColorResources.secondaryColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: 0,
              color: ColorResources.blackColor.withOpacity(.06),
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onMenuTap,
                  child: Image.asset(
                    Images.IC_NAV,
                    height: 20,
                    width: 20,
                  ),
                ),
                AdaptiveOrientation(
                  portrait: Image.asset(
                    Images.APP_LOGO_DARK,
                    height: 44,
                    width: 75,
                  ),
                  landscape: Image.asset(
                    Images.APP_LOGO_DARK,
                    height: 44,
                    width: 75,
                  ),
                ),
                const SizedBox(height: 20, width: 20)
              ],
            ),
            SizedBox(height: 23.h),
            SizedBox(
              height: 55.h,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                child: Text(
                  slogan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorResources.whiteColor,
                    fontSize: Dimensions.FONT_SIZE_LARGE_18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const AdaptiveOrientation(
              portrait: SizedBox(height: 40),
              landscape: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  static PreferredSizeWidget commonAppBar(
    BuildContext context, {
    required double height,
    double topPadding = 50,
    required Function() onMenuTap,
    bool isMenu = false,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height.h),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(
            top: topPadding.h,
            left: Dimensions.PADDING_SIZE_LARGE,
            right: Dimensions.PADDING_SIZE_LARGE),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(Dimensions.RADIUS_SIZE_LARGE20),
                bottomRight: Radius.circular(Dimensions.RADIUS_SIZE_LARGE20)),
            color: ColorResources.secondaryColor,
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                spreadRadius: 0,
                color: ColorResources.themeTextColor(context).withOpacity(.06),
                offset: const Offset(2, 0),
              )
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ExpandTapWidget(
                  onTap: onMenuTap,
                  tapPadding: const EdgeInsets.all(10),
                  child: RotatedBox(
                    quarterTurns: isMenu ? 0 : 1,
                    child: isMenu
                        ? Image.asset(
                            Images.IC_NAV,
                            height: 20,
                            width: 20,
                          )
                        : Image.asset(
                            Images.IC_DROP_DOWN,
                            height: 15,
                            width: 15,
                          ),
                  ),
                ),
                AdaptiveOrientation(
                  portrait: Image.asset(
                    Images.APP_LOGO_DARK_BIG,
                    height: 44,
                    width: 75,
                  ),
                  landscape: Image.asset(
                    Images.APP_LOGO_DARK_BIG,
                    height: 44,
                    width: 75,
                  ),
                ),
                SizedBox(height: 20.h, width: 20)
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
