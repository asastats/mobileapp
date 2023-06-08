import 'package:flutter/material.dart';

class AdaptiveOrientation extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;
  const AdaptiveOrientation({
    Key? key,
    required this.portrait,
    required this.landscape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return portrait;
        } else {
          return landscape;
        }
      },
    );
  }
}
