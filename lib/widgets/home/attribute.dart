import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../providers/theme_provider.dart';

enum TextType {
  link,
  text,
}

class Attribute extends StatelessWidget {
  final String label;
  final String? value;
  final Color? color;
  final TextType? type;
  final Function()? onValueTap;
  const Attribute({
    Key? key,
    required this.label,
    this.value,
    this.color,
    this.type = TextType.text,
    this.onValueTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (value != null ? " : " : ""), //address
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ColorResources.themeTextColor(context),
              fontSize: Dimensions.FONT_SIZE_SMALL,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
            ),
          ),
          if (value != null)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (onValueTap != null) {
                    onValueTap!();
                  }
                  if (type == TextType.link) {
                    launchURLApp(value!);
                  }
                },
                child: Text(
                  value!, //address
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    color: color ??
                        (Provider.of<ThemeProvider>(context).darkTheme
                            ? ColorResources.whiteColor
                            : const Color(0xffA8A7A7)),
                    fontSize: Dimensions.FONT_SIZE_SMALL,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
