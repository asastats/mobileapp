import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AllowMultipleGestureRecognizer extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class MultipleGestureDetector extends StatelessWidget {
  final void Function()? onTap;
  final Widget child;
  const MultipleGestureDetector({
    Key? key,
    this.onTap,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            AllowMultipleGestureRecognizer>(
          () => AllowMultipleGestureRecognizer(),
          (AllowMultipleGestureRecognizer instance) {
            instance.onTap = onTap;
          },
        )
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
