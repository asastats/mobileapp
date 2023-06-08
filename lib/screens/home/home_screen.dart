import 'dart:convert';
import 'dart:developer';

import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/main.dart';
import 'package:asa_stats/models/response/asa_model.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/providers/menu_provider.dart';
import 'package:asa_stats/screens/home/show_all_screen.dart';
import 'package:asa_stats/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/response/nftValues.dart';
import 'asa_screen.dart';
import 'nft_screen.dart';

TabController? tabController;

class HomeScreen extends StatefulWidget {
  final bool isSingleAddress;
  const HomeScreen({
    Key? key,
    this.isSingleAddress = false,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isSingleAddress = false;
  late MenuProvider _menuProvider;
  late ASAProvider _asaProvider;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    initController();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (_isInit) {
      _asaProvider = Provider.of<ASAProvider>(context, listen: false);
      _menuProvider = Provider.of<MenuProvider>(context, listen: false);
      // preCacheImages(_asaProvider.asaModel.nftValues ?? []);
      _isInit = false;
    }
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    isSingleAddress = widget.isSingleAddress;
    // var argument = ModalRoute.of(context)?.settings.arguments;
    // if (argument != null) {
    //   argument as Map<String, dynamic>;
    //   if (argument.isNotEmpty) {
    //  isSingleAddress = widget.isSingleAddress;
    //     // preCacheImages(_asaProvider.asaModel.nftValues ?? []);
    //   }
    // } else {
    //   isSingleAddress = false;
    // }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.backgroundColor(context),
      appBar: ThemeAppBar.commonAppBar(context,
          topPadding: 40,
          isMenu: !isSingleAddress,
          height: MediaQuery.of(context).orientation == Orientation.portrait
              ? 75
              : 185, onMenuTap: () {
        if (isSingleAddress) {
          Navigator.pop(context);
        } else {
          drawerController.toggle!();
        }
      }),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 1,
                transform: Matrix4.translationValues(0, 48, 0),
                width: double.maxFinite,
                color: ColorResources.borderColor,
              ),
              TabBar(
                controller: tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft:
                          Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT.w),
                      topRight:
                          Radius.circular(Dimensions.RADIUS_SIZE_DEFAULT.w)),
                  color: ColorResources.primaryColor,
                ),
                indicatorColor: ColorResources.primaryColor,
                indicatorPadding: const EdgeInsets.only(top: 44),
                unselectedLabelColor: ColorResources.themeTextColor(context),
                labelColor: ColorResources.primaryColor,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                ),
                indicatorWeight: 3,
                tabs: const [
                  Label(title: "Show All"),
                  Label(title: "ASA"),
                  Label(title: "NFT"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    ShowAllScreen(
                      key: const ValueKey("all"),
                      type: CategoryType.all,
                      isSingleAddress: isSingleAddress,
                      homeScreenState: this,
                    ),
                    AsaScreen(
                      key: const ValueKey("asa"),
                      type: CategoryType.asa,
                      isSingleAddress: isSingleAddress,
                      homeScreenState: this,
                    ),
                    NftScreen(
                      key: const ValueKey("nft"),
                      isSingleAddress: isSingleAddress,
                      homeScreenState: this,
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<ASAModel> readJsonFile(String filePath) async {
    final String response = await rootBundle.loadString(filePath);
    var map = jsonDecode(response);
    return ASAModel.fromJson(map);
  }

  void initController() {
    tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        setState(() {});
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
          await precacheImage(image.image, context, size: const Size(156, 156),
              onError: (o, s) {
            log("pre caching error", stackTrace: s, name: "Error", error: o);
          }).then((value) =>
              log("Caches image ${n.nft?.path ?? ""}", name: "Caching info"));
        }
      }
    }
    _asaProvider.isCaching = false;
    _asaProvider.notifyListeners();
    setState(() {});
    providers.forEach((key, value) {
      _asaProvider.imageProviders[key] = value;
    });
    debugPrint("Pre caching done");
  }
}

class Label extends StatelessWidget {
  final String title;
  const Label({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 45,
      child: Text(
        title,
        textAlign: TextAlign.center,
      ),
    );
  }
}
