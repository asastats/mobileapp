import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../models/response/amount.dart';
import '../../utility/utils.dart';

class AmountBuilder extends StatelessWidget {
  final Amount amount;
  // final bool isAlgo;
  final int decimal;
  const AmountBuilder({
    Key? key,
    required this.amount,
    // required this.isAlgo,
    required this.decimal,
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
          children: [
            if (amount.text != null)
              Tooltip(
                message: amount.text,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 2.h,
                    horizontal: amount.border != true ? 0 : 8.w,
                  ),
                  decoration: amount.border == true
                      ? BoxDecoration(
                          color: ColorResources.primaryColor,
                          borderRadius: BorderRadius.circular(2.h),
                        )
                      : null,
                  child: Text(
                    amount.text ?? "",
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: amount.border != true
                          ? ColorResources.themeTextColor(context)
                          : ColorResources.themeTextColorReverse(context),
                      fontSize: Dimensions.FONT_SIZE_SMALL,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                    ),
                  ),
                ),
              ),
            if (amount.text != null) SizedBox(height: 5.h, width: 3.w),
            RichText(
              textAlign: TextAlign.end,
              text: TextSpan(
                text: (amount.bracket == true ||
                        (amount.amount ?? 0.0).isNegative)
                    ? (amount.amount ?? 0.0).isNegative
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

                        /// WIP
                        /* amount.bracket == true
                        ? '${amount.amount}'
                        :  */
                        "${AppConstants.formateNumber(double.parse(formateAmount(amount.amount ?? 0, decimal, 6)), points: "0" * decimal)} ${amount.unit}", // conversion of usd
                    style: TextStyle(
                      color: (amount.amount ?? 0.0).isNegative
                          ? ColorResources.redColor
                          : ColorResources.themeTextColor(context),
                    ),
                  ),
                  TextSpan(
                    text: amount.bracket == true ||
                            (amount.amount ?? 0.0).isNegative
                        ? (amount.amount ?? 0.0).isNegative
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
