import 'dart:math';

import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/main.dart';
import 'package:asa_stats/providers/menu_provider.dart';
import 'package:asa_stats/widgets/app_bar.dart';
import 'package:asa_stats/widgets/buttons/theme_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/response/base/response_model.dart';
import '../../providers/asa_provider.dart';
import 'widget/address_field.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({Key? key}) : super(key: key);

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  //Controllers
  late TextEditingController addressController;

  final _formKey = GlobalKey<FormState>();
  final _random = Random();

  //provider
  late ASAProvider _asaProvider;
  late MenuProvider _menuProvider;

  bool isExpand = false;
  bool isMultipleAlgo = false;
  bool _isInit = true;
  String error = "";

  String slogan = " \n";

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(
        text: kDebugMode ? AppConstants.TEXT_ADDRESS : ""
        // : Provider.of<ASAProvider>(context, listen: false)
        //         .getAddress()
        //         .isNotEmpty
        //     ? Provider.of<ASAProvider>(context, listen: false).getAddress()
        // : ""
        );
    addressController.notifyListeners();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map data = {};
    if (_isInit) {
      _isInit = false;
      _asaProvider = Provider.of<ASAProvider>(context, listen: false);
      _menuProvider = Provider.of<MenuProvider>(context, listen: false);
      data = await AppConstants.readGlobalJsonFile(context);
      List<String> slogans = (data['slogans'] ?? []).cast<String>();
      if (slogans.isNotEmpty) {
        slogan = slogans[_random.nextInt(slogans.length)];
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: ColorResources.backgroundColor(context),
        body: SafeArea(
          top: false,
          left: false,
          right: false,
          child: Column(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            ((isExpand ? 125 : 25) + (error.isEmpty ? 0 : 25))),
                    child: ThemeAppBar.build(
                      context,
                      slogan: slogan,
                      height: (MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? 212
                          : 100),
                      onMenuTap: () {
                        drawerController.toggle?.call();
                      },
                    ),
                  ),
                  Positioned(
                      // top: (212 - 21).h,
                      bottom: 0,
                      left: Dimensions.PADDING_SIZE_DEFAULT +
                          MediaQuery.of(context).padding.left,
                      right: Dimensions.PADDING_SIZE_DEFAULT +
                          MediaQuery.of(context).padding.right,
                      child: SingleChildScrollView(
                        child: AddressField(
                          formKey: _formKey,
                          controller: addressController,
                          onExpand: (isExpand) {
                            this.isExpand = isExpand;
                            setState(() {});
                          },
                          onError: (error) {
                            this.error = error;
                            setState(() {});
                          },
                        ),
                      )),
                ],
              ),
              if (isMultipleAlgo) ...[
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        var val =
                            addressController.text.split("/")[0].isNotEmpty
                                ? addressController.text.split("/")[0]
                                : "name.algo";
                        addressController.text = "$val/ans";
                        setState(() {});
                      },
                      child: Image.asset(
                        "${Images.PROVIDER}${Images.ANS}",
                        height: 50,
                        width: 70,
                      ),
                    ),
                    SizedBox(
                      width: 10.w,
                    ),
                    GestureDetector(
                      onTap: () {
                        var val =
                            addressController.text.split("/")[0].isNotEmpty
                                ? addressController.text.split("/")[0]
                                : "name.algo";
                        addressController.text = "$val/nfd";
                        setState(() {});
                      },
                      child: Image.asset(
                        "${Images.PROVIDER}${Images.NFD}",
                        height: 50,
                        width: 70,
                      ),
                    )
                  ],
                ),
              ],
              Padding(
                padding: EdgeInsets.only(
                  left: Dimensions.PADDING_SIZE_DEFAULT +
                      MediaQuery.of(context).padding.left,
                  right: Dimensions.PADDING_SIZE_DEFAULT +
                      MediaQuery.of(context).padding.right,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 18.h),
                    Consumer<ASAProvider>(
                      builder: (context, value, child) {
                        return ThemeButton(
                          onTap: value.isLoading ? () {} : _whenMoon,
                          color: value.isLoading
                              ? ColorResources.greyDarkColor
                              : ColorResources.primaryColor,
                          title: "WHEN MOON",
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _whenMoon() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _formKey.currentState?.save();

    showEasyLoader(true);

    await _asaProvider.saveAddress(_asaProvider.address);
    // Phase 5c — address lookup migrated to V2. The V2 contract is
    // ``POST /api/v2/`` with ``{"addresses": "..."}`` (the provider's
    // ``getBundleHashV2`` wraps that for us; here we pass the raw value).
    // On success the provider unwraps the ``{"bundle": "..."}`` response
    // envelope to a bare hash string, then we feed that to
    // ``getEvaluatedAccountV2`` for the account fetch. The provider's
    // V2 fetch dual-populates ``_accountV2`` and ``_asaData`` via the
    // ``v2ToV1ASAModel`` shim, so unmigrated tab screens that still
    // read from ``asaModel`` continue to render correctly.
    ResponseModel responseAddress =
        await _asaProvider.getBundleHashV2(_asaProvider.address.toString());
    showEasyLoader(_asaProvider.isLoading);
    // ``Multiple:`` is a V1 backend-specific signal for "address belongs
    // to multiple bundles". V2 does not produce this message today, so
    // the branch below is effectively a no-op under V2; keep it in
    // place in case V2 ever grows a similar signal.
    if (responseAddress.message.startsWith("Multiple:")) {
      isMultipleAlgo = true;
      setState(() {});
    } else {
      if (responseAddress.isSuccess) {
        ResponseModel response =
            await _asaProvider.getEvaluatedAccountV2(responseAddress.data);
        isMultipleAlgo = false;
        if (response.isSuccess) {
          _menuProvider.setIndex(9);
        }
      } else {
        setState(() {});
      }
    }
  }

  showEasyLoader(
    bool isLoading,
  ) {
    if (isLoading) {
      EasyLoading.show(status: 'loading...');
    } else {
      if (EasyLoading.isShow) EasyLoading.dismiss();
    }
  }
}
