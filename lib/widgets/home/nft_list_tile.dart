import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:asa_stats/models/response/asa_model.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../config/images.dart';
import '../../models/response/nftValues.dart';
import '../../models/response/transaction.dart';
import '../../providers/app_setting_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utility/list_builder.dart';
import '../error_image.dart';
import 'attribute.dart';
import 'copt_text.dart';

enum TransType { Last, Max, Floor }

class NFTListTile extends StatefulWidget {
  final String title;
  final String subTitle;
  final List<String> images;
  final Color borderColor;
  final NftValues? nftValues;
  final ASAModel? model;
  final bool isExpanded;
  final Function(bool visible) onVisibilityChange;

  const NFTListTile({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.images,
    required this.nftValues,
    required this.model,
    required this.borderColor,
    required this.isExpanded,
    required this.onVisibilityChange,
  }) : super(key: key);

  @override
  State<NFTListTile> createState() => _NFTListTileState();
}

class _NFTListTileState extends State<NFTListTile> {
  @override
  void initState() {
    super.initState();
  }

  bool firstVisible = false;
  bool lastVisible = false;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          return VisibilityDetector(
            key: ValueKey("$runtimeType ${widget.title}"),
            onVisibilityChanged: (info) {
              if (info.visibleFraction <= info.visibleBounds.top) {
                widget.onVisibilityChange(info.visibleFraction != 0);
              }
            },
            child: nft(
              context,
              nft: widget.nftValues?.nfts?[i] ?? Nfts(),
              hasNext: widget.nftValues?.nfts?.length != i + 1,
            ),
          );
          // : nft(
          //     context,
          //     nft: widget.nftValues?.nfts?[i] ?? Nfts(),
          //     hasNext: widget.nftValues?.nfts?.length != i + 1,
          //   );
        },
        childCount:
            widget.isExpanded ? (widget.nftValues?.nfts?.length ?? 0) : 0,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget nft(BuildContext context, {required Nfts nft, bool hasNext = false}) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 7, bottom: 15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Provider.of<ASAProvider>(context, listen: false)
                            .imageProviders[nft.nft?.path ?? ""] ??
                        CachedNetworkImage(
                          // cacheKey: nft.nft?.path ?? "",
                          imageUrl:
                              AppConstants.getNFTImage(nft.nft?.path ?? ""),
                          height: 156,
                          width: 156,
                          fit: BoxFit.fill,
                          progressIndicatorBuilder: (_, __, ___) {
                            return const CupertinoActivityIndicator();
                          },
                          errorWidget: (context, o, s) =>
                              const ErrorImage(height: 156, width: 156),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.PADDING_SIZE_SMALL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (nft.nft?.listed?.text != null)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              alignment: WrapAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: RichText(
                                    maxLines: 2,
                                    textAlign: TextAlign.right,
                                    text: TextSpan(
                                      text: "Listed at ",
                                      style: TextStyle(
                                        fontFamily:
                                            AppConstants.FONT_FAMILY_OUTFIT,
                                        fontSize: Dimensions.FONT_SIZE_SMALL,
                                        fontWeight: FontWeight.w600,
                                        color: ColorResources.themeTextColor(
                                            context),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "${nft.nft?.listed?.text}: ",
                                          style: const TextStyle(
                                            fontFamily:
                                                AppConstants.FONT_FAMILY_OUTFIT,
                                            fontSize:
                                                Dimensions.FONT_SIZE_SMALL,
                                            fontWeight: FontWeight.w600,
                                            color: ColorResources.primaryColor,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () async {
                                              await launchURLApp(
                                                  nft.nft?.listed?.link ?? "");
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: containerBox(
                                      (Provider.of<AppSettingProvider>(context)
                                                          .currency !=
                                                      Currency.algo
                                                  ? ((nft.nft?.listed?.price ??
                                                          0) /
                                                      (widget.model?.total
                                                              ?.priceusdc ??
                                                          1))
                                                  : nft.nft?.listed?.price ?? 0)
                                              .toStringAsFixed(2) +
                                          " " +
                                          Provider.of<AppSettingProvider>(
                                                  context)
                                              .currency
                                              .name
                                              .toUpperCase()),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          if (nft.nft?.last?.price != null) ...[
                            transaction(
                              type: TransType.Last,
                              trans: nft.nft!.last!,
                            ), // global variable for Algo
                            const SizedBox(height: 4),
                          ],
                          if (nft.nft?.floor?.price != null) ...[
                            transaction(
                              type: TransType.Floor,
                              trans: nft.nft!.floor!,
                            ), // global variable for Algo
                            const SizedBox(height: 4),
                          ],
                          if (nft.nft?.max?.price != null)
                            if (((nft.nft?.max?.price ?? 0) >
                                (nft.nft?.last?.price ?? 0)))
                              transaction(
                                type: TransType.Max,
                                trans: nft.nft!.max!,
                              ), // global variable for Algo
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: value(
                        "${nft.nft?.unit} ${nft.amount ?? 0}/${nft.nft?.total ?? 0}",
                        maxLine: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: value(
                        nft.nft?.name ?? "",
                        maxLine: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: CopyText(text: "${nft.id ?? ""}"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ...listBuilder(
                itemCount: nft.nft?.urls?.toJson().length ?? 0,
                builder: (i) {
                  var key = nft.nft?.urls?.toJson().keys.toList()[i];
                  var value = nft.nft?.urls?.toJson()[key];

                  return value == null
                      ? Container()
                      : Attribute(
                          label: "$key",
                          value: "$value",
                          color: ColorResources.primaryColor,
                          type: TextType.link,
                        );
                },
              ),
              if (nft.nft?.desc != null && (nft.nft?.desc?.isNotEmpty ?? false))
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Attribute(
                    label: "Description",
                    value: nft.nft?.desc,
                  ),
                ),
              ...listBuilder(
                itemCount: nft.nft?.attrs?.length ?? 0,
                builder: (i) {
                  var key = nft.nft?.attrs?.keys.toList()[i];
                  var value = nft.nft?.attrs?[key];
                  return Attribute(
                    label: "$key",
                    value: "$value",
                  );
                },
              ),
              if (hasNext)
                Container(
                  height: 1.h,
                  margin: EdgeInsets.symmetric(vertical: 21.h),
                  width: double.maxFinite,
                  color: ColorResources.borderColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget containerBox(String title) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: ColorResources.primaryColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ColorResources.whiteColor,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          fontSize: Dimensions.FONT_SIZE_SMALL_10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget label(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          fontSize: Dimensions.FONT_SIZE_SMALL,
          fontWeight: FontWeight.w600,
          color: ColorResources.themeTextColor(context)),
    );
  }

  Widget value(
    String value, {
    Color? color,
    int maxLine = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        value, //address
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        maxLines: maxLine,
        style: TextStyle(
          color: color ?? ColorResources.themeTextColor(context),
          fontSize: Dimensions.FONT_SIZE_SMALL,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
    );
  }

  Widget transaction({required TransType type, required Transaction trans}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        label(
            "${type.name} ${type == TransType.Floor ? "price" : "purchase"}: " +
                (Provider.of<AppSettingProvider>(context).currency !=
                            Currency.algo
                        ? ((trans.price ?? 0) /
                            (widget.model?.total?.priceusdc ?? 1))
                        : trans.price ?? 0)
                    .toStringAsFixed(2) +
                " " +
                Provider.of<AppSettingProvider>(context)
                    .currency
                    .name
                    .toUpperCase()),
        if (type != TransType.Floor) ...[
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              text: timePassed((DateTime.now().millisecondsSinceEpoch ~/ 1000) -
                  (trans.epoch ?? 0)),
              style: TextStyle(
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                color: ColorResources.themeTextColor(context),
              ),
              children: [
                TextSpan(
                    text: trans.text ?? "",
                    style: const TextStyle(
                      color: ColorResources.primaryColor,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchURLApp(trans.link ?? ""))
              ],
            ),
          ),
        ],
        SizedBox(height: 4.h),
      ],
    );
  }

  String timePassed(int interval) {
    String prefix;
    if (interval < 91) {
      prefix = (interval).toString() + " seconds";
    } else if (interval < 5460) {
      prefix = (interval ~/ 60).toString() + " minutes";
    } else if (interval < 133200) {
      prefix = (interval ~/ 3600).toString() + " hours";
    } else {
      prefix = (interval ~/ 86400).toString() + " days";
    }
    return prefix + " ago on ";
  }
}

Widget nftStickyHeader(
    {required BuildContext context,
    required String title,
    required String subTitle,
    required List<String> images,
    required Color borderColor,
    required int crossAxisCount,
    required bool isExpanded,
    required Function() onTap,
    required int height}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: height.toDouble(),
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
      decoration: BoxDecoration(
        color: isExpanded
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
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: double.maxFinite,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
                bottomLeft: Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 0,
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          alignment: Alignment.topCenter,
                          width: (images.length > crossAxisCount
                                  ? (crossAxisCount * 39)
                                  : (images.length * 39)) +
                              4,
                          height: 39,
                          margin: const EdgeInsets.only(top: 6, bottom: 5),
                          child: images.isEmpty
                              ? null
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: images.length > crossAxisCount
                                      ? crossAxisCount
                                      : images.length,
                                  itemBuilder: (_, index) {
                                    return NFTHeaderImage(
                                        url: AppConstants.getNFTImage(
                                            images[index]));
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: images.length > 3 ? 20 : 0,
                        bottom: images.length > 3 ? null : 0,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          width: !isExpanded
                              ? (images.length / crossAxisCount) >= 1
                                  ? (MediaQuery.of(context).size.width /
                                          2) - // half screen size minus other spaces
                                      (Dimensions
                                              .PADDING_SIZE_SMALL.w + // Padding
                                          Dimensions
                                              .PADDING_SIZE_DEFAULT + // Padding
                                          23) - // Leading space
                                      ((crossAxisCount / 2) * 39) // NFT space
                                  : (MediaQuery.of(context).size.width /
                                          2) - // half screen size minus other spaces
                                      (Dimensions
                                              .PADDING_SIZE_SMALL.w + // Padding
                                          Dimensions
                                              .PADDING_SIZE_DEFAULT + // Padding
                                          23) - // Leading space
                                      ((images.length / 2) * 39)
                              : null,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: (images.length / crossAxisCount) > 0
                                ? ((images.length / crossAxisCount).ceil() + 1)
                                : 1,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              backgroundColor: isExpanded
                                  ? ColorResources.primaryColor
                                  : Provider.of<ThemeProvider>(context)
                                          .darkTheme
                                      ? const Color(0xff373737)
                                      : ColorResources.whiteColor,
                              color: isExpanded
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
                        top: images.length > 3 ? 20 : 0,
                        bottom: images.length > 3 ? null : 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  subTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isExpanded
                                        ? ColorResources.whiteColor
                                        : ColorResources
                                            .themeLightGrayWhiteColor(context),
                                    fontSize: Dimensions.FONT_SIZE_SMALL_8,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 17),
                                child: Image.asset(
                                  isExpanded
                                      ? Images.IC_ARROW_UP
                                      : Images.IC_DROP_DOWN,
                                  height: 5,
                                  width: 10,
                                  color: isExpanded
                                      ? ColorResources.whiteColor
                                      : ColorResources.themeTextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: !isExpanded,
                  child: (images.isEmpty)
                      ? const SizedBox(height: 0)
                      : Container(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: (images.length > crossAxisCount)
                                ? (crossAxisCount * 39) + 4
                                : (images.length * 39) + 4,
                            alignment: Alignment.topCenter,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: (images.length > crossAxisCount)
                                    ? crossAxisCount
                                    : images.length,
                              ),
                              itemCount: (images.length > crossAxisCount)
                                  ? images.length - crossAxisCount
                                  : 0,
                              shrinkWrap: true,
                              itemBuilder: (_, index) {
                                return NFTHeaderImage(
                                  url: AppConstants.getNFTImage(images[
                                      (images.length > crossAxisCount)
                                          ? (index + crossAxisCount)
                                          : index]),
                                );
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

class NFTHeaderImage extends StatelessWidget {
  final String url;
  const NFTHeaderImage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 35,
          width: 35,
          fit: BoxFit.fill,
          errorWidget: (context, o, s) =>
              const ErrorImage(height: 35, width: 35),
          progressIndicatorBuilder: (_, __, ___) {
            return const CupertinoActivityIndicator();
          },
        ),
      ),
    );
  }
}
