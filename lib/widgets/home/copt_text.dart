import 'package:asa_stats/utility/toast_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../config/images.dart';
import '../../screens/menu/menu_screen.dart';

class CopyText extends StatelessWidget {
  final String text;
  const CopyText({super.key, required this.text, this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: url != null
              ? () async {
                  await launchURLApp(url!);
                }
              : null,
          child: Text(
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
        ),
        SizedBox(width: 5.w),
        GestureDetector(
          onTap: () async {
            ToastService.show("Copied!");
            await Clipboard.setData(ClipboardData(text: text));
          },
          child: Image.asset(
            Images.IC_COPY,
            height: 20,
            width: 20,
          ),
        )
      ],
    );
  }
}
