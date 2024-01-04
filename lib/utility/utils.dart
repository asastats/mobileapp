import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config/dimensions.dart';

String formateAmount(double amount, int decimal, int dNumber, {utit = ""}) {
  // dNumber parameter specifies how many digits to keep after the decimal point.

  String f = (amount / math.pow(10, decimal))
      .toString()
      .replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');

  String newf = "";
  if (f.contains(".") && f.split(".").length == 2) {
    newf += f.split(".")[0];
    if (f.split(".")[1].length > dNumber) {
      newf += ".";
      newf += f.split(".")[1].substring(0, dNumber);
    } else {
      newf += ".";
      newf += f.split(".")[1];
    }
  } else {
    newf = f;
  }
  return newf;
}

String formateDecimalNumber(double amount, int decimal) {
  String f = amount.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');

  String newf = "";
  if (f.contains(".") && f.split(".").length == 2) {
    newf += f.split(".")[0];
    if (f.split(".")[1].length > decimal) {
      newf += ".";
      newf += f.split(".")[1].substring(0, decimal);
    }
  } else {
    newf = f;
  }
  return newf;
}

int countCrossAxisNFT(context) {
  return ((MediaQuery.of(context).size.width -
          (29 +
              Dimensions.PADDING_SIZE_SMALL.w +
              (Dimensions.PADDING_SIZE_DEFAULT * 2) +
              30 +
              27 +
              100)) ~/
      40);
}
