import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/widgets/auto_complete_textfield/src/flutter_typeahead.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/app_constants.dart';
import '../../../config/images.dart';

class AddressField extends StatefulWidget {
  final formKey;
  final Function(String error) onError;
  final Function(bool isExpand) onExpand;
  TextEditingController controller;
  AddressField({
    Key? key,
    required this.formKey,
    required this.onError,
    required this.onExpand,
    required this.controller,
  }) : super(key: key);

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  String error = "";
  bool isExpand = false;
  SuggestionsBoxController suggestionsBoxController =
      SuggestionsBoxController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (isExpand ? 150 : 48) + (error.isEmpty ? 0 : 30),
      padding: const EdgeInsets.only(
        right: Dimensions.PADDING_SIZE_SMALL,
      ),
      decoration: BoxDecoration(
        color: ColorResources.backgroundColor(context),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 4),
            color: ColorResources.themeTextColor(context).withOpacity(0.05),
          )
        ],
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_TEN),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_TEN),
        child: Form(
          key: widget.formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: isExpand
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TypeAheadFormField(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: widget.controller,
                          onChanged: (str) {
                            suggestionsBoxController.resize();
                          },
                          onTap: () {
                            suggestionsBoxController.resize();
                          },
                          style: const TextStyle(
                            color: ColorResources.textColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                          ),
                          keyboardType: TextInputType.multiline,
                          maxLines: isExpand ? 7 : 1,
                          textInputAction: isExpand
                              ? TextInputAction.newline
                              : TextInputAction.done,
                          cursorColor: ColorResources.primaryColor,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                              vertical: Dimensions.PADDING_SIZE_SMALL,
                            ),
                            // contentPadding: EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT.w,right: Dimensions.PADDING_SIZE_DEFAULT.w,
                            // top:Dimensions.PADDING_SIZE_SMALL.h, bottom: Dimensions.PADDING_SIZE_SMALL.h ),
                            border: InputBorder.none,
                            hintText: isExpand
                                ? "Enter up to five Algorand addresses"
                                : "Algorand address",
                            hintStyle: const TextStyle(
                              color: ColorResources.textColor,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                            ),
                            filled: true,
                            fillColor: ColorResources.backgroundColor(context),
                            errorStyle: const TextStyle(height: 0, fontSize: 0),
                          ),
                          onEditingComplete: () =>
                              TextInput.finishAutofillContext(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            error = "Invalid Algorand address!";
                          } else {
                            error = "";
                          }
                          setState(() {});
                          widget.onError(error);
                          return error.isEmpty ? null : error;
                        },
                        onSaved: (val) {
                          Provider.of<ASAProvider>(context, listen: false)
                                  .address =
                              kDebugMode
                                  ? val?.split("\n").join(",")
                                  : val?.split("\n").join(",");
                        },
                        hideOnEmpty: true,
                        hideOnLoading: true,
                        hideSuggestionsOnKeyboardHide: true,
                        getImmediateSuggestions: true,
                        hideOnError: true,
                        // suggestionsBoxVerticalOffset:isExpand ? 100 : 0,
                        itemBuilder: (context, String suggestion) {
                          return ListTile(
                            title: Text(
                              suggestion,
                              style: const TextStyle(
                                color: ColorResources.textColor,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                              ),
                            ),
                          );
                        },
                        suggestionsBoxDecoration: SuggestionsBoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onSuggestionSelected: (String suggestion) {
                          widget.controller.text = suggestion;
                        },
                        transitionBuilder:
                            (context, suggestionsBox, controller) {
                          return suggestionsBox;
                        },
                        suggestionsBoxController: suggestionsBoxController,
                        suggestionsCallback: (String pattern) {
                          List<String> matches = <String>[];
                          matches.addAll(
                              Provider.of<ASAProvider>(context, listen: false)
                                  .getAddress());
                          matches = [
                            ...matches.where((s) =>
                                s.toLowerCase().contains(pattern.toLowerCase()))
                          ].toList();
                          return matches;
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: _onExpand,
                      child: Container(
                        height: 24,
                        width: 24,
                        margin: const EdgeInsets.only(
                          top: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                          bottom: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 6),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorResources.secondaryColor),
                        child: Image.asset(
                          isExpand ? Images.IC_ARROW_UP : Images.IC_DROP_DOWN,
                          height: 8,
                          width: 4,
                          color: ColorResources.whiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (error.isNotEmpty)
                  Text(
                    error,
                    style: const TextStyle(
                      color: ColorResources.redColor,
                      fontSize: Dimensions.FONT_SIZE_DEFAULT,
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onExpand() {
    setState(() {
      isExpand = !isExpand;
      widget.onExpand(isExpand);
    });
    suggestionsBoxController.toggle();
  }
}
