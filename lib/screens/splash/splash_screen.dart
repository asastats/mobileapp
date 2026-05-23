import 'dart:async';

import 'package:asa_stats/config/images.dart';
import 'package:asa_stats/config/routes.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/utility/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late ASAProvider _asaProvider;
  bool _isInit = true;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (_isInit) {
      _asaProvider = Provider.of<ASAProvider>(context);
      // Phase 5c — settings endpoint migrated to v2 (``/api/v2/settings/``).
      // The payload shape is identical to v1, so the SharedPreferences key
      // (``AppConstants.GLOBAL_SETTING``) is unchanged and every downstream
      // reader of the persisted settings keeps working without changes.
      await _asaProvider.getGlobalSettingV2();
      Timer.periodic(const Duration(seconds: 3), (timer) {
        timer.cancel();
        Navigator.pushReplacementNamed(context, RouteList.MENU);
      });
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AdaptiveOrientation(
        portrait: PortraitSplashScreen(),
        landscape: LandscapeSplashScreen(),
      ),
    );
  }
}

class PortraitSplashScreen extends StatelessWidget {
  const PortraitSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            Images.TOP_RIGHT_VIEW,
            width: 95.w,
            height: 95.w,
            fit: BoxFit.fill,
          ),
        ),
        Align(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 68),
            child: Image.asset(
              Images.appLogo(context),
              height: 140.h,
              width: 238.w,
            ),
          ),
        )
      ],
    );
  }
}

class LandscapeSplashScreen extends StatelessWidget {
  const LandscapeSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            Images.TOP_RIGHT_VIEW,
            width: 95.w,
            height: 95.w,
            fit: BoxFit.fill,
          ),
        ),
        Align(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 68),
            child: Image.asset(
              Images.appLogo(context),
              height: 238.w,
              width: 140.w,
            ),
          ),
        )
      ],
    );
  }
}
