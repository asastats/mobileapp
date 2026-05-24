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
import 'package:asa_stats/models/v2/v2.dart' as v2;
import 'package:asa_stats/screens/chart_helpers.dart';
import 'package:asa_stats/widgets/home/amountHeader.dart';
import 'package:asa_stats/models/response/base/response_model.dart';
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/screens/web_view/webview_screen.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:asa_stats/utility/utils.dart';
import 'package:asa_stats/widgets/refresh_widget.dart';
import 'package:asa_stats/widgets/theme_search_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:asa_stats/widgets/chart.dart';

import '../../models/body/chart_data_model.dart';
import '../../providers/asa_provider.dart';
import '../../utility/multiple_gesturedetector.dart';
import '../../widgets/home/nft_list_tile_v2.dart';
import '../../widgets/progressbar.dart';
import 'home_screen.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart' show launchURLApp;

class NftScreen extends StatefulWidget {
  final CategoryType type;
  final bool isSingleAddress;
  final HomeScreenState homeScreenState;

  const NftScreen({
    super.key,
    required this.type,
    required this.isSingleAddress,
    required this.homeScreenState,
  });
  @override
  State<NftScreen> createState() => _NftScreenState();
}

class _NftScreenState extends State<NftScreen> {
  bool _isInit = true;
  bool _isloading = true;
  late double appbarH;

  int _nftHeight = 0;

  String selectedLabel = "";
  String asaId = "";
  String asaResponse = "";

  Map<String, dynamic> asaColors = {};
  List<ChartData> chartData = [];

  // Controller
  late ScrollController controller;
  late TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  //timer
  Timer? timer;

  // ASA — V1 state still populated by the provider's dual-population
  // shim. Search keeps using it (``_asaProvider.searchNFT`` works on
  // v1 shapes). Renders read from ``accountV2``.
  ASAModel asaModel = ASAModel();
  ASAModel originalAsaData = ASAModel();

  // Phase 5c-5 — V2 state. ``accountV2.nftcollections`` is the source
  // of truth for every NFT list-tile row in this screen.
  v2.EvaluatedAccount accountV2 = v2.EvaluatedAccount();

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
    timer?.cancel();
    ToastService.cancel();
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
          toolbarHeight:
              (((accountV2.accountInfo?.addresses.length ?? 0) > 4) ? 120 : 100),
          titleSpacing: 0,
          title: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                AmountHeader(
                  type: CategoryType.nft,
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
                        onTap: () => onAddressTap(element),
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
              child: filterView()),
        ),
        ..._sliverNFTList(accountV2.nftcollections.length),
        if (accountV2.nftcollections.isEmpty) emptyMsg(),
        SliverAppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          // Phase 5c-fixes — gate on chartData.isNotEmpty too. fl_chart
          // throws "Bad state: No element" on an empty ``sections`` list
          // (it reduces over an empty iterable). Flutter catches that
          // and renders the red ErrorWidget in place of the chart.
          toolbarHeight: (_asaProvider.getPieChartVisibility() &&
                  chartData.isNotEmpty)
              ? 250
              : 0,
          title: Column(
            children: [
              if (_asaProvider.getPieChartVisibility() &&
                  chartData.isNotEmpty) ...[
                const SizedBox(height: 20),
                Chart(
                  chartData: chartData,
                  type: CategoryType.nft,
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

  Widget emptyMsg() {
    return const SliverToBoxAdapter(
      child: Center(
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
      ),
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
            onChanged: (str) => _searchData(
              str.toLowerCase(),
            ),
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

  List<Widget> _sliverNFTList(int size) {
    var widgetList = <Widget>[];
    _nftHeight = 0;
    int crossAxisCount = countCrossAxisNFT(context);

    // Phase 5c-5 — palette resolved inline per A7; uses ``nft_colors``
    // slot ``i % palette.length``. Falls back to defaultColor on empty
    // palette so a missing global_settings.json doesn't crash.
    final Map<String, dynamic> palette = asaColors['nft_colors'] is Map
        ? Map<String, dynamic>.from(asaColors['nft_colors'] as Map)
        : <String, dynamic>{};

    for (int index = 0; index < size; index++) {
      final coll = accountV2.nftcollections[index];
      final collName = coll.name ?? '';
      final color = _paletteColor(palette, index);
      final length = coll.nfts.length;
      final nftRowCount = ((length + 1) / crossAxisCount).ceil();
      _nftHeight += nftRowCount * 50;
      final isExpanded = (asaId == collName);
      final int height = isExpanded
          ? 50
          : nftRowCount > 1
              ? (nftRowCount * 40) + 39
              : 50;

      widgetList
        ..add(SliverAppBar(
          toolbarHeight: height.toDouble() + 7,
          title: nftStickyHeaderV2(
            context: context,
            collection: coll,
            total: accountV2.total,
            borderColor: color,
            appSettingProvider: _appSettingProvider,
            crossAxisCount: crossAxisCount,
            isExpanded: isExpanded,
            height: height,
            onTap: () {
              if (_asaProvider.isCaching) return;
              double nHeight = 0;
              setState(() {
                asaId = isExpanded ? '' : collName;
              });
              if (asaId == collName) {
                _appSettingProvider.setValue(true);
              }
              // Compute the scroll offset by summing the heights of
              // every preceding collection row. The branching matches
              // the v1 logic verbatim, just keyed off V2 fields.
              for (int i = 0; i < index; i++) {
                final prev = accountV2.nftcollections[i];
                final prevImagesLen = prev.nfts.length;
                final prevRowCount =
                    ((prevImagesLen + 1) / crossAxisCount).ceil();
                final int prevHeight = (asaId == (prev.name ?? ''))
                    ? 50
                    : prevRowCount > 1
                        ? (prevRowCount * 39) + 45
                        : 0;
                nHeight += prevHeight;
              }
              onListItemTap(index.toDouble(),
                  animate: asaId.isNotEmpty, nHeight: nHeight);
            },
          ),
          pinned: isExpanded && _appSettingProvider.isExpanded,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
        ))
        ..add(
          NFTListTileV2(
            key: ValueKey('$runtimeType $collName NFT List tile'),
            collection: coll,
            total: accountV2.total,
            borderColor: color,
            isExpanded: isExpanded,
            onVisibilityChange: (visible) {
              _appSettingProvider.setValue(visible);
            },
          ),
        );
    }

    return widgetList;
  }

  /// Resolve a palette slot to a Flutter ``Color``. Wraps via modulo so
  /// lists with more items than palette slots still render. Falls back
  /// to ``ColorResources.defaultColor`` for invalid entries.
  Color _paletteColor(Map<String, dynamic> palette, int index) {
    if (palette.isEmpty) return ColorResources.defaultColor;
    final slot = (index % palette.length).toString();
    final hex = palette[slot];
    if (hex is! String || hex.isEmpty) return ColorResources.defaultColor;
    return HexColor(hex);
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

    // Phase 5c-5 / B8 — nft chart computed inline from accountV2 +
    // bundled palette.
    asaColors = await AppConstants.readGlobalJsonFile(context);
    final Map<String, dynamic> palette = asaColors['nft_colors'] is Map
        ? Map<String, dynamic>.from(asaColors['nft_colors'] as Map)
        : <String, dynamic>{};
    chartData.addAll(buildNftChartData(accountV2, palette));

    if (_searchController.text.isNotEmpty) {
      _searchData(_searchController.text);
    }
    setState(() {});
  }

  String getAmount() {
    return "";
  }

  String getOppositeAmount() {
    return "";
  }

  String getAddress(List<String> address) {
    String val = "";
    for (var item in address) {
      val += (" ${item.firstChars(5)}...${item.lastChars(5)}");
    }
    return val;
  }

  void onListItemTap(double index, {bool animate = true, double nHeight = 0}) {
    double offset = appbarH +
        nHeight +
        50 +
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

  void _searchData(String searchText) async {
    asaModel = ASAModel.fromJson(jsonDecode(asaResponse));
    setState(() {});
    if (searchText.isNotEmpty) {
      asaModel.nftValues = _asaProvider.searchNFT(searchText, asaModel);
      setState(() {});
    }
  }

  void changeCurrency(bool val) {
    _appSettingProvider.setCurrency(_appSettingProvider.currency != Currency.usd
        ? Currency.usd
        : Currency.algo);
  }

  void onAddressTap(element) async {
    if ((accountV2.accountInfo?.addresses.length ?? 0) == 1) {
      String url = 'https://algoexplorer.io/address/$element';
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
