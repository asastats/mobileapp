import 'package:flutter/material.dart';

List<Widget> listBuilder({
  required int itemCount,
  required Widget Function(int) builder,
}) {
  return List.generate(itemCount, (index) => builder(index));
}
