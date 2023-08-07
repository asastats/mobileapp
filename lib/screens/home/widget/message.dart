import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum messageType { message, info }

class Message extends StatefulWidget {
  final messageType type;
  const Message({Key? key, required this.type}) : super(key: key);

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  late ASAProvider _asaProvider;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      _asaProvider = Provider.of<ASAProvider>(context, listen: false);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        widget.type == messageType.message
            ? _asaProvider.asaModel.warning ?? ""
            : _asaProvider.asaModel.information ?? "",
        maxLines: 2,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.type == messageType.message
              ? ColorResources.warningColor
              : ColorResources.infoColor,
          fontSize: Dimensions.FONT_SIZE_LARGE,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
