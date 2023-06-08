import 'package:flutter/material.dart';

import '../config/color.dart';

class RefreshWidget extends StatelessWidget {
  final Future Function() onRefresh;
  final Widget child;

  const RefreshWidget({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ColorResources.primaryColor,
      backgroundColor: ColorResources.themeTextColorReverse(context),
      onRefresh: onRefresh,
      child: child,
    );
  }
}
