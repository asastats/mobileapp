import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/providers/menu_provider.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_zoom_drawer/config.dart';
//? SystemChrome
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:asa_stats/providers/asa_provider.dart';

import 'config/routes.dart';
import 'config/styles.dart';
import './config/di_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // status bar and navigation bar color
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await di.init();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<ASAProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<MenuProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AppSettingProvider>()),
      ],
      child: const MyApp(),
    ),
  );
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.light
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.transparent
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

final ZoomDrawerController drawerController = ZoomDrawerController();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(Style.systemUiOverlayStyle(context));
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, Widget? child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.APP_NAME,
        theme: Style.appTheme(context),
        builder: EasyLoading.init(),
        navigatorKey: navigatorKey,
        routes: Routes.getAll(),
      ),
    );
  }
}
