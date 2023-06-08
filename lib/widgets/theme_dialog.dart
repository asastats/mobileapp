import 'package:flutter/material.dart';

import '../config/color.dart';
import '../config/dimensions.dart';
import 'buttons/theme_button.dart';

class ThemeDeleteDialog extends StatelessWidget {
  final String title;
  final String icon;
  final Function() onTap;
  const ThemeDeleteDialog({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.delete,
            size: 56,
            color: ColorResources.redColor,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: ColorResources.themeTextColor(context),
              fontSize: Dimensions.FONT_SIZE_15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: ThemeTextButton(
                  onTap: onTap,
                  title: "Delete",
                  textColor: ColorResources.redColor,
                )),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: ThemeButton(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    title: "Cancel",
                    buttonHeight: 50,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 4,
          ),
        ],
      ),
    );
  }
}
