import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../models/response/value.dart';

class ValueBuilder extends StatelessWidget {
  final Value value;
  final bool isAlgo;
  final double priceusdc;
  const ValueBuilder({
    Key? key,
    required this.value,
    required this.isAlgo,
    required this.priceusdc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4.h,
          spacing: 4.w,
          children: [
            if (value.linktext != null)
              GestureDetector(
                onTap: () {
                  launchURLApp(value.link ?? "");
                },
                child: Tooltip(
                  message: value.title,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 3.h,
                      horizontal: value.border != true ? 0 : 8.w,
                    ),
                    decoration: value.border == true
                        ? BoxDecoration(
                            color: ColorResources.primaryColor,
                            borderRadius: BorderRadius.circular(2.h),
                          )
                        : null,
                    child: Text(
                      value.linktext ?? "",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value.border != true
                            ? ColorResources.themeTextColor(context)
                            : ColorResources.themeTextColorReverse(context),
                        fontSize: Dimensions.FONT_SIZE_SMALL,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                      ),
                    ),
                  ),
                ),
              ),
            RichText(
              text: TextSpan(
                text: value.bracket == true || (value.value ?? 0.0).isNegative
                    ? (value.value ?? 0.0).isNegative
                        ? "("
                        : "["
                    : "",
                style: TextStyle(
                  color: ColorResources.themeTextColor(context),
                  fontSize: Dimensions.FONT_SIZE_SMALL,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                ),
                children: [
                  TextSpan(
                    text:
                        "${isAlgo ? value.value?.toStringAsFixed(2) ?? "" : ((value.value ?? 0) / priceusdc).toStringAsFixed(2).toString()} ${isAlgo ? "ALGO" : "USD"}",
                    style: TextStyle(
                      color: (value.value ?? 0.0).isNegative
                          ? ColorResources.redColor
                          : ColorResources.themeTextColor(context),
                    ),
                  ),
                  TextSpan(
                    text:
                        value.bracket == true || (value.value ?? 0.0).isNegative
                            ? (value.value ?? 0.0).isNegative
                                ? ")"
                                : "]"
                            : "",
                    style: TextStyle(
                      color: ColorResources.themeTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
