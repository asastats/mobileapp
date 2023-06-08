import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../config/enums.dart';
import '../../data/repository/app_setting_repo.dart';
import '../../models/response/asa_model.dart';
import '../../providers/asa_provider.dart';

class AmountHeader extends StatefulWidget {
  final CategoryType type;
  final bool isSingle;
  const AmountHeader({
    Key? key,
    required this.type,
    required this.isSingle,
  }) : super(key: key);

  @override
  State<AmountHeader> createState() => _AmountHeaderState();
}

class _AmountHeaderState extends State<AmountHeader> {
  bool _isInit = true;

  late AppSettingProvider _appSettingProvider;
  late ASAProvider _asaProvider;
  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      _appSettingProvider = Provider.of<AppSettingProvider>(context);
      _asaProvider = Provider.of<ASAProvider>(context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: getOppositeAmount(),
      showDuration: const Duration(seconds: 5),
      decoration: BoxDecoration(
          color: ColorResources.secondaryColor,
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_SMALL)),
      triggerMode: TooltipTriggerMode.tap,
      child: Text(
        getAmount(),
        style: TextStyle(
          color: ColorResources.themeTextColor(context),
          fontSize: Dimensions.FONT_SIZE_MAX_26,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String getAmount() {
    return widget.type == CategoryType.all
        ? _appSettingProvider.currency == Currency.algo
            ? "${getASAModel().total?.total?.toStringAsFixed(2) ?? 0} ALGO"
            : "${getASAModel().total?.totalusdc?.toStringAsFixed(2) ?? 0} USD"
        : widget.type == CategoryType.asa
            ? _appSettingProvider.currency == Currency.algo
                ? "${getASAModel().total?.asa?.toStringAsFixed(2) ?? 0} ALGO"
                : "${((getASAModel().total?.asa ?? 1) / (getASAModel().total?.priceusdc ?? 1)).toStringAsFixed(2)} USD"
            : "";
  }

  String getOppositeAmount() {
    return widget.type == CategoryType.all
        ? _appSettingProvider.currency != Currency.algo
            ? "${getASAModel().total?.total?.toStringAsFixed(2) ?? 0} ALGO (${AppConstants.formateNumber((getASAModel().total?.total ?? 0) / (getASAModel().total?.totalusdc ?? 0), points: "0000")} ALGO/USD)"
            : "${getASAModel().total?.totalusdc?.toStringAsFixed(2) ?? 0} USD (${AppConstants.formateNumber((getASAModel().total?.totalusdc ?? 0) / (getASAModel().total?.total ?? 0), points: "0000")} USD/ALGO)"
        : widget.type == CategoryType.asa
            ? _appSettingProvider.currency != Currency.algo
                ? "${getASAModel().total?.asa?.toStringAsFixed(2) ?? 0} ALGO (${AppConstants.formateNumber((getASAModel().total?.asa ?? 0) / (getASAModel().total?.totalusdc ?? 0), points: "0000")} ALGO/USD)"
                : "${((getASAModel().total?.asa ?? 1) / (getASAModel().total?.priceusdc ?? 1)).toStringAsFixed(2)} USD (${AppConstants.formateNumber((getASAModel().total?.totalusdc ?? 0) / (getASAModel().total?.asa ?? 0), points: "0000")} USD/ALGO)"
            : "";
  }

  ASAModel getASAModel() {
    return widget.isSingle
        ? _asaProvider.asaModelSingle
        : _asaProvider.asaModel;
  }
}
