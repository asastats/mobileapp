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
import '../../models/response/nftValues.dart';
import '../../providers/asa_provider.dart';
import '../../utility/multiple_gesturedetector.dart';
import '../../widgets/home/nft_list_tile.dart';
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

  Ratiochart? _ratioChart;

  // ASA
  ASAModel asaModel = ASAModel();
  ASAModel originalAsaData = ASAModel();

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
          toolbarHeight: (((asaModel.addresses?.length ?? 0) > 4) ? 120 : 100),
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
                    ...asaModel.addresses?.map((element) {
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
                        }).toList() ??
                        [],
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
        ..._sliverNFTList(asaModel.nftValues?.length ?? 0, asaModel),
        if (asaModel.nftValues?.isEmpty ?? false) emptyMsg(),
        SliverAppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          toolbarHeight: _asaProvider.getPieChartVisibility() ? 220 : 0,
          title: Column(
            children: [
              if (_asaProvider.getPieChartVisibility()) ...[
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

  List<Widget> _sliverNFTList(int size, ASAModel asaModel) {
    var widgetList = <Widget>[];
    _nftHeight = 0;
    int crossAxisCount = countCrossAxisNFT(context);
    for (int index = 0; index < size; index++) {
      NftValues data = asaModel.nftValues?[index] ?? NftValues();
      String colorValue = "";
      colorValue =
          asaModel.nftColors?.getVal((data.collection ?? "").toString()) ?? "";
      Map<String, dynamic> asaColorsCodes = asaColors["nft_colors"] ?? {};
      Color color = (asaColorsCodes.getVal(colorValue) != ""
          ? HexColor(asaColorsCodes.getVal(colorValue))
          : ColorResources.defaultColor);
      var length = data.nfts?.length ?? 0;
      int nftRowCount = ((length + 1) / crossAxisCount).ceil();
      _nftHeight += nftRowCount * 50;
      int height = (asaId == data.collection.toString())
          ? 50
          : nftRowCount > 1
              ? (nftRowCount * 40) + 39
              : 50;
      widgetList
        ..add(SliverAppBar(
          toolbarHeight: height.toDouble() + 7,
          title: nftStickyHeader(
            context: context,
            height: height,
            isExpanded: (asaId == data.collection.toString()),
            crossAxisCount: crossAxisCount,
            borderColor: color,
            appSettingProvider: _appSettingProvider,
            asaData: asaModel,
            // title: "${data.amount ?? 0}  ${data.collection ?? ""}",
            title: AppConstants.removeDecimalZeroFormat(data.amount ?? 0) +
                " " +
                (data.collection ?? ""),
            images: [
              ...?data.nfts?.map<String>((e) => e.nft?.tpath ?? "").toList()
            ],
            miniSubTitle: "BETA ",
            subTitle: (_appSettingProvider.currency == Currency.algo
                ? (data.value ?? 0.0).toStringAsFixed(2)
                : ((data.value ?? 0) / (asaModel.total?.priceusdc ?? 1))
                    .toStringAsFixed(2)),
            onTap: () {
              if (_asaProvider.isCaching) return;
              double nHeight = 0;
              setState(() {
                asaId = asaId == data.collection.toString()
                    ? ""
                    : data.collection.toString();
              });
              if ((asaId == data.collection.toString())) {
                _appSettingProvider.setValue(true);
              }
              for (int i = 0; i < index; i++) {
                NftValues data = asaModel.nftValues?[i] ?? NftValues();
                var length = (data.nfts
                            ?.map<String>((e) =>
                                AppConstants.getNFTImage(e.nft?.tpath ?? ""))
                            .toList() ??
                        [])
                    .length;
                int nftRowCount = ((length + 1) / crossAxisCount).ceil();
                int height = (asaId == data.collection.toString())
                    ? 50
                    : nftRowCount > 1
                        ? (nftRowCount * 39) + 45
                        : 0;
                nHeight += height;
              }
              onListItemTap(index.toDouble(),
                  animate: asaId.isNotEmpty, nHeight: nHeight);
            },
          ),
          pinned: (asaId == data.collection.toString()) &&
              _appSettingProvider
                  .isExpanded, //? hide stick header when it's not visible
          automaticallyImplyLeading: false,
          titleSpacing: 0,
        ))
        ..add(
          NFTListTile(
            key: ValueKey("$runtimeType ${data.collection} NFT List tile"),
            isExpanded: (asaId == data.collection.toString()),
            title: "${data.amount ?? 0}  ${data.collection ?? ""}",
            subTitle: "BETA",
            images: [
              ...?data.nfts?.map<String>((e) => e.nft?.path ?? "").toList()
            ],
            nftValues: data,
            model: asaModel, // remove when we use provider
            borderColor: color,
            onVisibilityChange: (visible) {
              _appSettingProvider.setValue(visible);
            },
          ),
        );
    }

    return widgetList;
  }

  Future updateASAdata() async {
    asaResponse = _asaProvider.getResponse();
    if (widget.isSingleAddress) {
      asaModel = _asaProvider.asaModelSingle.copyWith();
    } else {
      asaModel = _asaProvider.asaModel.copyWith();
    }
    chartData.clear();
    originalAsaData = asaModel.copyWith();
    _ratioChart = asaModel.nftChart;
    for (var i = 0; i < (_ratioChart?.labels?.length ?? 0); i++) {
      chartData.insert(
          i,
          ChartData(
              color: HexColor(
                  (_ratioChart?.datasets?[0].backgroundColor?[i] ?? "")),
              title: (_ratioChart?.labels?[i] ?? ""),
              y: double.parse(_ratioChart?.datasets?[0].data?[i] ?? "")));
    }

    asaColors = await AppConstants.readGlobalJsonFile(context);
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
        (((asaModel.addresses?.length ?? 0) > 4) ? 35 : 0);
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
    if ((asaModel.addresses?.length ?? 0) == 1) {
      String url = 'https://algoexplorer.io/address/$element';
      await launchURLApp(url);
      return;
    }
    showEasyLoader(true);
    _asaProvider.singleAddress = element;
    ResponseModel response =
        await _asaProvider.getAsaData(element, isSingle: true);
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
    Map<String, dynamic> data = {
      "raw": widget.isSingleAddress
          ? _asaProvider.singleAddress.toString()
          : _asaProvider.address.toString()
    };
    ResponseModel responseAddress = await _asaProvider.getAsaAddress(data,
        isSingle: widget.isSingleAddress);
    if (responseAddress.isSuccess) {
      ResponseModel responseData = await _asaProvider
          .getAsaData(responseAddress.data, isSingle: widget.isSingleAddress);
      if (responseData.isSuccess) {
        await _asaProvider.getAsaData(responseAddress.data,
            isSingle: widget.isSingleAddress);
        await updateASAdata();
      }
    }
    return;
  }
}
