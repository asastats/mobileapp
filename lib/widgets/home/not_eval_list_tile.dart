import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../config/images.dart';
import '../../providers/theme_provider.dart';

class NotEvalListTile extends StatefulWidget {
  final bool isExpanded;
  final String title;
  final Function() onExpand;

  const NotEvalListTile({
    Key? key,
    required this.title,
    required this.isExpanded,
    required this.onExpand,
  }) : super(key: key);

  @override
  State<NotEvalListTile> createState() => _NotEvalListTileState();
}

class _NotEvalListTileState extends State<NotEvalListTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onExpand();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
        child: Container(
          height: 50,
          width: double.maxFinite,
          margin: EdgeInsets.only(bottom: 7.h),
          padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
          decoration: BoxDecoration(
            color: widget.isExpanded
                ? ColorResources.primaryColor
                : Provider.of<ThemeProvider>(context).darkTheme
                    ? const Color(0xff373737)
                    : ColorResources.whiteColor,
            borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(4, 4),
                color: ColorResources.blackColor.withOpacity(0.05),
              )
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isExpanded
                        ? ColorResources.whiteColor
                        : ColorResources.themeTextColor(context),
                    fontSize: Dimensions.FONT_SIZE_DEFAULT,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 17.w),
                child: Image.asset(
                  widget.isExpanded ? Images.IC_ARROW_UP : Images.IC_DROP_DOWN,
                  height: 5,
                  width: 10,
                  color: widget.isExpanded
                      ? ColorResources.whiteColor
                      : ColorResources.themeTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
