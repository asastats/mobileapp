import 'dart:developer';

import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/main.dart';
import 'package:asa_stats/widgets/app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController _controller;
  late ThemeProvider _themeProvider;
  bool _isInit = true;
  bool _isLoading = true;
  double progress = 0;

  late String url;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      url = widget.url + (_themeProvider.darkTheme ? "?dark=1" : "");
      _themeProvider.addListener(() {
        url = widget.url + (_themeProvider.darkTheme ? "?dark=1" : "");
        try {
          WebUri webUri = WebUri(url);
          _controller.loadUrl(urlRequest: URLRequest(url: webUri));
        } on Exception catch (e) {
          log("$runtimeType didChangeDependencies error", error: e);
        }
      });
    }
    _isInit = false;
  }

  @override
  void dispose() {
    super.dispose();
    showEasyLoader(false);
  }

  InAppWebViewSettings inAPPWebOption = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: true,
    useOnDownloadStart: true,
    supportZoom: false,
    javaScriptEnabled: true,
    cacheEnabled: true,
    // userAgent: AppConstants.USER_AGENT,
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: true,
    preferredContentMode: UserPreferredContentMode.MOBILE,
    transparentBackground: false,
    useHybridComposition: true,
    thirdPartyCookiesEnabled: true,
    allowFileAccess: true,
    geolocationEnabled: true,
    domStorageEnabled: true,
    allowsInlineMediaPlayback: true,
    allowsPictureInPictureMediaPlayback: true,
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return Future.value(false);
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: ColorResources.themeDataBgColor(context),
        appBar: ThemeAppBar.commonAppBar(context,
            topPadding: 40,
            height: MediaQuery.of(context).orientation == Orientation.portrait
                ? 75
                : 185, onMenuTap: () {
          showEasyLoader(false);
          drawerController.toggle?.call();
        }, isMenu: true),
        body: InAppWebView(
          gestureRecognizers: Set()
            ..add(Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer())),
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: inAPPWebOption,
          onWebViewCreated: (controller) async {
            _controller = controller;
            setState(() {
              _isLoading = true;
            });
            showEasyLoader(_isLoading);
          },
          onDownloadStartRequest: (controller, downloadStartRequest) async {
            if (await canLaunchUrl(downloadStartRequest.url)) {
              await launchUrl(downloadStartRequest.url);
            } else {
              log('Could not launch ${downloadStartRequest.url}');
            }
          },
          onLoadStart: (controller, url) {
            setState(() {
              _isLoading = true;
            });
            showEasyLoader(_isLoading);
          },
          onLoadStop: (controller, url) async {
            setState(() {
              _isLoading = false;
            });
            showEasyLoader(_isLoading);

            controller.evaluateJavascript(
                source:
                    "document.getElementsByClassName('z-depth-0')[0].remove();");
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;
            if (![
              "http",
              "https",
              "file",
              "chrome",
              "data",
              "javascript",
              "about"
            ].contains(uri.scheme)) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
                return NavigationActionPolicy.CANCEL;
              }
            }
            return NavigationActionPolicy.ALLOW;
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
        ),
      ),
    );
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
