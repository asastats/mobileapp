import 'dart:async';
import 'dart:convert';

import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/config/extensions.dart';
import 'package:asa_stats/config/hex_color.dart';
import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:asa_stats/models/response/asa_model.dart';
import 'package:asa_stats/models/response/base/response_model.dart';
import 'package:asa_stats/models/v2/v2.dart' as v2;
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/screens/chart_helpers.dart';
import 'package:asa_stats/screens/web_view/webview_screen.dart';
import 'package:asa_stats/utility/multiple_gesturedetector.dart';
import 'package:asa_stats/widgets/chart.dart';
import 'package:asa_stats/widgets/home/amountHeader.dart';
import 'package:asa_stats/widgets/home/asa_list_tile_v2.dart';
import 'package:asa_stats/widgets/theme_search_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/body/chart_data_model.dart';
import '../../models/response/values.dart';
import '../../providers/asa_provider.dart';
import '../../widgets/progressbar.dart';
import '../../widgets/refresh_widget.dart';
import 'home_screen.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart' show launchURLApp;

class AsaScreen extends StatefulWidget {
  final CategoryType type;
  final bool isSingleAddress;
  final HomeScreenState homeScreenState;

  const AsaScreen({
    super.key,
    required this.type,
    required this.isSingleAddress,
    required this.homeScreenState,
  });

  @override
  State<AsaScreen> createState() => _AsaScreenState();
}

class _AsaScreenState extends State<AsaScreen> {
  bool _isInit = true;
  late double appbarH;

  String selectedLabel = "";
  String asaId = "";
  String asaResponse = "";

  Map<String, dynamic> asaColors = {};
  List<ChartData> chartData = [];

  // Controller
  late ScrollController controller;
  late TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  // ASA — V1 state still populated by the provider's dual-population
  // shim. Search keeps using it (``_asaProvider.searchAsa`` works on
  // v1 shapes) and the screen's ``onAddressTap`` flow still relies on
  // the v1 ``asaModel.addresses`` until Phase 5d. Renders read from
  // ``accountV2``.
  ASAModel asaModel = ASAModel();
  ASAModel originalAsaData = ASAModel();

  // Phase 5c-4 / 5d — V2 state. ``accountV2.asaitems`` is the source
  // of truth for the list-tile rows. The filtered list below mirrors
  // ``accountV2.asaitems`` and gets narrowed by the search box.
  v2.EvaluatedAccount accountV2 = v2.EvaluatedAccount();
  List<v2.AsaItem> _filteredAsaitems = const [];

  //provider
  late ASAProvider _asaProvider;
  late AppSettingProvider _appSettingProvider;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      appbarH = MediaQuery.of(context).padding.top;
      _appSettingProvider = Provider.of<AppSettingProvider>(context);
      _asaProvider = Provider.of<ASAProvider>(context, listen: false);
      await updateASAdata();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultipleGestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Column(
        children: [
          ThemeLinearProgressBar(visible: _asaProvider.isCaching),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.PADDING_SIZE_DEFAULT),
              child: RefreshWidget(
                onRefresh: onRefresh,
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get body {
    return CustomScrollView(
      key: const ValueKey("customScrollView"),
      physics: const AlwaysScrollableScrollPhysics(),
      controller: controller,
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          // Phase 5c-4 — top-level account info from V2.
          toolbarHeight:
              (((accountV2.accountInfo?.addresses.length ?? 0) > 4) ? 35 : 0) +
                  (widget.type == CategoryType.nft ? 50 : 100),
          titleSpacing: 0,
          title: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                AmountHeader(
                  type: CategoryType.asa,
                  isSingle: widget.isSingleAddress,
                ),
                const SizedBox(height: 5),
                Wrap(
                  children: [
                    ...(accountV2.accountInfo?.addresses ?? const [])
                        .map((element) {
                      String val = "";
                      val +=
                          (" ${element.firstChars(5)}...${element.lastChars(5)}");
                      return GestureDetector(
                        onTap: () async {
                          onAddressTap(element);
                        },
                        child: Text(
                          val,
                          style: const TextStyle(
                            color: ColorResources.primaryColor,
                            fontSize: Dimensions.FONT_SIZE_LARGE,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          toolbarHeight: 72,
          leadingWidth: 0,
          titleSpacing: 0,
          backgroundColor: ColorResources.backgroundColor(context),
          title: Padding(
            padding:
                EdgeInsets.only(top: Dimensions.PADDING_SIZE_15, bottom: 7.h),
            child: filterView(),
          ),
        ),

        //? ASA
        if (widget.type == CategoryType.asa)
          emptyMsg(_filteredAsaitems.isEmpty),
        ..._sliverAsaList(_filteredAsaitems.length),

        SliverAppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          // Phase 5c-fixes — also gate on chartData.isNotEmpty. fl_chart's
          // PieChart throws "Bad state: No element" on an empty
          // ``sections`` list (reduces over an empty iterable). Flutter
          // catches and renders ErrorWidget (red box in debug). With
          // ``buildAsaChartData`` returning [] when no positive values
          // exist OR before async updateASAdata populates the list,
          // skipping the widget entirely is safer.
          toolbarHeight: (_asaProvider.getPieChartVisibility() &&
                  chartData.isNotEmpty)
              ? 250
              : 0,
          title: Column(
            children: [
              if (_asaProvider.getPieChartVisibility() &&
                  chartData.isNotEmpty) ...[
                Chart(
                  paddingTop: 40,
                  chartData: chartData,
                  type: CategoryType.asa,
                  categoryScreenState: this,
                  scrollController: controller,
                ),
                const SizedBox(height: 20),
              ]
            ],
          ),
        )
      ],
    );
  }

  Widget emptyMsg(bool showMsg) {
    return SliverToBoxAdapter(
      child: showMsg
          ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: Dimensions.PADDING_SIZE_15),
                child: Text(
                  "Try with different keyword",
                  style: TextStyle(
                    color: ColorResources.primaryColor,
                    fontSize: Dimensions.FONT_SIZE_LARGE_18,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                  ),
                ),
              ),
            )
          : Container(),
    );
  }

  Widget filterView() {
    return Row(
      children: [
        Expanded(
          child: ThemeSearchField(
            hint: "Filter",
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (str) => _searchData(str.toLowerCase(), widget.type),
          ),
        ),
        SizedBox(width: 7.w),
        const Text(
          "ALGO",
          style: TextStyle(
            fontSize: Dimensions.FONT_SIZE_SMALL,
            fontWeight: FontWeight.w600,
            color: ColorResources.textColor,
            fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.PADDING_SIZE_SMALL),
          child: SizedBox(
            height: 24,
            width: 48,
            child: CupertinoSwitch(
              activeColor: ColorResources.primaryColor,
              value: _appSettingProvider.currency == Currency.usd,
              onChanged: changeCurrency,
            ),
          ),
        ),
        const Text(
          "USD",
          style: TextStyle(
            fontSize: Dimensions.FONT_SIZE_SMALL,
            fontWeight: FontWeight.w600,
            color: ColorResources.textColor,
            fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          ),
        ),
      ],
    );
  }

  List<Widget> _sliverAsaList(int size) {
    var widgetList = <Widget>[];
    // Phase 5d — max value across the FILTERED asaitems. With an empty
    // search this is the full list; with a search it's the visible subset.
    final values = _filteredAsaitems
        .map((i) => i.value ?? 0.0)
        .toList(growable: false);
    final max = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxl =
        (Provider.of<AppSettingProvider>(context).currency == Currency.algo
                ? AppConstants.formateNumber(max, points: "00")
                : AppConstants.formateNumber(
                    max / (accountV2.total?.priceusdc ?? 1.0),
                    points: "00"))
            .length;

    // Palette comes from the bundled / fetched global settings JSON
    // (``asa_colors`` slot → hex color). Per A7, color is computed
    // inline at render time: ``palette[i % palette.length]``. Falls
    // back to ``ColorResources.defaultColor`` for empty/malformed
    // palettes.
    final Map<String, dynamic> palette = asaColors['asa_colors'] is Map
        ? Map<String, dynamic>.from(asaColors['asa_colors'] as Map)
        : <String, dynamic>{};

    for (int index = 0; index < size; index++) {
      final item = _filteredAsaitems[index];
      final assetIdStr = item.asset?.id?.toString() ?? '';
      final color = _paletteColor(palette, index);

      widgetList
        ..add(SliverAppBar(
          title: getStickyHeaderV2(
            asaId: asaId,
            item: item,
            context: context,
            color: color,
            appSettingProvider: _appSettingProvider,
            total: accountV2.total,
            onTap: () {
              if (_asaProvider.isCaching) return;
              if (asaId == assetIdStr) {
                asaId = '';
              } else {
                asaId = assetIdStr;
              }
              setState(() {});
              onListItemTap(index.toDouble(), animate: asaId.isNotEmpty);
            },
            tailWidth: (maxl * 6) + 50,
          ),
          pinned: (asaId == assetIdStr) && _appSettingProvider.isExpanded,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
        ))
        ..add(
          ASAListTileV2(
            key: ValueKey('$runtimeType ${item.asset?.id} Asa listTile'),
            item: item,
            total: accountV2.total,
            isAlgo: _appSettingProvider.currency == Currency.algo,
            isExpanded: asaId == assetIdStr,
            borderColor: color,
            onVisibilityChange: (visible) {
              _appSettingProvider.setValue(visible);
            },
          ),
        );
    }

    return widgetList;
  }

  /// Resolve a palette slot to a Flutter ``Color``. Wraps via modulo so
  /// charts/lists with more items than palette slots still render. Falls
  /// back to ``ColorResources.defaultColor`` for invalid entries.
  Color _paletteColor(Map<String, dynamic> palette, int index) {
    if (palette.isEmpty) return ColorResources.defaultColor;
    final slot = (index % palette.length).toString();
    final hex = palette[slot];
    if (hex is! String || hex.isEmpty) return ColorResources.defaultColor;
    return HexColor(hex);
  }

  String getAddress(List<String> address) {
    String val = "";
    for (var item in address) {
      val += (" ${item.firstChars(5)}...${item.lastChars(5)}");
    }
    return val;
  }

  Future updateASAdata() async {
    asaResponse = _asaProvider.getResponse();
    if (widget.isSingleAddress) {
      asaModel = _asaProvider.asaModelSingle.copyWith();
      accountV2 = _asaProvider.accountV2Single ?? v2.EvaluatedAccount();
    } else {
      asaModel = _asaProvider.asaModel.copyWith();
      accountV2 = _asaProvider.accountV2;
    }
    chartData.clear();
    originalAsaData = asaModel.copyWith();

    // Phase 5d — initialize the filtered list from the full V2 list;
    // the search box narrows it.
    _filteredAsaitems = accountV2.asaitems;

    // Phase 5c-4 / B8 — asa chart computed inline from accountV2 +
    // bundled palette. Need to load the palette first since the chart
    // colors come from ``asa_colors``.
    asaColors = await AppConstants.readGlobalJsonFile(context);
    final Map<String, dynamic> palette = asaColors['asa_colors'] is Map
        ? Map<String, dynamic>.from(asaColors['asa_colors'] as Map)
        : <String, dynamic>{};
    chartData.addAll(buildAsaChartData(accountV2, palette));

    if (_searchController.text.isNotEmpty) {
      _searchData(_searchController.text, widget.type);
    }
    setState(() {});
  }

  void onListItemTap(double index, {bool animate = true}) {
    double offset = appbarH +
        (widget.type == CategoryType.nft ? 50 : 100) +
        ((index.toInt() == 0) ? 7 : (index * 54)) +
        (((accountV2.accountInfo?.addresses.length ?? 0) > 4) ? 35 : 0);
    if (animate) {
      if (controller.position.maxScrollExtent > 0) {
        controller.animateTo(
          offset, //Top padding + previous asa list height + bottom padding
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _searchData(String searchText, CategoryType type) async {
    // Phase 5d — V2 search via provider helper, writes the filtered
    // asaitem list. Empty search restores the full list.
    if (searchText.isEmpty) {
      setState(() {
        _filteredAsaitems = accountV2.asaitems;
      });
      return;
    }
    _filteredAsaitems = _asaProvider.searchAsaitemsV2(searchText, accountV2);
    setState(() {});
  }

  void changeCurrency(bool val) {
    _appSettingProvider.setCurrency(_appSettingProvider.currency != Currency.usd
        ? Currency.usd
        : Currency.algo);
  }

  void onAddressTap(element) async {
    if ((accountV2.accountInfo?.addresses.length ?? 0) == 1) {
      String url = 'https://allo.info/account/$element';
      await launchURLApp(url);
      return;
    }
    showEasyLoader(true);
    _asaProvider.singleAddress = element;
    // Phase 5c — V2 fetch via dual-population shim.
    ResponseModel response =
        await _asaProvider.getEvaluatedAccountV2(element, isSingle: true);
    showEasyLoader(_asaProvider.isLoading);
    if (response.isSuccess) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (builder) => const HomeScreen(
                    key: ValueKey("single"),
                    isSingleAddress: true,
                  )));
      widget.homeScreenState.initController();
      widget.homeScreenState.setState(() {});
    }
    setState(() {});
  }

  Future onRefresh() async {
    final lookupAddress = widget.isSingleAddress
        ? _asaProvider.singleAddress.toString()
        : _asaProvider.address.toString();
    // See note in show_all_screen.dart onRefresh re: duplicate fetch
    // (preserved pre-existing V1 behavior).
    ResponseModel responseAddress =
        await _asaProvider.getBundleHashV2(lookupAddress);
    if (responseAddress.isSuccess) {
      ResponseModel responseData = await _asaProvider.getEvaluatedAccountV2(
          responseAddress.data,
          isSingle: widget.isSingleAddress);
      if (responseData.isSuccess) {
        await _asaProvider.getEvaluatedAccountV2(responseAddress.data,
            isSingle: widget.isSingleAddress);
        await updateASAdata();
      }
    }
    return;
  }
}
