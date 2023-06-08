import 'package:flutter/material.dart';

class ErrorImage extends StatelessWidget {
  final double height;
  final double width;
  final String text;
  const ErrorImage({
    Key? key,
    required this.height,
    this.text = "NFT",
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
    );
  }
}
