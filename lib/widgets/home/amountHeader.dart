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
    if (widget.type == CategoryType.all) {
      if (_asaProvider.getTotalWithoutNfts()) {
        // don't calculate nfts
        if (_appSettingProvider.currency == Currency.algo) {
          return "${getASAModel().total?.total?.toStringAsFixed(2) ?? 0} ALGO";
        } else {
          return "${getASAModel().total?.totalusdc?.toStringAsFixed(2) ?? 0} USD";
        }
      } else {
        // calculate nfts
        if (_appSettingProvider.currency == Currency.algo) {
          double total = (getASAModel().total?.total ?? 0) +
              (getASAModel().total?.nft ?? 0);
          return "${total.toStringAsFixed(2)} ALGO";
        } else {
          double totalAlgo = (getASAModel().total?.total ?? 0) +
              (getASAModel().total?.nft ?? 0);
          double priceUsdc = getASAModel().total?.priceusdc ?? 1;
          double totalUsd = totalAlgo / priceUsdc;
          return "${totalUsd.toStringAsFixed(2)} USD";
        }
      }
    } else if (widget.type == CategoryType.asa) {
      if (_appSettingProvider.currency == Currency.algo) {
        return "${getASAModel().total?.asa?.toStringAsFixed(2) ?? 0} ALGO";
      } else {
        double usdValue = ((getASAModel().total?.asa ?? 1) /
            (getASAModel().total?.priceusdc ?? 1));
        return "${usdValue.toStringAsFixed(2)} USD";
      }
    }

    return "";
  }

  String getOppositeAmount() {
    if (widget.type == CategoryType.all) {
      if (_appSettingProvider.currency != Currency.algo) {
        if (_asaProvider.getTotalWithoutNfts()) {
          double totalAlgo = getASAModel().total?.total ?? 0;
          double totalUsdc = getASAModel().total?.totalusdc ?? 0;
          double algoPerUsd = totalUsdc != 0 ? totalAlgo / totalUsdc : 0;
          String formattedAlgoPerUsd =
              AppConstants.formateNumber(algoPerUsd, points: "0000");
          return "${totalAlgo.toStringAsFixed(2)} ALGO ($formattedAlgoPerUsd ALGO/USD)";
        } else {
          double totalAlgo = (getASAModel().total?.total ?? 0) +
              (getASAModel().total?.nft ?? 0);
          double totalUsdc = (getASAModel().total?.totalusdc ?? 0) +
              ((getASAModel().total?.nft ?? 0) /
                  (getASAModel().total?.priceusdc ?? 1));
          double algoPerUsd = totalUsdc != 0 ? totalAlgo / totalUsdc : 0;
          String formattedAlgoPerUsd =
              AppConstants.formateNumber(algoPerUsd, points: "0000");
          return "${totalAlgo.toStringAsFixed(2)} ALGO ($formattedAlgoPerUsd ALGO/USD)";
        }
      } else {
        if (_asaProvider.getTotalWithoutNfts()) {
          double totalUsdc = getASAModel().total?.totalusdc ?? 0;
          double priceAlgo = getASAModel().total?.pricealgo ?? 0;
          String formattedPriceAlgo =
              AppConstants.formateNumber(priceAlgo, points: "0000");
          return "${totalUsdc.toStringAsFixed(2)} USD ($formattedPriceAlgo USD/ALGO)";
        } else {
          //currency algo, include nft evaluation
          double totalUsdc = (getASAModel().total?.totalusdc ?? 0) +
              ((getASAModel().total?.nft ?? 0) /
                  (getASAModel().total?.priceusdc ?? 1));
          double priceAlgo = getASAModel().total?.pricealgo ?? 0;
          String formattedPriceAlgo =
              AppConstants.formateNumber(priceAlgo, points: "0000");
          return "${totalUsdc.toStringAsFixed(2)} USD ($formattedPriceAlgo USD/ALGO)";
        }
      }
    } else if (widget.type == CategoryType.asa) {
      if (_appSettingProvider.currency != Currency.algo) {
        double totalAsa = getASAModel().total?.asa ?? 0;
        double priceAlgo =
            getASAModel().total?.pricealgo ?? 1; // evade zero division
        double algoPerUsd = 1 / priceAlgo;
        String formattedAlgoPerUsd =
            AppConstants.formateNumber(algoPerUsd, points: "0000");

        return "${totalAsa.toStringAsFixed(2)} ALGO ($formattedAlgoPerUsd ALGO/USD)";
      } else {
        double asa = (getASAModel().total?.asa ?? 1) /
            (getASAModel().total?.priceusdc ?? 1);
        double priceAlgo = getASAModel().total?.pricealgo ?? 0;
        String formattedPriceAlgo =
            AppConstants.formateNumber(priceAlgo, points: "0000");
        return "${asa.toStringAsFixed(2)} USD ($formattedPriceAlgo USD/ALGO)";
      }
    }

    return "";
  }

  ASAModel getASAModel() {
    return widget.isSingle
        ? _asaProvider.asaModelSingle
        : _asaProvider.asaModel;
  }
}
