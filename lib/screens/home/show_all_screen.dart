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
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/screens/home/home_screen.dart';
import 'package:asa_stats/screens/home/widget/message.dart';
import 'package:asa_stats/screens/web_view/webview_screen.dart';
import 'package:asa_stats/utility/multiple_gesturedetector.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:asa_stats/utility/utils.dart';
import 'package:asa_stats/widgets/chart.dart';
import 'package:asa_stats/widgets/home/address_action_row.dart';
import 'package:asa_stats/widgets/home/amountHeader.dart';
import 'package:asa_stats/widgets/home/asa_list_tile.dart';
import 'package:asa_stats/widgets/home/not_eval_list_tile.dart';
import 'package:asa_stats/widgets/progressbar.dart';
import 'package:asa_stats/widgets/refresh_widget.dart';
import 'package:asa_stats/widgets/theme_search_field.dart';
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
      if ((_asaProvider.asaModel.values != null &&
          _asaProvider.asaModel.nftValues != null &&
          _asaProvider.asaModel.notEval != null)) {
        preCacheImages(_asaProvider.asaModel.nftValues ?? []);
        await updateASAdata();
        autoRefresh();
      }
      if (_asaProvider.isAddressSaved() &&
          (asaModel.values == null &&
              asaModel.nftValues == null &&
              asaModel.notEval == null)) {
        _asaProvider.address = _asaProvider.getAddress().first;
        showEasyLoader(true);
        ResponseModel response = await _asaProvider
            .getAsaAddress({"raw": _asaProvider.getAddress().first});
        ResponseModel responseData =
            await _asaProvider.getAsaData(response.data);
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
          toolbarHeight: (((asaModel.addresses?.length ?? 0) > 4) ? 35 : 20) +
              (widget.type == CategoryType.nft ? 50 : 100) +
              (asaModel.warning != null ? 40 : 0) +
              (asaModel.information != null ? 40 : 0),
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
                    ...asaModel.addresses?.map((element) {
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
                        }).toList() ??
                        [],
                  ],
                ),
                const SizedBox(height: 8),
                AddressActionRow(
                    isSingle: asaModel.addresses?.length == 1,
                    status: asaModel.online ?? false,
                    exportUrl: getSingleAddressForTax(_asaProvider.address)),
                if (asaModel.warning != null)
                  const Message(type: messageType.message),
                if (asaModel.information != null)
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
          emptyMsg(((asaModel.nftValues?.isEmpty ?? false) &&
              (asaModel.values?.isEmpty ?? false))),

        //? ASA
        if (widget.type == CategoryType.all ||
            widget.type == CategoryType.asa) ...[
          if (widget.type == CategoryType.asa)
            emptyMsg((asaModel.values?.isEmpty ?? false)),
          ..._sliverAsaList(asaModel.values?.length ?? 0),
        ],

        //? NFT
        ...[
          if (widget.type == CategoryType.all &&
              (asaModel.nftValues?.isNotEmpty ?? false))
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
              emptyMsg((asaModel.nftValues?.isEmpty ?? false)),
            ..._sliverNFTList(asaModel.nftValues?.length ?? 0),
          ],
        ],

        //? Not Eval
        if (widget.type == CategoryType.all &&
            (asaModel.notEval?.isNotEmpty ?? false)) ...[
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
          ..._sliverNotEvalList(asaModel.notEval?.length ?? 0),
        ],
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
                  type: widget.type,
                  categoryScreenState: this,
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
    final max =
        (asaModel.values?.map((e) => e.value).toList().isNotEmpty ?? false)
            ? (asaModel.values
                    ?.map((e) => e.value)
                    .toList()
                    .reduce((curr, next) => (curr! > next! ? curr : next)) ??
                0.0)
            : 0.0;
    final maxl =
        (Provider.of<AppSettingProvider>(context).currency == Currency.algo
                ? AppConstants.formateNumber(max, points: "00")
                : AppConstants.formateNumber(
                    ((max) / (asaModel.total?.priceusdc ?? 1)),
                    points: "00"))
            .length;
    for (int index = 0; index < size; index++) {
      Values data = asaModel.values?[index] ?? Values();
      String colorValue = "";
      colorValue = asaModel.colors?.getVal((data.id ?? "").toString()) ?? "";
      Map<String, dynamic> asaColorsCodes = asaColors["asa_colors"] ?? {};
      Color color = (asaColorsCodes.getVal(colorValue) != ""
          ? HexColor(asaColorsCodes.getVal(colorValue))
          : ColorResources.defaultColor);

      widgetList
        ..add(SliverAppBar(
          title: getStickyHeader(
            asaId: asaId,
            data: data,
            context: context,
            color: color,
            appSettingProvider: _appSettingProvider,
            asaData: asaModel,
            onTap: () {
              if (_asaProvider.isCaching) return;
              if ((asaId == data.asa?.id.toString())) {
                asaId = "";
              } else {
                asaId = data.asa?.id.toString() ?? "";
              }
              setState(() {});
              onListItemTap(index.toDouble(), animate: asaId.isNotEmpty);
            },
            tailWidth: (maxl * 6) + 50,
          ),
          pinned: (asaId == data.asa?.id.toString()) &&
              _appSettingProvider
                  .isExpanded, // hide stick header when it's not visible
          automaticallyImplyLeading: false,
          titleSpacing: 0,
        ))
        ..add(
          ASAListTile(
            key: ValueKey("$runtimeType ${data.asa?.id} Asa listTile"),
            // upper line change unit to id, and it doesn't crash
            title: data.asa?.unit ?? "",
            isAlgo: _appSettingProvider.currency == Currency.algo,
            values: data,
            model: asaModel, // remove when we use provider
            isExpanded: (asaId == data.asa?.id.toString()),
            borderColor: color,
            onVisibilityChange: (visible) {
              // setState(() {
              //   _expandedVisible = visible;
              // });
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
    for (int index = 0; index < size; index++) {
      NftValues data = asaModel.nftValues?[index] ?? NftValues();
      String colorValue = "";
      colorValue =
          asaModel.nftColors?.getVal((data.collection ?? "").toString()) ?? "";
      Map<String, dynamic> asaColorsCodes = asaColors["nft_colors"] ?? {};
      Color color = (asaColorsCodes.getVal(colorValue) != ""
          ? HexColor(asaColorsCodes.getVal(colorValue))
          : ColorResources.defaultColor);
      var length = (data.nfts
                  ?.map<String>(
                      (e) => AppConstants.getNFTImage(e.nft?.tpath ?? ""))
                  .toList() ??
              [])
          .length;
      int nftRowCount = ((length + 1) / crossAxisCount).ceil();
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
            title: AppConstants.removeDecimalZeroFormat(data.amount ?? 0) +
                " " +
                (data.collection ?? ""),
            images:
                data.nfts?.map<String>((e) => e.nft?.tpath ?? "").toList() ??
                    [],
            miniSubTitle: "BETA ",
            subTitle: (_appSettingProvider.currency == Currency.algo
                ? (data.value ?? 0.0).toStringAsFixed(2)
                : ((data.value ?? 0) / (asaModel.total?.priceusdc ?? 1))
                    .toStringAsFixed(2)),
            onTap: () {
              double nHeight = 0;
              if (_asaProvider.isCaching) return;
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
              onListItemTap(
                  ((widget.type == CategoryType.all
                              ? ((asaModel.values?.length ?? 0) + 0.76)
                              : 0) +
                          index)
                      .toDouble(),
                  animate: asaId.isNotEmpty,
                  nHeight: nHeight);
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
            images: data.nfts
                    ?.map<String>((e) => e.nft?.urls?['URL'] ?? "")
                    .toList() ??
                [],
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

  List<Widget> _sliverNotEvalList(int size) {
    var widgetList = <Widget>[];
    widgetList.add(SliverAppBar(
      title: NotEvalListTile(
        isExpanded: (asaId == "not evaluated"),
        title: "${asaModel.notEval?.length ?? 0} not evaluated",
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
          for (int i = 0; i < (asaModel.nftValues?.length ?? 0); i++) {
            NftValues data = asaModel.nftValues?[i] ?? NftValues();
            var length = (data.nfts
                        ?.map<String>(
                            (e) => AppConstants.getNFTImage(e.nft?.tpath ?? ""))
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
          onListItemTap(
              (asaModel.values?.length ?? 0) +
                  (asaModel.nftValues?.length ?? 0).toDouble(),
              animate: asaId.isNotEmpty,
              nHeight: nHeight);
        },
      ),
      pinned: (asaId == "not evaluated"),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
    ));
    for (int index = 0; index < size; index++) {
      NotEval data = asaModel.notEval?[index] ?? NotEval();
      widgetList.add(
        ASAListTile(
          // key: ValueKey("asaListTile ${data.asa?.unit ?? ""}"),
          title: data.asa?.unit ?? "",
          isAlgo: _appSettingProvider.currency == Currency.algo,
          values: Values(
            amount: data.amount,
            asa: data.asa,
            dapps: data.dapps,
            id: data.id,
            price: data.price,
            value: data.value,
          ),
          model: asaModel, // remove when we use provider
          isExpanded: (asaId == "not evaluated"),
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
    } else {
      asaModel = _asaProvider.asaModel.copyWith();
    }
    chartData.clear();
    originalAsaData = asaModel.copyWith();
    _ratioChart = widget.type == CategoryType.all
        ? asaModel.ratioChart
        : widget.type == CategoryType.asa
            ? asaModel.asaChart
            : asaModel.nftChart;
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
        (((asaModel.addresses?.length ?? 0) > 4) ? 35 : 0) +
        (asaModel.warning != null ? 40 : 0) +
        (asaModel.information != null ? 40 : 0);
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
      ResponseModel responseAddress = await _asaProvider.getAsaAddress({
        "raw": widget.isSingleAddress
            ? _asaProvider.singleAddress.toString()
            : _asaProvider.address.toString()
      });
      if (responseAddress.isSuccess) {
        await _asaProvider.getAsaData(responseAddress.data,
            isSingle: widget.isSingleAddress);
        updateASAdata();
      }
      ToastService.show("Data updated");
    });
  }

  void preCacheImages(List<NftValues> list) async {
    Map<String, Image> providers = {};
    _asaProvider.isCaching = true;
    for (NftValues nft in list) {
      for (Nfts n in (nft.nfts ?? [])) {
        // if (!_asaProvider.imageProviders.containsKey(n.nft?.tpath ?? "")) {
        //   Image tImage = Image.network(
        //     AppConstants.getNFTImage(n.nft?.tpath ?? ""),
        //     height: 35,
        //     width: 35,
        //   );
        //   providers.addAll({n.nft?.tpath ?? "": tImage});
        //   await precacheImage(tImage.image, context, size: const Size(35, 35));
        // }
        if (!_asaProvider.imageProviders.containsKey(n.nft?.path ?? "")) {
          Image image = Image.network(
            AppConstants.getNFTImage(n.nft?.path ?? ""),
            height: 156,
            width: 156,
          );
          providers.addAll({n.nft?.path ?? "": image});
          precacheImage(image.image, context, size: const Size(156, 156),
              onError: (o, s) {
            log("pre caching error", stackTrace: s, name: "Error", error: o);
          }).then((value) => log(
              "Caches image[${nft.nfts?.indexOf(n)}] ${n.nft?.path ?? ""}",
              name: "Caching info"));
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
    _asaProvider.isCaching = false;
    setState(() {});
    providers.forEach((key, value) {
      _asaProvider.imageProviders[key] = value;
    });
    debugPrint("Pre caching done");
  }

  void onAddressTap(element) async {
    if ((asaModel.addresses?.length ?? 0) == 1) {
      String url = 'https://allo.info/account/$element';
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

  // hacky address handling for tax report link for a single address, in cases when we navigate to single address from within a bundle
  String getSingleAddressForTax(String asaProviderDotAddress) {
    List<String> parts = asaProviderDotAddress
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.length > 1) {
      asaProviderDotAddress = _asaProvider.singleAddress;
    }

    return ('${AppConstants.TAX_URL}${(asaModel.addresses?.length == 1) ? asaModel.addresses![0] : _asaProvider.bundleHash}');
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

// class Chart extends StatelessWidget {
//   final List<ChartData> chartData;
//   final CategoryType type;
//   final _ShowAllScreenState categoryScreenState;
//   const Chart({
//     Key? key,
//     required this.chartData,
//     required this.type,
//     required this.categoryScreenState,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 200,
//       child: chartData.isEmpty
//           ? Container()
//           : SfCircularChart(
//               legend: Legend(
//                 position: LegendPosition.bottom,
//                 orientation: LegendItemOrientation.horizontal,
//                 isVisible: true,
//                 height: "30%",
//                 isResponsive: true,
//                 toggleSeriesVisibility: true,
//                 iconWidth: 15,
//                 iconHeight: 15,
//                 padding: 12.w,
//                 // width: type != CategoryType.all ? "100%" : "60%",
//                 alignment: ChartAlignment.center,
//                 overflowMode: LegendItemOverflowMode.scroll,
//                 textStyle: TextStyle(
//                   color: ColorResources.themeTextColor(context),
//                   fontWeight: FontWeight.w600,
//                   fontSize: Dimensions.FONT_SIZE_SMALL,
//                   fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
//                 ),
//               ),
//               onLegendTapped: (legend) {
//                 // setState(() {});
//               },
//               onDataLabelTapped: (DataLabelTapDetails data) {},
//               series: <CircularSeries>[
//                 PieSeries<ChartData, String>(
//                   dataSource: chartData,
//                   legendIconType: LegendIconType.rectangle,
//                   onPointTap: (ChartPointDetails details) {
//                     if (details.pointIndex != null) {
//                       categoryScreenState.selectedLabel =
//                           chartData[details.pointIndex ?? -1].title ?? "";
//                       categoryScreenState.asaId =
//                           categoryScreenState.selectedLabel;
//                     }
//                     if (categoryScreenState
//                             .controller.position.maxScrollExtent >
//                         (MediaQuery.of(context).size.height - 250)) {
//                       if (categoryScreenState.selectedLabel.toLowerCase() ==
//                           "nft") {
//                         categoryScreenState.controller.animateTo(
//                           ((270.h) +
//                               ((categoryScreenState.asaModel.values?.length ??
//                                       0) *
//                                   57.h) +
//                               21.h), // Top padding + total asa padding + space
//                           duration: const Duration(seconds: 2),
//                           curve: Curves.fastOutSlowIn,
//                         );
//                         return;
//                       }
//                       categoryScreenState.controller.animateTo(
//                         (270.h) +
//                             ((details.pointIndex ?? 0) *
//                                 57.h), // Top padding + above total asa padding
//                         duration: const Duration(seconds: 2),
//                         curve: Curves.fastOutSlowIn,
//                       );
//                     }
//                   },
//                   pointColorMapper: (ChartData data, i) => data.color,
//                   xValueMapper: (ChartData data, _) => data.title,
//                   yValueMapper: (ChartData data, _) => data.y,
//                   animationDelay: 400,
//                   // Radius of pie
//                   radius: '100%',
//                 )
//               ],
//             ),
//     );
//   }
// }
