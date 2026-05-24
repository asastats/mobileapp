import 'dart:async';
import 'dart:developer';
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
import 'package:asa_stats/screens/home/home_screen.dart';
import 'package:asa_stats/screens/home/widget/message.dart';
import 'package:asa_stats/screens/web_view/webview_screen.dart';
import 'package:asa_stats/utility/multiple_gesturedetector.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:asa_stats/utility/utils.dart';
import 'package:asa_stats/widgets/chart.dart';
import 'package:asa_stats/widgets/home/address_action_row.dart';
import 'package:asa_stats/widgets/home/amountHeader.dart';
import 'package:asa_stats/widgets/home/asa_list_tile_v2.dart';
import 'package:asa_stats/widgets/home/nft_list_tile_v2.dart';
import 'package:asa_stats/widgets/home/not_eval_list_tile.dart';
import 'package:asa_stats/widgets/progressbar.dart';
import 'package:asa_stats/widgets/refresh_widget.dart';
import 'package:asa_stats/widgets/theme_search_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/body/chart_data_model.dart';
import '../../models/response/nftValues.dart';
import '../../models/response/notEval.dart';
import '../../models/response/values.dart';
import '../../providers/asa_provider.dart';
import '../../widgets/home/nft_list_tile.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart' show launchURLApp;

class ShowAllScreen extends StatefulWidget {
  final CategoryType type;
  final bool isSingleAddress;
  final HomeScreenState homeScreenState;
  const ShowAllScreen({
    Key? key,
    required this.type,
    required this.isSingleAddress,
    required this.homeScreenState,
  }) : super(key: key);

  @override
  State<ShowAllScreen> createState() => _ShowAllScreenState();
}

class _ShowAllScreenState extends State<ShowAllScreen> {
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

  //timer
  Timer? timer;

  // ASA
  ASAModel asaModel = ASAModel();
  ASAModel originalAsaData = ASAModel();

  // Phase 5c-3 — V2 state. Currently this screen reads top-level account
  // info (addresses, online, warning, information, total), list counts,
  // and chart data from ``_accountV2`` directly. Per-row drill data
  // (values[i], nftValues[i], notEval[i] passed into AsaListTile /
  // NftListTile / NotEvalListTile) still comes from ``asaModel`` because
  // those widgets haven't been migrated yet (Phases 5c-4 / 5c-5). The
  // dual-population shim in ASAProvider keeps both in sync.
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
      // Phase 5c-3 — data-presence check uses V2 state. ``accountV2`` is
      // never null (provider initializes it to ``EvaluatedAccount()`` —
      // empty lists for asaitems/nftcollections/notevals), so we check
      // for non-empty content rather than null. ``preCacheImages`` still
      // takes the V2 NftCollection list (migrated 5c-fixes).
      if (_asaProvider.accountV2.asaitems.isNotEmpty ||
          _asaProvider.accountV2.nftcollections.isNotEmpty ||
          _asaProvider.accountV2.notevals.isNotEmpty) {
        preCacheImages(_asaProvider.asaModel.nftValues ?? []);
        await updateASAdata();
        autoRefresh();
      }
      if (_asaProvider.isAddressSaved() &&
          _asaProvider.accountV2.asaitems.isEmpty &&
          _asaProvider.accountV2.nftcollections.isEmpty &&
          _asaProvider.accountV2.notevals.isEmpty) {
        _asaProvider.address = _asaProvider.getAddress().first;
        showEasyLoader(true);
        // Phase 5c — address lookup + account fetch migrated to V2.
        // The provider dual-populates V1 state via the v2ToV1ASAModel
        // shim, so this screen's existing references to ``asaModel``
        // (built from ``_asaData``) keep working until the screen
        // itself migrates to read ``accountV2`` in a later sub-phase.
        ResponseModel response = await _asaProvider
            .getBundleHashV2(_asaProvider.getAddress().first);
        ResponseModel responseData =
            await _asaProvider.getEvaluatedAccountV2(response.data);
        showEasyLoader(_asaProvider.isLoading);
        if (responseData.isSuccess) {
          preCacheImages(_asaProvider.asaModel.nftValues ?? []);
          await updateASAdata();
          autoRefresh();
        }
        setState(() {});
      }
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
      physics: const BouncingScrollPhysics(),
      controller: controller,
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          // Phase 5c-3 — top-level account info now sourced from
          // accountV2 directly. The shim keeps asaModel populated in
          // parallel so child list-tile widgets (which still consume
          // v1 types) keep rendering until 5c-4 / 5c-5.
          toolbarHeight:
              (((accountV2.accountInfo?.addresses.length ?? 0) > 4) ? 35 : 20) +
                  (widget.type == CategoryType.nft ? 50 : 100) +
                  (accountV2.systemInfo?.warning != null ? 40 : 0) +
                  (accountV2.systemInfo?.information != null ? 40 : 0),
          titleSpacing: 0,
          title: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                AmountHeader(
                  type: CategoryType.all,
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
                const SizedBox(height: 8),
                AddressActionRow(
                    isSingle:
                        (accountV2.accountInfo?.addresses.length ?? 0) == 1,
                    status: accountV2.accountInfo?.online ?? false,
                    exportUrl: getSingleAddressForTax(_asaProvider.address)),
                if (accountV2.systemInfo?.warning != null)
                  const Message(type: messageType.message),
                if (accountV2.systemInfo?.information != null)
                  const Message(type: messageType.info),
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
        if (widget.type == CategoryType.all)
          emptyMsg(accountV2.nftcollections.isEmpty &&
              accountV2.asaitems.isEmpty),

        //? ASA
        if (widget.type == CategoryType.all ||
            widget.type == CategoryType.asa) ...[
          if (widget.type == CategoryType.asa)
            emptyMsg(accountV2.asaitems.isEmpty),
          // Per-row drill (asaModel.values[i] passed into list tiles)
          // stays on V1 until Phase 5c-4 migrates the tile widgets;
          // ``asaModel.values?.length`` is equivalent to
          // ``accountV2.asaitems.length`` via the shim. Using the V2
          // count keeps the read surface consistent.
          ..._sliverAsaList(accountV2.asaitems.length),
        ],

        //? NFT
        ...[
          if (widget.type == CategoryType.all &&
              accountV2.nftcollections.isNotEmpty)
            SliverAppBar(
              toolbarHeight: 43,
              leadingWidth: 0,
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              title: Container(
                height: 1.h,
                width: double.maxFinite,
                color: ColorResources.borderColor,
              ),
            ),
          if (widget.type == CategoryType.nft ||
              widget.type == CategoryType.all) ...[
            if (widget.type == CategoryType.nft)
              emptyMsg(accountV2.nftcollections.isEmpty),
            ..._sliverNFTList(accountV2.nftcollections.length),
          ],
        ],

        //? Not Eval
        if (widget.type == CategoryType.all &&
            accountV2.notevals.isNotEmpty) ...[
          SliverAppBar(
            toolbarHeight: 43,
            leadingWidth: 0,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: Container(
              height: 1.h,
              width: double.maxFinite,
              color: ColorResources.borderColor,
            ),
          ),
          ..._sliverNotEvalList(accountV2.notevals.length),
        ],
        SliverAppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          toolbarHeight: _asaProvider.getPieChartVisibility() ? 250 : 0,
          title: Column(
            children: [
              if (_asaProvider.getPieChartVisibility()) ...[
                const SizedBox(height: 20),
                Chart(
                  chartData: chartData,
                  type: widget.type,
                  categoryScreenState: this,
                  enableScrollOnSectionTap: false,
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
    // Compute the max asaitem value from V2 directly. Returns 0.0 when
    // the list is empty (matches V1's `?? 0.0` fallback chain).
    final values = accountV2.asaitems
        .map((i) => i.value ?? 0.0)
        .toList(growable: false);
    final max =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxl =
        (Provider.of<AppSettingProvider>(context).currency == Currency.algo
                ? AppConstants.formateNumber(max, points: "00")
                : AppConstants.formateNumber(
                    ((max) / (accountV2.total?.priceusdc ?? 1)),
                    points: "00"))
            .length;
    for (int index = 0; index < size; index++) {
      // Phase 5d-prep — iterate V2 directly. Per-row color computed
      // inline (palette[i % palette.length]) per A7.
      final item = accountV2.asaitems[index];
      final assetIdStr = item.asset?.id?.toString() ?? '';
      final Map<String, dynamic> palette = asaColors['asa_colors'] is Map
          ? Map<String, dynamic>.from(asaColors['asa_colors'] as Map)
          : <String, dynamic>{};
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

  List<Widget> _sliverNFTList(int size) {
    var widgetList = <Widget>[];
    int crossAxisCount = countCrossAxisNFT(context);
    final Map<String, dynamic> palette = asaColors['nft_colors'] is Map
        ? Map<String, dynamic>.from(asaColors['nft_colors'] as Map)
        : <String, dynamic>{};

    for (int index = 0; index < size; index++) {
      final coll = accountV2.nftcollections[index];
      final collName = coll.name ?? '';
      final color = _paletteColor(palette, index);
      final length = coll.nfts.length;
      final nftRowCount = ((length + 1) / crossAxisCount).ceil();
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
              onListItemTap(
                  ((widget.type == CategoryType.all
                              ? (accountV2.asaitems.length + 0.76)
                              : 0) +
                          index)
                      .toDouble(),
                  animate: asaId.isNotEmpty,
                  nHeight: nHeight);
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

  List<Widget> _sliverNotEvalList(int size) {
    var widgetList = <Widget>[];
    widgetList.add(SliverAppBar(
      title: NotEvalListTile(
        isExpanded: (asaId == "not evaluated"),
        title: "${accountV2.notevals.length} not evaluated",
        onExpand: () {
          if (_asaProvider.isCaching) return;
          double nHeight = 0;
          if ((asaId == "not evaluated")) {
            asaId = "";
          } else {
            asaId = "not evaluated";
          }
          //List height count
          int crossAxisCount = countCrossAxisNFT(context);
          setState(() {});
          // Per-item drill below: iterate V2 nftcollections; the
          // measurement only needs counts, so no v1 reads.
          for (int i = 0; i < accountV2.nftcollections.length; i++) {
            final coll = accountV2.nftcollections[i];
            final imgCount = coll.nfts.length;
            final nftRowCount = ((imgCount + 1) / crossAxisCount).ceil();
            final collName = coll.name ?? '';
            final int height = (asaId == collName)
                ? 50
                : nftRowCount > 1
                    ? (nftRowCount * 39) + 45
                    : 0;
            nHeight += height;
          }
          onListItemTap(
              (accountV2.asaitems.length +
                      accountV2.nftcollections.length)
                  .toDouble(),
              animate: asaId.isNotEmpty,
              nHeight: nHeight);
        },
      ),
      pinned: (asaId == "not evaluated"),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
    ));
    for (int index = 0; index < size; index++) {
      // NotEvaluatedItem -> AsaItem: V2 shapes share the asset/amount/
      // programs fields; the not-eval items just don't have a value or
      // price (those default to null on AsaItem, which the tile renders
      // as zero/empty). Wrapping on the fly is cleaner than having a
      // parallel NotEvalListTileV2 — the user-visible difference is
      // ``showProviders: false`` (links are computed-value features
      // that don't apply to not-eval rows).
      final noteval = accountV2.notevals[index];
      final wrapped = v2.AsaItem(
        asset: noteval.asset,
        amount: noteval.amount,
        programs: noteval.programs,
      );
      widgetList.add(
        ASAListTileV2(
          item: wrapped,
          total: accountV2.total,
          isAlgo: _appSettingProvider.currency == Currency.algo,
          isExpanded: (asaId == 'not evaluated'),
          borderColor: ColorResources.whiteColor,
          showProviders: false,
          onVisibilityChange: (visible) {},
        ),
      );
    }

    return widgetList;
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

    // Phase 5c-3 / B8 — chart data is now computed inline from the V2
    // model instead of read from the pre-built ``asaModel.ratioChart`` /
    // ``asaChart`` / ``nftChart`` (the shim leaves those null per design).
    // For ``CategoryType.all`` this is the 3-segment ALGO/ASA/NFT pie
    // matching the v1 backend's _ratio_chart_data() output. The two
    // other branches stay null-safe so unmigrated tabs that instantiate
    // this widget with a different type don't crash — Phase 5c-4 / 5c-5
    // will rewrite the asa/nft per-item charts in their own screens.
    chartData.addAll(buildRatioChartData(accountV2, widget.type));

    asaColors = await AppConstants.readGlobalJsonFile(context);
    if (_searchController.text.isNotEmpty) {
      _searchData(_searchController.text, widget.type);
    }
    setState(() {});
    return;
  }

  void onListItemTap(double index, {bool animate = true, double nHeight = 0}) {
    double offset = appbarH +
        nHeight +
        100 +
        ((index.toInt() == 0) ? 7 : (index * 54)) +
        (((accountV2.accountInfo?.addresses.length ?? 0) > 4) ? 35 : 0) +
        (accountV2.systemInfo?.warning != null ? 40 : 0) +
        (accountV2.systemInfo?.information != null ? 40 : 0);
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
    asaModel = ASAModel.fromJson(jsonDecode(asaResponse));
    setState(() {});
    if (searchText.isNotEmpty) {
      if (type == CategoryType.all) {
        asaModel.values = _asaProvider.searchAsa(searchText, asaModel);
        asaModel.nftValues = _asaProvider.searchNFT(searchText, asaModel);
        asaModel.notEval = _asaProvider.searchNotEval(searchText, asaModel);
      } else if (type == CategoryType.asa) {
        asaModel.values = _asaProvider.searchAsa(searchText, asaModel);
      } else if (type == CategoryType.nft) {
        asaModel.nftValues = _asaProvider.searchNFT(searchText, asaModel);
      }
      setState(() {});
    }
  }

  void changeCurrency(bool val) {
    _appSettingProvider.setCurrency(_appSettingProvider.currency != Currency.usd
        ? Currency.usd
        : Currency.algo);
  }

  void autoRefresh() {
    if (!_asaProvider.isAutoRefreshOn()) return;
    timer = Timer.periodic(
        const Duration(seconds: AppConstants.REFRESH_TIMEOUT), (Timer t) async {
      debugPrint("Data updating...");
      if (!_asaProvider.isAutoRefreshOn()) {
        ToastService.cancel();
        return t.cancel(); // Cancel time if user disable it
      }
      ResponseModel responseAddress = await _asaProvider.getBundleHashV2(
        widget.isSingleAddress
            ? _asaProvider.singleAddress.toString()
            : _asaProvider.address.toString(),
      );
      if (responseAddress.isSuccess) {
        await _asaProvider.getEvaluatedAccountV2(responseAddress.data,
            isSingle: widget.isSingleAddress);
        updateASAdata();
      }
      ToastService.show("Data updated");
    });
  }

  void preCacheImages(List<v2.NftCollection> list) async {
    _asaProvider.isCaching = true;

    for (final coll in list) {
      for (final n in coll.nfts) {
        final imagePath = n.nft?.image ?? '';

        if (!_asaProvider.imageProviders.containsKey(imagePath) &&
            imagePath.isNotEmpty) {
          // V2 has no ``hash`` field; we always pre-cache. The v1 path's
          // hash-presence skip was a duplication avoidance heuristic
          // for assets that shared their on-chain hash; without it we
          // may pre-cache the same URL twice if it appears across
          // collections. ``CachedNetworkImage`` deduplicates on URL at
          // the disk-cache layer anyway, so the cost is one extra
          // in-memory ImageProvider entry per duplicate URL.
          Image image = Image.network(
            AppConstants.getNFTImage(imagePath),
            height: 156,
            width: 156,
          );

          await precacheImage(image.image, context);
          _asaProvider.imageProviders[imagePath] = image;

          log('Pre-cached image $imagePath', name: 'Image Caching');
        }
      }
    }

    _asaProvider.isCaching = false;
    setState(() {});
  }

  void onAddressTap(element) async {
    if ((accountV2.accountInfo?.addresses.length ?? 0) == 1) {
      String url = 'https://allo.info/account/$element';
      await launchURLApp(url);
      return;
    }
    showEasyLoader(true);
    _asaProvider.singleAddress = element;
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

  // hacky address handling for tax report link for a single address, in cases when we navigate to single address from within a bundle
  String getSingleAddressForTax(String asaProviderDotAddress) {
    List<String> parts = asaProviderDotAddress
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.length > 1) {
      asaProviderDotAddress = _asaProvider.singleAddress;
    }

    final addresses = accountV2.accountInfo?.addresses ?? const <String>[];
    final addrPart =
        addresses.length == 1 ? addresses[0] : _asaProvider.bundleHash;
    return ('${AppConstants.TAX_URL}$addrPart');
  }

  Future onRefresh() async {
    final lookupAddress = widget.isSingleAddress
        ? _asaProvider.singleAddress.toString()
        : _asaProvider.address.toString();
    // Note: V1 ``getAsaAddress`` had an ``isSingle`` parameter that the
    // V1 implementation actually ignored; V2 ``getBundleHashV2`` doesn't
    // take it (the bundle hash is identical regardless). The flag is
    // only meaningful on the account-fetch step.
    ResponseModel responseAddress =
        await _asaProvider.getBundleHashV2(lookupAddress);
    if (responseAddress.isSuccess) {
      ResponseModel responseData = await _asaProvider.getEvaluatedAccountV2(
          responseAddress.data,
          isSingle: widget.isSingleAddress);
      if (responseData.isSuccess) {
        // Pre-existing V1 quirk: the original called getAsaData twice
        // here for unclear reasons. Preserved bit-for-bit to avoid
        // introducing behavior changes in this transition; the
        // duplicate fetch is a Phase 5d / general-cleanup candidate.
        await _asaProvider.getEvaluatedAccountV2(responseAddress.data,
            isSingle: widget.isSingleAddress);
        await updateASAdata();
      }
    }
    return;
  }

  /// Resolve a palette slot (decimal-string key) to a Flutter ``Color``.
  /// Wraps via modulo so a chart/list with more items than palette slots
  /// still renders. Falls back to ``ColorResources.defaultColor`` for
  /// invalid entries.
  Color _paletteColor(Map<String, dynamic> palette, int index) {
    if (palette.isEmpty) return ColorResources.defaultColor;
    final slot = (index % palette.length).toString();
    final hex = palette[slot];
    if (hex is! String || hex.isEmpty) return ColorResources.defaultColor;
    return HexColor(hex);
  }
}
