import 'package:fluttertoast/fluttertoast.dart';

import '../config/color.dart';
import '../config/dimensions.dart';

class ToastService {
  static show(
    String message, {
    toastLength = Toast.LENGTH_SHORT,
    gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      gravity: gravity,
      toastLength: toastLength,
      timeInSecForIosWeb: 1,
      backgroundColor: ColorResources.secondaryDarkBlackColor,
      textColor: ColorResources.secondaryWhiteColor,
      fontSize: Dimensions.FONT_SIZE_DEFAULT,
    );
  }

  static cancel() {
    Fluttertoast.cancel();
  }
}
