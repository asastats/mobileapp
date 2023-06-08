import 'package:asa_stats/utility/toast_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../config/images.dart';

class CopyText extends StatelessWidget {
  final String text;
  const CopyText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        ToastService.show("Copied!");
        await Clipboard.setData(ClipboardData(text: text));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text, //address
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: ColorResources.primaryColor,
              fontSize: Dimensions.FONT_SIZE_DEFAULT,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
            ),
          ),
          SizedBox(width: 5.w),
          Image.asset(
            Images.IC_COPY,
            height: 20,
            width: 20,
          ),
        ],
      ),
    );
  }
}
