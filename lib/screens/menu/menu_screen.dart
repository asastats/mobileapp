import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/config/styles.dart';
import 'package:asa_stats/main.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/providers/menu_provider.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:asa_stats/screens/address/address_screen.dart';
import 'package:asa_stats/screens/home/home_screen.dart';
import 'package:asa_stats/screens/settings/setting_screen.dart';
import 'package:asa_stats/screens/web_view/webview_screen.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/config.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  //Provider
  late MenuProvider _menuProvider;
  late ASAProvider _asaProvider;
  PackageInfo? packageInfo;

  bool _isInit = true;

  //Widget List
  final List<Widget> _widgetList = [
    const AddressScreen(),
    const WebViewScreen(
      url: AppConstants.ABOUT_URL,
      key: ValueKey(AppConstants.ABOUT_URL),
    ),
    const WebViewScreen(
        url: AppConstants.TOKENOMICS_URL,
        key: ValueKey(AppConstants.TOKENOMICS_URL)),
    const WebViewScreen(
      url: AppConstants.FAQ_URL,
      key: ValueKey(AppConstants.FAQ_URL),
    ),
    const WebViewScreen(
        url: AppConstants.DISCLAIMER_URL,
        key: ValueKey(AppConstants.DISCLAIMER_URL)),
    const WebViewScreen(
      url: AppConstants.BUY_ASA_URL,
      key: ValueKey(AppConstants.BUY_ASA_URL),
    ),
    const SettingScreen(),
    const HomeScreen()
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      _menuProvider = Provider.of<MenuProvider>(context, listen: false);
      _asaProvider = Provider.of<ASAProvider>(context);
      if (_asaProvider.isAddressSaved() &&
          _asaProvider.getAddress().isNotEmpty) {
        _menuProvider.setIndex(7);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_menuProvider.screenStack.isNotEmpty) {
          if (tabController?.index != 0 &&
              tabController?.index != null &&
              _menuProvider.selectedIndex == 7) {
            tabController?.animateTo(0);
          } else {
            _menuProvider.setIndex(_menuProvider.popInScreenStack(),
                save: false);
          }
          return false;
        }
        return true;
      },
      child: ZoomDrawer(
        controller: drawerController,
        borderRadius: 24,
        style: DrawerStyle.defaultStyle,
        openCurve: Curves.easeIn,
        slideWidth: MediaQuery.of(context).size.width * 0.7,
        duration: const Duration(milliseconds: 350),
        mainScreenTapClose: true,
        angle: 0.0,
        menuBackgroundColor: ColorResources.backgroundColor(context),
        mainScreen: Consumer<MenuProvider>(
          builder: (context, value, child) => Container(
            child: _widgetList[value.selectedIndex],
          ),
        ),
        menuScreenWidth: MediaQuery.of(context).size.width,
        androidCloseOnBackTap: true,
        menuScreen: Theme(
          data: Style.appTheme(context),
          child: const Menu(),
        ),
      ),
    );
  }
}

///
///  # Drawer Menu
///
class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final List<Map<String, dynamic>> menu = [
    {"image": Images.IC_STATE, "title": "Home"},
    {"image": Images.IC_ABOUT, "title": "About"},
    {"image": Images.IC_TOKENOMICS, "title": "Tokenomics"},
    {"image": Images.IC_FAQ, "title": "FAQ"},
    {"image": Images.IC_DISCLAIMER, "title": "Disclaimer"},
    {"image": Images.IC_BUY_ASA, "title": "Buy ASASTATS"},
    {"image": Images.IC_SETTING, "title": "Settings"},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Consumer<MenuProvider>(builder: (context, provider, s) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                height: (MediaQuery.of(context).orientation ==
                        Orientation.landscape)
                    ? 25
                    : 50),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.PADDING_SIZE_28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    height: 28,
                    width: 28,
                  ),
                  GestureDetector(
                      onTap: () => drawerController.toggle?.call(),
                      child: Image.asset(
                        Images.IC_CLOSE,
                        height: 28,
                        width: 28,
                      ))
                ],
              ),
            ),
            SizedBox(
                height: (MediaQuery.of(context).orientation ==
                        Orientation.landscape)
                    ? 15
                    : 60),
            Expanded(
              // flex: 9,
              child: Padding(
                padding: const EdgeInsets.only(right: 38),
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (notification) {
                    notification.disallowIndicator();
                    return true;
                  },
                  child: ListView.builder(
                    itemCount: menu.length,
                    padding: EdgeInsets.zero,
                    // shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (_, index) {
                      var item = menu[index];
                      return ListTile(
                          icon: item['image'],
                          title: item["title"],
                          isSelected: index == provider.selectedIndex,
                          onTap: () {
                            if (item['image'] == Images.IC_BUY_ASA) {
                              launchURLApp(AppConstants.BUY_ASA_URL);
                            } else {
                              drawerController.toggle?.call();
                              provider.setIndex(index);
                            }
                          });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
                height: (MediaQuery.of(context).orientation ==
                        Orientation.landscape)
                    ? 20
                    : 50),
            Consumer<ThemeProvider>(builder: (context, theme, s) {
              return Padding(
                padding: const EdgeInsets.only(left: 30),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * .7,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          theme.toggleTheme();
                        },
                        child: Tooltip(
                          message: theme.darkTheme ? "Dark" : "Light",
                          child: Container(
                            height: 31,
                            width: 31,
                            margin: const EdgeInsets.only(
                                right: Dimensions.PADDING_SIZE_SMALL),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(1),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: theme.darkTheme
                                            ? ColorResources.secondaryColor
                                            : ColorResources.greyDarkColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(100),
                                          bottomLeft: Radius.circular(100),
                                        )),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    transform:
                                        Matrix4.translationValues(-1, 0, 0),
                                    decoration: BoxDecoration(
                                      color: theme.darkTheme
                                          ? ColorResources.greyDarkColor
                                          : ColorResources.secondaryColor,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(100),
                                        bottomRight: Radius.circular(100),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      OptionButton(
                          icon: Images.IC_TWITTER,
                          isDarkTheme: theme.darkTheme,
                          index: 1,
                          onTap: () {
                            launchURLApp(AppConstants.TWITTER_URL);
                          }),
                      OptionButton(
                          icon: Images.IC_DISCORD,
                          isDarkTheme: theme.darkTheme,
                          index: 2,
                          onTap: () {
                            launchURLApp(AppConstants.DISCORD_URL);
                          }),
                      OptionButton(
                          icon: Images.IC_MONKEY,
                          isDarkTheme: theme.darkTheme,
                          index: 3,
                          onTap: () {
                            launchURLApp(AppConstants.REDDIT_URL);
                          }),
                      OptionButton(
                          icon: Images.IC_GITHUB,
                          isDarkTheme: theme.darkTheme,
                          index: 4,
                          onTap: () {
                            launchURLApp(AppConstants.GITHUB_URL);
                          }),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, AsyncSnapshot<PackageInfo> data) {
                  return Container(
                    width: MediaQuery.of(context).size.width * .7,
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      "Version" +
                          (data.connectionState == ConnectionState.waiting
                              ? "--"
                              : " ${data.data?.version}+${data.data?.buildNumber}"),
                      style: const TextStyle(
                        color: ColorResources.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: Dimensions.FONT_SIZE_DEFAULT,
                      ),
                    ),
                  );
                }),
            SizedBox(
                height: (MediaQuery.of(context).orientation ==
                        Orientation.landscape)
                    ? 20
                    : 60),
          ],
        );
      }),
    );
  }

  Widget listTile(
      BuildContext context, String icon, String title, bool isSelected,
      {required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        margin: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
        width: MediaQuery.of(context).size.width * 0.7,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorResources.primaryColor.withOpacity(isSelected ? .1 : 0),
              Colors.white.withOpacity(0)
            ],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 30,
            ),
            Image.asset(
              icon,
              width: 21,
              height: 20,
              color: isSelected
                  ? ColorResources.primaryColor
                  : ColorResources.textColor,
            ),
            const SizedBox(
              width: 18,
            ),
            Text(
              title,
              style: TextStyle(
                  color: isSelected
                      ? ColorResources.primaryColor
                      : ColorResources.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: Dimensions.FONT_SIZE_DEFAULT),
            )
          ],
        ),
      ),
    );
  }

  Widget buttonOptions(
      BuildContext context, String icon, bool isDarkTheme, int index,
      {required Function() onTap, bool showBG = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
        height: 31,
        width: 31,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    height: 31,
                    width: 31,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorResources.whiteColor,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Image.asset(
                  icon,
                  color: (index == 2 || index == 4)
                      ? ColorResources.secondaryColor
                      : null,
                  fit: BoxFit.fill,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ListTile extends StatelessWidget {
  final String icon;
  final String title;
  final bool isSelected;
  final Function() onTap;
  const ListTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        margin: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
        width: MediaQuery.of(context).size.width * 0.7,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorResources.primaryColor.withOpacity(isSelected ? .1 : 0),
              Colors.white.withOpacity(0)
            ],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 30,
            ),
            Image.asset(
              icon,
              width: 21,
              height: 20,
              color: isSelected
                  ? ColorResources.primaryColor
                  : ColorResources.textColor,
            ),
            const SizedBox(
              width: 18,
            ),
            Text(
              title,
              style: TextStyle(
                  color: isSelected
                      ? ColorResources.primaryColor
                      : ColorResources.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: Dimensions.FONT_SIZE_DEFAULT),
            )
          ],
        ),
      ),
    );
    ;
  }
}

class OptionButton extends StatelessWidget {
  final String icon;
  final bool isDarkTheme;
  final int index;
  final Function() onTap;
  bool? showBG = true;
  OptionButton({
    Key? key,
    required this.icon,
    required this.isDarkTheme,
    required this.index,
    required this.onTap,
    this.showBG,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
        height: 31,
        width: 31,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    height: 31,
                    width: 31,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorResources.whiteColor,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Image.asset(
                  icon,
                  color: (index == 2 || index == 4)
                      ? ColorResources.secondaryColor
                      : null,
                  fit: BoxFit.fill,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future launchURLApp(String urlString) async {
  // if(await canLaunchUrl(url??Uri())) await launchUrl(url??Uri(),mode: LaunchMode.externalApplication);
  var url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    ToastService.show('Could not launch $url');
  }
}
