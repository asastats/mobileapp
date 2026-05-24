// Phase 5c — totals header migrated to V2.
//
// V2 semantics for ``total.*`` are inverted from V1:
//   - V1 ``total.total`` meant "ASA + ALGO" (excluding NFT). To include
//     NFT the v1 code added ``total.nft`` on top.
//   - V2 ``total.total`` is the all-inclusive sum. The V2 backend also
//     exposes ``total.totalwonft`` directly for the "exclude NFTs"
//     toggle.
//
// The old v1 widget added ``total.nft`` to ``total.total`` in the
// "include NFTs" branch, which under V2 double-counts NFTs (the bug
// surfaced in user testing as a 2522.87 ALGO total instead of 1459.04).
// This rewrite uses V2 directly via the provider's ``accountV2`` /
// ``accountV2Single`` slots — same data ASAProvider populates from the
// v2 fetch, no shim involved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../config/enums.dart';
import '../../data/repository/app_setting_repo.dart';
import '../../models/v2/v2.dart' as v2;
import '../../providers/app_setting_provider.dart';
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
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SIZE_SMALL),
      ),
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

  // # Total resolution ----------------------------------------------------

  /// Source of truth for this widget's totals. V2 ``EvaluatedAccount``
  /// from the provider — same instance every other migrated screen reads.
  v2.EvaluatedAccount _account() {
    return widget.isSingle
        ? (_asaProvider.accountV2Single ?? v2.EvaluatedAccount())
        : _asaProvider.accountV2;
  }

  bool get _isAlgo => _appSettingProvider.currency == Currency.algo;

  /// Total amount in ALGO. Switches between full total and total-without-
  /// NFT based on the user's "total without NFTs" setting. The V2 backend
  /// gives us both directly — no client arithmetic.
  double _totalAlgo() {
    final total = _account().total;
    if (total == null) return 0;
    return _asaProvider.getTotalWithoutNfts()
        ? (total.totalwonft ?? 0.0)
        : (total.total ?? 0.0);
  }

  /// Same as [_totalAlgo] but for USD. V2 also exposes ``totalwonftusdc``,
  /// so we don't divide ourselves.
  double _totalUsd() {
    final total = _account().total;
    if (total == null) return 0;
    return _asaProvider.getTotalWithoutNfts()
        ? (total.totalwonftusdc ?? 0.0)
        : (total.totalusdc ?? 0.0);
  }

  // # The visible "big number" -------------------------------------------

  String getAmount() {
    switch (widget.type) {
      case CategoryType.all:
        return _isAlgo
            ? '${_totalAlgo().toStringAsFixed(2)} ALGO'
            : '${_totalUsd().toStringAsFixed(2)} USD';

      case CategoryType.asa:
        final asa = _account().total?.asa ?? 0.0;
        if (_isAlgo) return '${asa.toStringAsFixed(2)} ALGO';
        final priceusdc = _account().total?.priceusdc ?? 1.0;
        return '${(asa / priceusdc).toStringAsFixed(2)} USD';

      case CategoryType.nft:
        final nft = _account().total?.nft ?? 0.0;
        if (_isAlgo) return '${nft.toStringAsFixed(2)} ALGO';
        final priceusdc = _account().total?.priceusdc ?? 1.0;
        return '${(nft / priceusdc).toStringAsFixed(2)} USD';
    }
    return '';
  }

  // # The tooltip's opposite-currency row --------------------------------

  String getOppositeAmount() {
    switch (widget.type) {
      case CategoryType.all:
        if (_isAlgo) {
          final usd = _totalUsd();
          final priceAlgo = _account().total?.pricealgo ?? 0.0;
          final fmt = AppConstants.formateNumber(priceAlgo, points: '0000');
          return '${usd.toStringAsFixed(2)} USD ($fmt USD/ALGO)';
        } else {
          final algo = _totalAlgo();
          final usd = _totalUsd();
          // ``0.0`` (not ``0``) on the else branch so the ternary stays
          // ``double`` not ``num`` — ``formateNumber`` takes ``double``.
          final algoPerUsd = usd != 0 ? algo / usd : 0.0;
          final fmt = AppConstants.formateNumber(algoPerUsd, points: '0000');
          return '${algo.toStringAsFixed(2)} ALGO ($fmt ALGO/USD)';
        }

      case CategoryType.asa:
        final asa = _account().total?.asa ?? 0.0;
        final priceusdc = _account().total?.priceusdc ?? 1.0;
        if (_isAlgo) {
          final usd = asa / priceusdc;
          final priceAlgo = _account().total?.pricealgo ?? 0.0;
          final fmt = AppConstants.formateNumber(priceAlgo, points: '0000');
          return '${usd.toStringAsFixed(2)} USD ($fmt USD/ALGO)';
        } else {
          final priceAlgo = _account().total?.pricealgo == 0
              ? 1.0
              : (_account().total?.pricealgo ?? 1.0);
          final algoPerUsd = 1.0 / priceAlgo;
          final fmt = AppConstants.formateNumber(algoPerUsd, points: '0000');
          return '${asa.toStringAsFixed(2)} ALGO ($fmt ALGO/USD)';
        }

      case CategoryType.nft:
        final nft = _account().total?.nft ?? 0.0;
        final priceusdc = _account().total?.priceusdc ?? 1.0;
        if (_isAlgo) {
          final usd = nft / priceusdc;
          final priceAlgo = _account().total?.pricealgo ?? 0.0;
          final fmt = AppConstants.formateNumber(priceAlgo, points: '0000');
          return '${usd.toStringAsFixed(2)} USD ($fmt USD/ALGO)';
        } else {
          final priceAlgo = _account().total?.pricealgo == 0
              ? 1.0
              : (_account().total?.pricealgo ?? 1.0);
          final algoPerUsd = 1.0 / priceAlgo;
          final fmt = AppConstants.formateNumber(algoPerUsd, points: '0000');
          return '${nft.toStringAsFixed(2)} ALGO ($fmt ALGO/USD)';
        }
    }
    return '';
  }
}
