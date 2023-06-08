// Routes
// ignore_for_file: constant_identifier_names

import 'package:asa_stats/screens/address/address_screen.dart';
import 'package:asa_stats/screens/home/home_screen.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:asa_stats/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState>? navigatorKey = GlobalKey<NavigatorState>();

class RouteList {
  static const String INITIAL = "/";
  static const String MENU = "/menu";
  static const String ADDRESS = "/address";
  static const String SPLASH_SCREEN = "/splash_screen";
  static const String HOME_SCREEN = "/home_screen";
}

class Routes {
  static Map<String, WidgetBuilder> getAll() => _routes;

  static final Map<String, WidgetBuilder> _routes = {
    "/": (ctx) => const SplashScreen(),
    RouteList.ADDRESS: (context) => const AddressScreen(),
    RouteList.HOME_SCREEN: (context) => const HomeScreen(),
    RouteList.MENU: (context) => const MenuScreen()
  };

  static Route getRouteGenerate(RouteSettings settings) {
    // var routingData = settings.arguments;

    switch (settings.name) {
      case RouteList.ADDRESS:
        return _buildRoute(settings, (_) => Container());
      default:
        return _errorRoute("Ops! Page Not found!");
    }
  }

  static MaterialPageRoute _buildRoute(
      RouteSettings settings, WidgetBuilder builder,
      {bool fullScreenDialog = false}) {
    return MaterialPageRoute(
      settings: settings,
      builder: builder,
      fullscreenDialog: fullScreenDialog,
    );
  }

  static Route _errorRoute([String message = 'Page not founds']) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(message),
        ),
      );
    });
  }
}
