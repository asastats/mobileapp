// Phase 5c-5 — V2 NFTListTile.
//
// Renders one expandable NFT collection row. Consumes
// ``v2.NftCollection`` directly. The v1 ``NFTListTile`` in
// ``nft_list_tile.dart`` stays in place because ``show_all_screen``
// still consumes it; this widget lives alongside it.
//
// Field-by-field, the v2 source for what each rendered piece of the
// row was:
//   - collection title: ``v2.NftCollection.{name, amount}``
//   - collection value: ``v2.NftCollection.value`` (ALGO)
//   - per-NFT data: ``v2.NftItem.nft`` (``v2.Nft``)
//     - image / thumbnail paths: ``Nft.image`` / ``Nft.thumbnail``
//       (was v1 ``Nft.path`` / ``Nft.tpath``)
//     - listings, last/max purchase, floor: all on Nft.*
//     - urls / traits: lists of typed objects, NOT v1's flat dicts
//     - description, name, rarity, unit, total: same names as v1
// Differences from v1:
//   - ``v1.Nft.hash`` had no equivalent in v2; CachedNetworkImage's
//     cacheKey falls back to deriving the key from the URL itself,
//     which has slightly looser cross-NFT deduping but is functionally
//     correct.
//   - ``v1.Listed.text`` / ``v1.Transaction.text`` map to
//     ``NftListing.market?.name`` / ``NftPurchase.market?.name``.
//   - Floor in v2 is a list; we take ``floor.first`` to match the v1
//     single-Transaction shape the widget expects.

import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:asa_stats/models/v2/v2.dart' as v2;
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:asa_stats/utility/list_builder.dart';
import 'package:asa_stats/widgets/error_image.dart';
import 'package:asa_stats/widgets/home/attribute.dart';
import 'package:asa_stats/widgets/home/copt_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum NftTransType { Last, Max, Floor }

class NFTListTileV2 extends StatefulWidget {
  final v2.NftCollection collection;
  final v2.Total? total;
  final Color borderColor;
  final bool isExpanded;
  final Function(bool visible) onVisibilityChange;

  const NFTListTileV2({
    super.key,
    required this.collection,
    required this.total,
    required this.borderColor,
    required this.isExpanded,
    required this.onVisibilityChange,
  });

  @override
  State<NFTListTileV2> createState() => _NFTListTileV2State();
}

class _NFTListTileV2State extends State<NFTListTileV2> {
  @override
  Widget build(BuildContext context) {
    final items = widget.collection.nfts;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final item = items[i];
          return VisibilityDetector(
            key: ValueKey(
                '$runtimeType ${widget.collection.name} ${item.nft?.id ?? i}'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction <= info.visibleBounds.top) {
                widget.onVisibilityChange(info.visibleFraction != 0);
              }
            },
            child: _nftCard(
              context,
              item: item,
              hasNext: i + 1 != items.length,
            ),
          );
        },
        childCount: widget.isExpanded ? items.length : 0,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _nftCard(BuildContext context,
      {required v2.NftItem item, bool hasNext = false}) {
    final nft = item.nft;
    if (nft == null) return const SizedBox.shrink();

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
                    child: CachedNetworkImage(
                      // No ``hash`` field on v2.Nft. CachedNetworkImage
                      // derives its own cache key from the URL when
                      // none is supplied — slightly looser dedup but
                      // functionally equivalent.
                      imageUrl: AppConstants.getNFTImage(nft.image ?? ''),
                      height: 156,
                      width: 156,
                      fit: BoxFit.fill,
                      progressIndicatorBuilder: (_, __, ___) =>
                          const CupertinoActivityIndicator(),
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
                        children: _rightColumn(item, nft),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _identityRow(item, nft),
              SizedBox(height: 10.h),
              ..._urlRows(nft),
              if (nft.description != null && nft.description!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Attribute(
                      label: 'Description', value: nft.description),
                ),
              ..._traitRows(nft),
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

  // # Right-column rows --------------------------------------------------

  List<Widget> _rightColumn(v2.NftItem item, v2.Nft nft) {
    final rows = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'BETA',
            style: TextStyle(
              color: ColorResources.themeTextColor(context),
              fontSize: Dimensions.FONT_SIZE_SMALL_8,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
            ),
          ),
          _label('Estimated Value: '),
        ],
      ),
      _label(_priceLine(item.price ?? 0)),
      const SizedBox(height: 18),
    ];

    // Active listings — one row per listing with text+link.
    for (final listing in nft.listings) {
      if (listing.market?.name == null) continue;
      rows.add(_listingRow(listing));
    }

    if (nft.lastPurchase?.price != null) {
      rows.addAll([
        _transactionRow(NftTransType.Last, nft.lastPurchase!),
        const SizedBox(height: 4),
      ]);
    }
    if (nft.floor.isNotEmpty && nft.floor.first.price != null) {
      rows.addAll([
        _floorListingRow(nft.floor.first),
        const SizedBox(height: 4),
      ]);
    }
    // The v1 widget only renders the Max purchase if its price strictly
    // exceeds Last's — preserves that conditional verbatim.
    final maxPrice = nft.maxPurchase?.price;
    final lastPrice = nft.lastPurchase?.price;
    if (maxPrice != null && lastPrice != null && maxPrice > lastPrice) {
      rows.add(_transactionRow(NftTransType.Max, nft.maxPurchase!));
    }

    return rows;
  }

  // # Identity row (unit + amount/total + id link + name + rarity) -------

  Widget _identityRow(v2.NftItem item, v2.Nft nft) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: _value(
                  '${nft.unit} ${item.amount ?? 0}/${nft.total ?? 0}',
                  maxLine: 2,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: CopyText(
                  text: '${nft.id ?? ''}',
                  url: 'https://allo.info/asset/${nft.id ?? ''}',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerRight,
                child: _value(nft.name ?? '', maxLine: 2),
              ),
              Visibility(
                visible: (nft.rarity ?? '').isNotEmpty,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: _rarityValue('Rarity: ', nft.rarity),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // # URL / trait rows ---------------------------------------------------

  List<Widget> _urlRows(v2.Nft nft) {
    return listBuilder(
      itemCount: nft.urls.length,
      builder: (i) {
        final u = nft.urls[i];
        if (u.url == null) return Container();
        return Attribute(
          label: u.typ ?? '',
          value: u.url,
          color: ColorResources.primaryColor,
          type: TextType.link,
        );
      },
    );
  }

  List<Widget> _traitRows(v2.Nft nft) {
    return listBuilder(
      itemCount: nft.traits.length,
      builder: (i) {
        final t = nft.traits[i];
        return Attribute(label: t.name ?? '', value: t.value);
      },
    );
  }

  // # Listing / Transaction row builders --------------------------------

  Widget _listingRow(v2.NftListing listing) {
    final priceDisplay = _priceLine(listing.price ?? 0);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      alignment: WrapAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            maxLines: 2,
            textAlign: TextAlign.right,
            text: TextSpan(
              text: 'Listed at ',
              style: TextStyle(
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                color: ColorResources.themeTextColor(context),
              ),
              children: [
                TextSpan(
                  text: '${listing.market!.name}: ',
                  style: const TextStyle(
                    fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                    fontSize: Dimensions.FONT_SIZE_SMALL,
                    fontWeight: FontWeight.w600,
                    color: ColorResources.primaryColor,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await launchURLApp(listing.link ?? '');
                    },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _containerBox(priceDisplay),
        ),
      ],
    );
  }

  Widget _transactionRow(NftTransType type, v2.NftPurchase trans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _label(
            '${type.name} purchase: ${_priceLine(trans.price ?? 0)}'),
        const SizedBox(height: 4),
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            text: _timePassed(
                (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
                    (trans.epoch ?? 0)),
            style: TextStyle(
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              fontSize: Dimensions.FONT_SIZE_SMALL,
              fontWeight: FontWeight.w600,
              color: ColorResources.themeTextColor(context),
            ),
            children: [
              TextSpan(
                text: trans.market?.name ?? '',
                style: const TextStyle(
                  color: ColorResources.primaryColor,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchURLApp(trans.link ?? ''),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }

  /// Floor entries are ``NftListing`` (no epoch), not ``NftPurchase``,
  /// so they get their own row with a different label + no time-passed
  /// suffix. Matches the v1 widget's ``TransType.Floor`` branch.
  Widget _floorListingRow(v2.NftListing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _label('Floor price: ${_priceLine(listing.price ?? 0)}'),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: listing.market?.name ?? '',
            style: const TextStyle(
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              fontSize: Dimensions.FONT_SIZE_SMALL,
              fontWeight: FontWeight.w600,
              color: ColorResources.primaryColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchURLApp(listing.link ?? ''),
          ),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }

  // # Small widget helpers -----------------------------------------------

  /// Currency-aware price line. Used for estimated value, listing
  /// prices, and transaction prices. Converts the ALGO price to USD
  /// when the user has the USD toggle on, using ``total.priceusdc`` as
  /// the rate.
  String _priceLine(double priceAlgo) {
    final isAlgo = Provider.of<AppSettingProvider>(context).currency ==
        Currency.algo;
    final usdRate = widget.total?.priceusdc ?? 1;
    final display = isAlgo ? priceAlgo : (priceAlgo / usdRate);
    return '${display.toStringAsFixed(2)} ${Provider.of<AppSettingProvider>(context).currency.name.toUpperCase()}';
  }

  String _timePassed(int interval) {
    String prefix;
    if (interval < 91) {
      prefix = '$interval seconds';
    } else if (interval < 5460) {
      prefix = '${interval ~/ 60} minutes';
    } else if (interval < 133200) {
      prefix = '${interval ~/ 3600} hours';
    } else {
      prefix = '${interval ~/ 86400} days';
    }
    return '$prefix ago on ';
  }

  Widget _containerBox(String title) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: ColorResources.primaryColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ColorResources.whiteColor,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          fontSize: Dimensions.FONT_SIZE_SMALL_10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _label(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        fontSize: Dimensions.FONT_SIZE_SMALL,
        fontWeight: FontWeight.w600,
        color: ColorResources.themeTextColor(context),
      ),
    );
  }

  Widget _value(String value, {int maxLine = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        maxLines: maxLine,
        style: TextStyle(
          color: ColorResources.themeTextColor(context),
          fontSize: Dimensions.FONT_SIZE_SMALL,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
    );
  }

  Widget _rarityValue(String label, String? value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: ColorResources.themeTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: Dimensions.FONT_SIZE_SMALL,
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
            ),
          ),
          TextSpan(
            text: value ?? '',
            style: TextStyle(
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              fontSize: Dimensions.FONT_SIZE_SMALL,
              fontWeight: FontWeight.normal,
              color: Provider.of<ThemeProvider>(context).darkTheme
                  ? ColorResources.whiteColor
                  : const Color(0xffA8A7A7),
            ),
          ),
        ],
      ),
    );
  }
}

/// V2 NFT sticky header (mirrors ``nftStickyHeader`` in
/// ``nft_list_tile.dart``). Takes a ``v2.NftCollection`` and produces a
/// header row showing collection title + total value + a small NFT
/// image grid.
Widget nftStickyHeaderV2({
  required BuildContext context,
  required v2.NftCollection collection,
  required v2.Total? total,
  required Color borderColor,
  required AppSettingProvider appSettingProvider,
  required int crossAxisCount,
  required bool isExpanded,
  required int height,
  required Function() onTap,
}) {
  final title = '${AppConstants.removeDecimalZeroFormat(collection.amount ?? 0)} ${collection.name ?? ''}';
  final isAlgo = appSettingProvider.currency == Currency.algo;
  final priceusdc = total?.priceusdc ?? 1;
  final valueAlgo = collection.value ?? 0.0;
  final subTitle =
      (isAlgo ? valueAlgo : (valueAlgo / priceusdc)).toStringAsFixed(2);
  const miniSubTitle = 'BETA ';
  final images = collection.nfts
      .map<String>((it) => it.nft?.thumbnail ?? '')
      .toList(growable: false);

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
          ),
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
                      // Title row (left).
                      Positioned(
                        left: 0,
                        top: images.length > 3 ? 20 : 0,
                        bottom: images.length > 3 ? null : 0,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          width: _titleWidth(
                              context, images.length, crossAxisCount,
                              isExpanded: isExpanded),
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
                      // Subtitle + currency + expand/collapse arrow (right).
                      Positioned(
                        top: images.length > 3 ? 10 : 10,
                        bottom: images.length > 3 ? null : 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                alignment: Alignment.centerRight,
                                child: _subtitleAdaptive(
                                  context,
                                  miniSubTitle: miniSubTitle,
                                  subTitle: subTitle,
                                  appSettingProvider: appSettingProvider,
                                  isExpanded: isExpanded,
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
                      // Top-row image grid (center).
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
                                    return NFTHeaderImageV2(
                                      url: AppConstants.getNFTImage(
                                          images[index]),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Second-row image grid (visible only when collapsed and
                // there are more images than fit in one row).
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
                                crossAxisCount:
                                    (images.length > crossAxisCount)
                                        ? crossAxisCount
                                        : images.length,
                              ),
                              itemCount: (images.length > crossAxisCount)
                                  ? images.length - crossAxisCount
                                  : 0,
                              shrinkWrap: true,
                              itemBuilder: (_, index) {
                                final actualIndex =
                                    images.length > crossAxisCount
                                        ? index + crossAxisCount
                                        : index;
                                return NFTHeaderImageV2(
                                  url: AppConstants.getNFTImage(
                                      images[actualIndex]),
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

/// Title-column width calculation lifted verbatim from the v1 sticky
/// header. Extracted as a helper purely to keep the build tree
/// readable; the math is identical.
double? _titleWidth(
  BuildContext context,
  int imageCount,
  int crossAxisCount, {
  required bool isExpanded,
}) {
  if (isExpanded) return null;
  final halfScreen = MediaQuery.of(context).size.width / 2;
  final padAndLeading = Dimensions.PADDING_SIZE_SMALL.w +
      Dimensions.PADDING_SIZE_DEFAULT +
      23; // 23 = leading-icon spacer in original
  if ((imageCount / crossAxisCount) >= 1) {
    return halfScreen - padAndLeading - ((crossAxisCount / 2) * 39);
  }
  return halfScreen - padAndLeading - ((imageCount / 2) * 39);
}

/// Subtitle layout that adapts between portrait (Column) and landscape
/// (Row) orientations. Mirrors the v1 widget's inline Builder/Row/Column
/// conditional.
Widget _subtitleAdaptive(
  BuildContext context, {
  required String miniSubTitle,
  required String subTitle,
  required AppSettingProvider appSettingProvider,
  required bool isExpanded,
}) {
  final isLandscape =
      MediaQuery.of(context).orientation == Orientation.landscape;
  final richSpans = TextSpan(
    children: [
      TextSpan(
        text: miniSubTitle,
        style: TextStyle(
          color: isExpanded
              ? ColorResources.whiteColor
              : ColorResources.themeLightGrayWhiteColor(context),
          fontSize: Dimensions.FONT_SIZE_SMALL_8,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
      TextSpan(
        text: subTitle,
        style: TextStyle(
          color: isExpanded
              ? ColorResources.whiteColor
              : ColorResources.themeLightGrayWhiteColor(context),
          fontSize: Dimensions.FONT_SIZE_DEFAULT,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
    ],
  );
  final currencyText = Text(
    appSettingProvider.currency.name.toUpperCase(),
    textAlign: TextAlign.right,
    style: TextStyle(
      color: isExpanded
          ? ColorResources.whiteColor
          : ColorResources.themeLightGrayWhiteColor(context),
      fontSize: Dimensions.FONT_SIZE_DEFAULT,
      fontWeight: FontWeight.w700,
      fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
    ),
  );
  if (isLandscape) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        RichText(textAlign: TextAlign.right, text: richSpans),
        const SizedBox(width: 3),
        currencyText,
      ],
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      RichText(textAlign: TextAlign.right, text: richSpans),
      currencyText,
    ],
  );
}

/// Single thumbnail cell in the sticky-header image grid. V2 version
/// drops the ``hash`` cacheKey (no v2 field); CachedNetworkImage
/// derives its own key from the URL.
class NFTHeaderImageV2 extends StatelessWidget {
  final String url;
  const NFTHeaderImageV2({super.key, required this.url});

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
          fit: BoxFit.contain,
          errorWidget: (context, o, s) =>
              const ErrorImage(height: 35, width: 35),
          progressIndicatorBuilder: (_, __, ___) =>
              const CupertinoActivityIndicator(),
        ),
      ),
    );
  }
}
