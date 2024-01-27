import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/main.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:asa_stats/widgets/app_bar.dart';
import 'package:asa_stats/widgets/theme_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.backgroundColor(context),
      appBar: ThemeAppBar.commonAppBar(
        context,
        height: 95,
        onMenuTap: () {
          drawerController.toggle?.call();
        },
        isMenu: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                vertical: Dimensions.PADDING_SIZE_15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "App settings",
                  style: TextStyle(
                    color: ColorResources.themeTextColor(context),
                    fontSize: Dimensions.FONT_SIZE_LARGE_18,
                    fontWeight: FontWeight.w600,
                    // fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<ThemeProvider>(builder: (context, theme, ___) {
                  return listTile("Dark theme", theme.darkTheme, (value) {
                    theme.toggleTheme();
                  });
                }),
                Consumer<ASAProvider>(builder: (context, provider, ___) {
                  return Column(
                    children: [
                      listTile("Auto refresh", provider.isAutoRefreshOn(),
                          (value) {
                        provider.setAutoRefresh(value);
                        setState(() {});
                      }),
                      listTile("Pie chart visibility",
                          provider.getPieChartVisibility(), (value) {
                        provider.setPieChartVisibility(value);
                        setState(() {});
                      }),
                      listTile(
                          "Home as startup page", provider.isAddressSaved(),
                          (value) {
                        provider.setHomeFirst(value);
                        setState(() {});
                      }),
                      listTile(
                          "Total without NFTs", provider.getTotalWithoutNfts(),
                          (value) {
                        provider.setTotalWithoutNfts(value);
                        setState(() {});
                      }),
                      clearAllListTile(
                          "Clear all autofill addresses", onClearAllAddress)
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget listTile(String title, bool value, Function(bool)? onChanged) {
    return Container(
      height: 50,
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 7),
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).darkTheme
            ? const Color(0xff373737)
            : ColorResources.whiteColor,
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_TEN),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(4, 4),
            color: ColorResources.blackColor.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: ColorResources.themeTextColor(context),
                fontSize: Dimensions.FONT_SIZE_15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget clearAllListTile(
    String title,
    Function()? onTap,
  ) {
    return Container(
      height: 50,
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).darkTheme
            ? const Color(0xff373737)
            : ColorResources.whiteColor,
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_TEN),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(4, 4),
            color: ColorResources.blackColor.withOpacity(0.05),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_TEN),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.PADDING_SIZE_SMALL),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: ColorResources.themeTextColor(context),
                      fontSize: Dimensions.FONT_SIZE_15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.PADDING_SIZE_SMALL),
                  child: SizedBox(
                    child: Icon(
                      Icons.delete,
                      size: 24,
                      color: ColorResources.redColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onClearAllAddress() {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_TEN),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            backgroundColor: ColorResources.backgroundColor(context),
            child: ThemeDeleteDialog(
              title: "All saved autofill addresses will be deleted. \nProceed?",
              icon: Images.IC_BIT_COIN,
              onTap: () async {
                Navigator.pop(context);
                await Provider.of<ASAProvider>(context, listen: false)
                    .clearAddress();
                ToastService.show("All addresses are cleared!");
              },
            ),
          );
        });
  }
}
