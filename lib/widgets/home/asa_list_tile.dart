import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/extensions.dart';
import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:asa_stats/models/response/asa_model.dart';
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:asa_stats/utility/list_builder.dart';
import 'package:asa_stats/widgets/error_image.dart';
import 'package:asa_stats/widgets/home/copt_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../config/app_constants.dart';
import '../../models/response/links.dart';
import '../../models/response/total.dart';
import '../../models/response/values.dart';
import '../../utility/utils.dart';
import 'asa_data.dart';
import 'attribute.dart';

class ASAListTile extends StatefulWidget {
  final String title;
  final bool? isAlgo;
  final Color? borderColor;
  final Values? values;
  final ASAModel? model;
  final bool showBorder;
  final bool isExpanded;
  final bool showProviders;
  final Function(bool visible) onVisibilityChange;
  const ASAListTile({
    Key? key,
    required this.title,
    required this.values,
    required this.isAlgo,
    required this.model,
    this.showBorder = true,
    this.borderColor,
    required this.isExpanded,
    this.showProviders = true,
    required this.onVisibilityChange,
  }) : super(key: key);

  @override
  State<ASAListTile> createState() => _ASAListTile();
}

class _ASAListTile extends State<ASAListTile> {
  bool _isFirstRowExpanded = false;

  List providerImage = [
    Images.ALGO_CHARTS,
    Images.ALGO_EXPLORER,
    Images.ALGORAND_STATS,
    Images.ANS,
    Images.COIN_MARKET_CAT,
    Images.LIVE_COIN_WATCH,
    Images.LOFTY_AI,
    Images.NFD,
    Images.TINY_CHART,
    Images.VESTIGE
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _sliverList();
  }

  Widget _sliverList() {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (widget.isExpanded)
          VisibilityDetector(
            key: ValueKey("$runtimeType ${widget.values?.id}"),
            onVisibilityChanged: (info) {
              if (info.visibleFraction <= info.visibleBounds.top) {
                widget.onVisibilityChange(info.visibleFraction != 0);
              }
            },
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 7, bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Visibility(
                            visible: !_isFirstRowExpanded,
                            child: Expanded(
                              flex: 1,
                              child: asaInfo(),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: ASAData(
                              values: (widget.values ?? Values()),
                              isAlgo: widget.isAlgo ?? false,
                              total: widget.model?.total ?? Total(),
                              onExpand: (isExpand) {
                                _isFirstRowExpanded = isExpand;
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),

                      if (widget.showProviders && _isFirstRowExpanded)
                        divider(), // for not evaluate
                      Visibility(
                        visible: _isFirstRowExpanded,
                        child: asaInfo(),
                      ),
                      if (widget.showProviders) // for not evaluate
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.values?.asa?.links?.isNotEmpty ??
                                false) ...[
                              const SizedBox(height: 6),
                              providers(),
                            ]
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget asaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title, //name
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ColorResources.themeLightGrayWhiteColor(context),
            fontSize: Dimensions.FONT_SIZE_LARGE,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () {
            launchURLApp(
              widget.values?.asa?.url ?? "",
            );
          },
          child: CopyText(
            text: widget.values?.id.toString() ?? "",
            url: 'https://allo.info/asset/${widget.values?.id.toString()}',
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.showProviders) // only show for noteval
          Attribute(
            label: "Amount",
            value: widget.values?.amount != null
                ? AppConstants.formateNumber(
                    double.parse(
                      formateAmount(widget.values!.amount!,
                          widget.values!.asa?.decimals ?? 0, 6),
                    ),
                    points: "0000")
                : 'Unknown amount',
          ),
        Attribute(
          label: "Unit name",
          value: widget.values?.asa?.unit ?? "",
        ),
        Attribute(
          label: "Total supply",
          value: NumberFormat('#,##0.0000')
              .format(double.parse(widget.values?.asa?.total ?? ""))
              .replaceAll(RegExp(r'.000*$'), ''),
        ),
        Attribute(
          label: "Decimals",
          value: widget.values?.asa?.decimals.toString() ?? "",
        ),
        if (widget.showProviders) // don't show for noteval
          PricePerUnit(
            values: widget.values,
            usdValue: widget.model?.total?.priceusdc ?? 1,
          ),
        Attribute(
          label: "URL",
          value: widget.values?.asa?.url.toString(),
          type: TextType.link,
          color: ColorResources.primaryColor,
        ),

        ///
        /// Balance
        ///
        // Attribute(
        //   label: "Balance",
        //   value: AppConstants.formateNumber(widget.values?.amount ?? 0.0)
        //       .toString(),
        // ),
      ],
    );
  }

  Widget providers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: listBuilder(
          itemCount: widget.values?.asa?.links?.length ?? 0,
          builder: (index) {
            Links e = widget.values!.asa!.links![index];
            return Padding(
              padding: const EdgeInsets.only(
                  left: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              child: GestureDetector(
                onTap: () {
                  launchURLApp(e.link ?? "");
                },
                child: Tooltip(
                  message: e.provider,
                  child: Image.network(
                    AppConstants.getProviderImage("${e.provider}"),
                    // "${Images.PROVIDER}${providerImage.getString("${e.provider}.png")}",
                    height: 25,
                    width: 25,
                    errorBuilder: (_, __, ___) {
                      return const ErrorImage(height: 25, width: 25);
                    },
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget value(
    String value, [
    Color? color,
  ]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Text(
        value, //address
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? ColorResources.themeTextColor(context),
          fontSize: Dimensions.FONT_SIZE_SMALL,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
    );
  }

  Widget divider() {
    return Container(
      height: 1.h,
      margin: EdgeInsets.symmetric(vertical: 21.h),
      width: double.maxFinite,
      color: ColorResources.borderColor,
    );
  }
}

class PricePerUnit extends StatefulWidget {
  final Values? values;
  final double usdValue;
  const PricePerUnit({
    Key? key,
    required this.values,
    required this.usdValue,
  }) : super(key: key);

  @override
  State<PricePerUnit> createState() => _PricePerUnitState();
}

class _PricePerUnitState extends State<PricePerUnit> {
  bool _isPriceConverted = false;

  void _convertPrice() {
    setState(() {
      _isPriceConverted = !_isPriceConverted;
    });
  }

  String getPrice() {
    double price =
        Provider.of<AppSettingProvider>(context).currency == Currency.algo
            ? (widget.values?.price ?? 1)
            : (widget.values?.price ?? 1) / widget.usdValue;

    if (_isPriceConverted) price = 1 / price;

    String unit = (_isPriceConverted ? "${widget.values?.asa?.unit}/" : "") +
        (Provider.of<AppSettingProvider>(context).currency == Currency.algo
            ? "ALGO"
            : "USD");
    return "${AppConstants.formateNumber(price, points: "000000")} $unit";
  }

  @override
  Widget build(BuildContext context) {
    return Attribute(
      label: "Price per unit",
      value: getPrice(),
      color: _isPriceConverted
          ? ColorResources.primaryColor
          : (Provider.of<ThemeProvider>(context).darkTheme
              ? ColorResources.whiteColor
              : const Color(0xffA8A7A7)),
      onValueTap: _convertPrice,
    );
  }
}

Widget getStickyHeader({
  required String asaId,
  required Values data,
  required BuildContext context,
  required Color color,
  required AppSettingProvider appSettingProvider,
  required ASAModel asaData,
  required double tailWidth,
  required Function() onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
      decoration: BoxDecoration(
        color: (asaId == data.asa?.id.toString())
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
          Container(
            width: 5,
            height: double.maxFinite,
            decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(
                    Dimensions.RADIUS_SIZE_DEFAULT,
                  ),
                  bottomLeft: Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "${AppConstants.formateNumber(double.parse(
                            formateAmount(
                                data.amount ?? 0, data.asa?.decimals ?? 0, 6,
                                utit: data.asa?.unit),
                          ), points: "0000")}  ${data.asa?.unit ?? ""}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        backgroundColor: (asaId == data.asa?.id.toString())
                            ? ColorResources.primaryColor
                            : Provider.of<ThemeProvider>(context).darkTheme
                                ? const Color(0xff373737)
                                : ColorResources.whiteColor,
                        color: (asaId == data.asa?.id.toString())
                            ? ColorResources.whiteColor
                            : ColorResources.themeTextColor(context),
                        fontSize: Dimensions.FONT_SIZE_DEFAULT,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.centerRight,
                        child: Text(
                          (appSettingProvider.currency == Currency.algo
                                      ? (data.value ?? 0.0)
                                      : ((data.value ?? 0) /
                                          (asaData.total?.priceusdc ?? 1)))
                                  .toStringAsFixed(2) +
                              " " +
                              appSettingProvider.currency.name.toUpperCase(),
                          // overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            backgroundColor: (asaId == data.asa?.id.toString())
                                ? ColorResources.primaryColor
                                : Provider.of<ThemeProvider>(context).darkTheme
                                    ? const Color(0xff373737)
                                    : ColorResources.whiteColor,
                            color: (asaId == data.asa?.id.toString())
                                ? ColorResources.whiteColor
                                : ColorResources.themeLightGrayWhiteColor(
                                    context),
                            fontSize: Dimensions.FONT_SIZE_DEFAULT,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 17),
                        child: Image.asset(
                          (asaId == data.asa?.id.toString())
                              ? Images.IC_ARROW_UP
                              : Images.IC_DROP_DOWN,
                          height: 5,
                          width: 10,
                          color: (asaId == data.asa?.id.toString())
                              ? ColorResources.whiteColor
                              : ColorResources.themeTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.PADDING_SIZE_SMALL),
                      child: CachedNetworkImage(
                        imageUrl: AppConstants.getAsaImage(data.id.toString()),
                        height: 35,
                        width: 35,
                        errorWidget: (_, __, ___) {
                          return const ErrorImage(height: 35, width: 35);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
