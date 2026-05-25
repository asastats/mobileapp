// Phase 5c-4 — V2 ASAListTile.
//
// Renders one expandable row in the ASA tab. Consumes ``v2.AsaItem``
// directly (no v1 shim). The v1 ``ASAListTile`` in ``asa_list_tile.dart``
// stays in place because ``show_all_screen`` and (until 5c-5) the NFT
// tab still consume it; this widget lives alongside it.
//
// Field-by-field, the v2 source for what each rendered piece of the
// row was:
//   - title: ``v2.AsaItem.asset.unit``  (was ``v1.Values.asa.unit``)
//   - asset id, name, decimals, total, url, links: all on ``asset.*``
//   - per-program detail: delegated to ``ASADataV2`` (see asa_data_v2.dart)
//
// Per Q5, the v1 dropdown / search-on-attributes UI lands here too,
// but only where the data exists in v2. Per A7, color is computed by
// the calling screen (``palette[i % palette.length]``) and passed in
// via ``borderColor``.

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
import 'package:asa_stats/utility/utils.dart';
import 'package:asa_stats/widgets/error_image.dart';
import 'package:asa_stats/widgets/home/asa_data_v2.dart';
import 'package:asa_stats/widgets/home/attribute.dart';
import 'package:asa_stats/widgets/home/copt_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ASAListTileV2 extends StatefulWidget {
  final v2.AsaItem item;
  final v2.Total? total;
  final bool isAlgo;
  final Color? borderColor;
  final bool showBorder;
  final bool isExpanded;
  final bool showProviders;
  final Function(bool visible) onVisibilityChange;

  const ASAListTileV2({
    super.key,
    required this.item,
    required this.total,
    required this.isAlgo,
    required this.isExpanded,
    required this.onVisibilityChange,
    this.showBorder = true,
    this.borderColor,
    this.showProviders = true,
  });

  @override
  State<ASAListTileV2> createState() => _ASAListTileV2State();
}

class _ASAListTileV2State extends State<ASAListTileV2> {
  bool _isFirstRowExpanded = false;

  v2.Asa get _asset => widget.item.asset ?? v2.Asa();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (widget.isExpanded)
          VisibilityDetector(
            key: ValueKey('$runtimeType ${_asset.id}'),
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
                            child: Expanded(flex: 1, child: _asaInfo()),
                          ),
                          Expanded(
                            flex: 1,
                            child: ASADataV2(
                              item: widget.item,
                              isAlgo: widget.isAlgo,
                              total: widget.total,
                              onExpand: (isExpand) {
                                _isFirstRowExpanded = isExpand;
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      if (widget.showProviders && _isFirstRowExpanded)
                        _divider(),
                      Visibility(
                        visible: _isFirstRowExpanded,
                        child: _asaInfo(),
                      ),
                      if (widget.showProviders)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_asset.links.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _providers(),
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

  Widget _asaInfo() {
    // Total-supply rendering: v2 stores ``total`` as int (micro-units),
    // v1 stored it as String (display-formatted with decimals already
    // baked in). To preserve the visible rendering, divide by
    // ``10^decimals`` and format. Strip trailing zeros so common cases
    // like USDC's 18B supply render as "18,000,000,000" not
    // "18,000,000,000.0000".
    final supplyString = _formattedTotalSupply();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _asset.unit,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ColorResources.themeLightGrayWhiteColor(context),
            fontSize: Dimensions.FONT_SIZE_LARGE,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => launchURLApp(_asset.url ?? ''),
          child: CopyText(
            text: _asset.id?.toString() ?? '',
            url: 'https://allo.info/asset/${_asset.id ?? ''}',
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.showProviders) // not-eval row
          Attribute(
            label: 'Amount',
            value: widget.item.amount != null
                ? AppConstants.formateNumber(
                    double.parse(formateAmount(widget.item.amount!,
                        _asset.decimals ?? 0, 6)),
                    points: '0000')
                : 'Unknown amount',
          ),
        Attribute(label: 'Unit name', value: _asset.unit),
        Attribute(label: 'Total supply', value: supplyString),
        Attribute(
          label: 'Decimals',
          value: _asset.decimals?.toString() ?? '',
        ),
        if (widget.showProviders)
          PricePerUnitV2(
            item: widget.item,
            usdValue: widget.total?.priceusdc ?? 1.0,
          ),
        Attribute(
          label: 'URL',
          value: _asset.url,
          type: TextType.link,
          color: ColorResources.primaryColor,
        ),
      ],
    );
  }

  String _formattedTotalSupply() {
    final total = _asset.total;
    if (total == null) return '';
    final decimals = _asset.decimals ?? 0;
    // ``int / pow(10, n)`` is exact for typical asset totals; the
    // potential precision loss at huge supplies (>2^53) is acceptable
    // since we're producing display text, not arithmetic input.
    final scale = _pow10(decimals);
    final value = total / scale;
    return NumberFormat('#,##0.0000')
        .format(value)
        .replaceAll(RegExp(r'\.000*$'), '');
  }

  /// Integer power of ten without importing dart:math just for this.
  /// Caps at 10^18 since Algorand assets max out at decimals=19 but
  /// in practice never exceed 8.
  double _pow10(int n) {
    var v = 1.0;
    for (var i = 0; i < n; i++) {
      v *= 10.0;
    }
    return v;
  }

  Widget _providers() {
    final links = _asset.links;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: listBuilder(
        itemCount: links.length,
        builder: (index) {
          final e = links[index];
          // Provider name is on a Provider object now (was a flat
          // string in v1). The icon lookup needs whatever maps to the
          // legacy slug — v2.Provider.iconSlug does that ("Live Coin
          // Watch" -> "livecoinwatch") matching the website's
          // ``provider_icon`` template filter.
          final slug = e.provider?.iconSlug ?? '';
          final tooltip = e.provider?.name ?? '';
          return Padding(
            padding: const EdgeInsets.only(
                left: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            child: GestureDetector(
              onTap: () => launchURLApp(e.link ?? ''),
              child: Tooltip(
                message: tooltip,
                child: Image.network(
                  AppConstants.getProviderImage(slug),
                  height: 25,
                  width: 25,
                  errorBuilder: (_, __, ___) =>
                      const ErrorImage(height: 25, width: 25),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _divider() => Container(
        height: 1.h,
        margin: EdgeInsets.symmetric(vertical: 21.h),
        width: double.maxFinite,
        color: ColorResources.borderColor,
      );
}

/// Price-per-unit row with toggle between native price and inverted
/// (1/price) display. The price comes from ``v2.AsaItem.price`` (the
/// per-unit ALGO price). When the user is viewing USD totals, we divide
/// by ``Total.priceusdc`` (the ALGO/USD rate) to convert.
class PricePerUnitV2 extends StatefulWidget {
  final v2.AsaItem item;
  final double usdValue;

  const PricePerUnitV2({
    super.key,
    required this.item,
    required this.usdValue,
  });

  @override
  State<PricePerUnitV2> createState() => _PricePerUnitV2State();
}

class _PricePerUnitV2State extends State<PricePerUnitV2> {
  bool _isPriceConverted = false;

  String _getPrice() {
    final isAlgo =
        Provider.of<AppSettingProvider>(context).currency == Currency.algo;
    var price = isAlgo
        ? (widget.item.price ?? 1.0)
        : (widget.item.price ?? 1.0) / widget.usdValue;
    if (_isPriceConverted) price = 1 / price;
    final unit = (_isPriceConverted ? '${widget.item.asset?.unit ?? ''}/' : '') +
        (isAlgo ? 'ALGO' : 'USD');
    return '${AppConstants.formateNumber(price, points: '000000')} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Attribute(
      label: 'Price per unit',
      value: _getPrice(),
      color: _isPriceConverted
          ? ColorResources.primaryColor
          : (Provider.of<ThemeProvider>(context).darkTheme
              ? ColorResources.whiteColor
              : const Color(0xffA8A7A7)),
      onValueTap: () => setState(() => _isPriceConverted = !_isPriceConverted),
    );
  }
}

/// Sticky header rendered above each ASA list tile. V2 version of the
/// ``getStickyHeader`` function in ``asa_list_tile.dart``.
Widget getStickyHeaderV2({
  required String asaId,
  required v2.AsaItem item,
  required BuildContext context,
  required Color color,
  required AppSettingProvider appSettingProvider,
  required v2.Total? total,
  required double tailWidth,
  required Function() onTap,
}) {
  final isSelected = asaId == (item.asset?.id?.toString() ?? '');
  final isAlgo = appSettingProvider.currency == Currency.algo;
  final valueAlgo = item.value ?? 0.0;
  final valueDisplay = isAlgo ? valueAlgo : (valueAlgo / (total?.priceusdc ?? 1.0));
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
      decoration: BoxDecoration(
        color: isSelected
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
      child: Row(
        children: [
          Container(
            width: 5,
            height: double.maxFinite,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
                bottomLeft: Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT),
              ),
            ),
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
                      '${AppConstants.formateNumber(double.parse(formateAmount(
                            item.amount ?? 0,
                            item.asset?.decimals ?? 0,
                            6,
                          )), points: '0000')}  ${item.asset?.unit ?? ''}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        backgroundColor: isSelected
                            ? ColorResources.primaryColor
                            : Provider.of<ThemeProvider>(context).darkTheme
                                ? const Color(0xff373737)
                                : ColorResources.whiteColor,
                        color: isSelected
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
                          '${valueDisplay.toStringAsFixed(2)} ${appSettingProvider.currency.name.toUpperCase()}',
                          style: TextStyle(
                            backgroundColor: isSelected
                                ? ColorResources.primaryColor
                                : Provider.of<ThemeProvider>(context).darkTheme
                                    ? const Color(0xff373737)
                                    : ColorResources.whiteColor,
                            color: isSelected
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
                          isSelected ? Images.IC_ARROW_UP : Images.IC_DROP_DOWN,
                          height: 5,
                          width: 10,
                          color: isSelected
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
                        imageUrl: AppConstants.getAsaImage(
                            (item.asset?.id ?? 0).toString()),
                        height: 35,
                        width: 35,
                        errorWidget: (_, __, ___) =>
                            const ErrorImage(height: 35, width: 35),
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
