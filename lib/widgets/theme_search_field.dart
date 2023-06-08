import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSearchField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  const ThemeSearchField({
    Key? key,
    required this.hint,
    required this.onChanged,
    required this.controller,
    this.focusNode,
  }) : super(key: key);

  @override
  State<ThemeSearchField> createState() => _ThemeSearchFieldState();
}

class _ThemeSearchFieldState extends State<ThemeSearchField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: ColorResources.backgroundColor(context),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(4, 4),
            color: ColorResources.blackColor.withOpacity(0.05),
          )
        ],
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
      ),
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(
          color: ColorResources.textColor,
          fontWeight: FontWeight.w500,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
        focusNode: widget.focusNode,
        cursorColor: ColorResources.primaryColor,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          isDense: true,
          border: border(context),
          enabledBorder: border(context),
          focusedBorder: border(context),
          disabledBorder: border(context),
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: ColorResources.textColor,
            fontWeight: FontWeight.w500,
            fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          ),
          filled: true,
          fillColor: ColorResources.backgroundColor(context),
        ),
      ),
    );
  }

  OutlineInputBorder border(BuildContext context) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
      borderSide: Provider.of<ThemeProvider>(context).darkTheme
          ? const BorderSide(width: 1, color: ColorResources.secondaryColor)
          : BorderSide.none);
}
