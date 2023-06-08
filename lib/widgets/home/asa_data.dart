import 'dart:math' as math;

import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/widgets/home/value_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../data/repository/app_setting_repo.dart';
import '../../models/response/dapps.dart';
import '../../models/response/distribution.dart';
import '../../models/response/total.dart';
import '../../models/response/values.dart';
import '../../screens/menu/menu_screen.dart';
import 'amount_builder.dart';

class ASAData extends StatefulWidget {
  final Values values;
  final bool isAlgo;
  final Total total;
  final Function(bool isExpanded) onExpand;
  const ASAData({
    Key? key,
    required this.values,
    required this.isAlgo,
    required this.total,
    required this.onExpand,
  }) : super(key: key);

  @override
  State<ASAData> createState() => _ASADataState();
}

class _ASADataState extends State<ASAData> {
  bool _isFirstExpand = true;
  List<int> selectedIndexes = [];
  List<int> selectedDapPriceIndex = [];

  _toggleExpand(List<Distribution>? distribution, index) {
    if (distribution?.isNotEmpty ?? false) {
      if (selectedIndexes.contains(index)) {
        setState(() => selectedIndexes.remove(index));
      } else {
        setState(() => selectedIndexes.add(index));
      }
      widget.onExpand(selectedIndexes.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.values.dapps?.length ?? 0,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        var item = widget.values.dapps?[index];
        if (item?.entries?.value?.text?.toLowerCase().contains("balance") ??
            false ||
                (item?.entries?.value?.linktext
                        ?.toLowerCase()
                        .contains("balance") ??
                    false) ||
                (item?.entries?.amount?.text
                        ?.toLowerCase()
                        .contains("balance") ??
                    false)) {
          if (selectedIndexes.isEmpty &&
              (item?.distribution?.isNotEmpty ?? false) &&
              _isFirstExpand) {
            selectedIndexes.add(index);
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              widget.onExpand(selectedIndexes.isNotEmpty);
            });
            _isFirstExpand = false;
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedIndexes.contains(index))
              Expanded(
                flex: 1,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (ctx, index) {
                    return DistributorWidget(
                      distributor: item!.distribution![index],
                      dapps: item,
                      values: widget.values,
                      total: widget.total,
                    );
                  },
                  itemCount: item?.distribution?.length ?? 0,
                ),
              ),
            if (!selectedIndexes.contains(index)) const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  _toggleExpand(item?.distribution, index);
                },
                child: Container(
                  margin: EdgeInsets.only(
                      bottom:
                          (widget.values.dapps?.isNotEmpty ?? false) ? 20 : 0),
                  padding: !selectedIndexes.contains(index)
                      ? null
                      : const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                  decoration: !selectedIndexes.contains(index)
                      ? null
                      : BoxDecoration(
                          color: ColorResources.themeDataBgColor(context),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: const [
                              BoxShadow(
                                color: ColorResources.dataBgColor,
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, -1),
                              ),
                            ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      //? Value builder
                      if (item?.entries?.value != null &&
                          item?.entries?.value?.value != null)
                        ValueBuilder(
                          value: item!.entries!.value!,
                          isAlgo: widget.isAlgo,
                          priceusdc: widget.total.priceusdc ?? 1,
                        ),
                      //? Link with beta
                      ...item?.entries?.links?.map((e) {
                            return Tooltip(
                              message: e.title,
                              child: GestureDetector(
                                onTap: () {
                                  launchURLApp(e.link ?? "");
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 4),
                                    RichText(
                                      textAlign: TextAlign.end,
                                      text: TextSpan(
                                        text: "${e.small ?? ""}  ",
                                        style: TextStyle(
                                          color: ColorResources.themeTextColor(
                                              context),
                                          fontSize:
                                              Dimensions.FONT_SIZE_SMALL_8,
                                          fontWeight: FontWeight.w300,
                                          fontFamily:
                                              AppConstants.FONT_FAMILY_OUTFIT,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: (e.linktext ?? ""),
                                            style: const TextStyle(
                                              color:
                                                  ColorResources.primaryColor,
                                              fontSize:
                                                  Dimensions.FONT_SIZE_SMALL,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppConstants
                                                  .FONT_FAMILY_OUTFIT,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList() ??
                          [],
                      //? Amount builder
                      if (item?.entries?.amount != null &&
                          item!.entries!.amount?.unit != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AmountBuilder(
                            amount: item.entries!.amount!,
                            decimal: widget.values.asa?.decimals ?? 1,
                          ),
                        ),

                      //? price builder
                      if (item?.entries?.price?.unit != null &&
                          item?.entries?.price?.price != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () {
                              // _isPriceChanged = !_isPriceChanged;
                              if (selectedDapPriceIndex.contains(index)) {
                                selectedDapPriceIndex.remove(index);
                              } else {
                                selectedDapPriceIndex.add(index);
                              }
                              setState(() {});
                            },
                            child: Text(
                              '${(!selectedDapPriceIndex.contains(index) ? (item?.entries?.price?.price ?? 0.0) : (((item?.entries?.amount?.amount ?? 0.0) / (item?.entries?.value?.value ?? 1)) / math.pow(10, widget.values.asa?.decimals ?? 0))).toStringAsFixed(8)}  ${selectedDapPriceIndex.contains(index) ? (item?.entries?.price?.unit ?? "").split("/").length > 1 ? (item?.entries?.price?.unit ?? "").split("/")[1] + "/" + (item?.entries?.price?.unit ?? "").split("/")[0] : (item?.entries?.price?.unit ?? "") : (item?.entries?.price?.unit ?? "")}', //TODO Refactor
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: selectedDapPriceIndex.contains(index)
                                    ? ColorResources.primaryColor
                                    : ColorResources.themeTextColor(context),
                                fontSize: Dimensions.FONT_SIZE_SMALL,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DistributorWidget extends StatefulWidget {
  final Distribution distributor;
  final Dapps dapps;
  final Total total;
  final Values values;

  const DistributorWidget({
    Key? key,
    required this.distributor,
    required this.dapps,
    required this.total,
    required this.values,
  }) : super(key: key);

  @override
  State<DistributorWidget> createState() => _DistributorWidgetState();
}

class _DistributorWidgetState extends State<DistributorWidget> {
  List<int> selectedDapPriceIndex = [];
  List<int> selectedDapIndex = [];

  late Distribution distributor;
  late Dapps dapps;

  @override
  void initState() {
    distributor = widget.distributor;
    dapps = widget.dapps;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: distributor.text ?? "",
              style: const TextStyle(
                color: ColorResources.primaryColor,
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchURLApp(distributor.link ?? "");
                },
              children: [
                TextSpan(
                  text:
                      "  ${((distributor.value ?? 1) / (Provider.of<AppSettingProvider>(context).currency == Currency.algo ? 1 : widget.total.priceusdc ?? 1)).toStringAsFixed(2)} ${Provider.of<AppSettingProvider>(context).currency == Currency.algo ? "ALGO" : "USD"}",
                  style: TextStyle(
                    color: ColorResources.themeTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            "${AppConstants.formateNumber(distributor.amount ?? 0, points: "000000")} ${widget.values.asa?.unit ?? ""}",
            style: TextStyle(
              color: ColorResources.themeTextColor(context),
              fontSize: Dimensions.FONT_SIZE_SMALL,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
            ),
          ),
          SizedBox(height: 7.h),
          GestureDetector(
            onTap: convertPrice,
            child: Text(
              pricePerUnit(), // reverse unit on click
              style: TextStyle(
                color: isPriceConverted(distributor)
                    ? ColorResources.primaryColor
                    : ColorResources.themeTextColor(context),
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void convertPrice() {
    if (isPriceConverted(distributor)) {
      selectedDapIndex.remove((dapps.distribution
              ?.indexWhere((element) => element.amount == distributor.amount) ??
          0));
    } else {
      selectedDapIndex.add((dapps.distribution
              ?.indexWhere((element) => element.amount == distributor.amount) ??
          0));
    }
    setState(() {});
  }

  bool isPriceConverted(Distribution distributor) {
    return (selectedDapIndex.contains((dapps.distribution
            ?.indexWhere((element) => element.amount == distributor.amount) ??
        0)));
  }

  String pricePerUnit() {
    final rawUnit = dapps.entries?.price?.unit ?? dapps.entries?.amount?.unit;
    String amount = AppConstants.formateNumber(
        !isPriceConverted(distributor)
            ? (distributor.price ?? 0.0)
            : (1 / (distributor.price ?? 1)),
        // : (((dapps.entries?.amount?.amount ?? 0.0) /
        //         (dapps.entries?.value?.value ?? 1)) /
        //     math.pow(10, widget.values.asa?.decimals ?? 0)),
        points: "00000000");

    String unit = rawUnit != null
        ? isPriceConverted(distributor)
            ? rawUnit.split("/").length > 1
                ? rawUnit.split("/")[1] + "/" + rawUnit.split("/")[0]
                : rawUnit +
                    "/" +
                    Provider.of<AppSettingProvider>(context)
                        .currency
                        .name
                        .toUpperCase()
            : rawUnit.split("/").length > 1
                ? rawUnit
                : Provider.of<AppSettingProvider>(context)
                        .currency
                        .name
                        .toUpperCase() +
                    "/" +
                    rawUnit
        : "";

    return "$amount $unit";
  }
}
