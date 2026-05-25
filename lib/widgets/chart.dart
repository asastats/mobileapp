import 'dart:async';
import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/models/body/chart_data_model.dart';
import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/providers/asa_provider.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class Chart extends StatefulWidget {
  final List<ChartData> chartData;
  final CategoryType type;
  final dynamic categoryScreenState;
  final ScrollController? scrollController;
  final double? paddingTop;
  final bool enableScrollOnSectionTap;

  const Chart({
    super.key,
    required this.chartData,
    required this.type,
    required this.categoryScreenState,
    this.scrollController,
    this.paddingTop,
    this.enableScrollOnSectionTap = true,
  });

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  Timer? _touchTimer;
  int? _lastTouchedIndex;
  // ignore: unused_field
  DateTime? _tapDownTime;

  late List<bool> _isVisible;

  @override
  void initState() {
    super.initState();
    _isVisible = List<bool>.filled(widget.chartData.length, true);
  }

  @override
  void didUpdateWidget(covariant Chart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chartData.length != oldWidget.chartData.length) {
      _isVisible = List<bool>.filled(widget.chartData.length, true);
    }
  }

  void _startTouchTimer(BuildContext context, String label, int index) {
    _touchTimer?.cancel();
    _touchTimer = Timer(const Duration(milliseconds: 500), () {
      _showTooltip(
          context, label, widget.chartData[index].y?.toStringAsFixed(2));
      _touchTimer = null;
    });
  }

  void _cancelTouchTimerAndScroll(
      BuildContext context, String label, int index) {
    if (_touchTimer != null && _touchTimer!.isActive) {
      _touchTimer!.cancel();
      _touchTimer = null;
      if (widget.enableScrollOnSectionTap) {
        _handleSectionSelected(context, label, index);
      }
    }
    _lastTouchedIndex = null;
  }

  void _handleSectionSelected(BuildContext context, String label, int index) {
    final parentScreenState = widget.categoryScreenState;
    String selectedAssetId = label;
    // Phase 5d — resolve the tapped pie segment to an asset/collection
    // id by scanning the V2 ``accountV2`` lists. The chart's segments
    // are labeled with the asset's unit (asa) or the collection name
    // (nft); the screen needs the asset id (asa) or the name string
    // (nft) to set up the row scroll target.
    final accountV2 = parentScreenState.accountV2;
    if (widget.type == CategoryType.asa) {
      for (final item in accountV2.asaitems) {
        if (item.asset?.unit == label) {
          selectedAssetId = item.asset?.id?.toString() ?? label;
          break;
        }
      }
    } else if (widget.type == CategoryType.nft) {
      for (final coll in accountV2.nftcollections) {
        if (coll.name == label) {
          selectedAssetId = coll.name.toString();
          break;
        }
      }
    }
    parentScreenState.selectedLabel = label;
    parentScreenState.asaId = selectedAssetId;
    if (parentScreenState is State) {
      parentScreenState.setState(() {});
    }
    try {
      parentScreenState.onListItemTap(index, animate: true);
    } catch (_) {
      final ScrollController sc =
          widget.scrollController ?? parentScreenState.controller;
      sc.animateTo((140.h) + (index * 57.h),
          duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
    }
  }

  void _showTooltip(BuildContext context, String? title, String? percentage) {
    ToastService.show('$title $percentage %', gravity: ToastGravity.BOTTOM);
  }

  Widget _buildPieChart(
      double pieChartWidth, double containerHeight, double pieChartRadius) {
    final List<int> visibleIndexes = [];
    final List<PieChartSectionData> visibleSections = [];
    for (int i = 0; i < widget.chartData.length; i++) {
      if (_isVisible[i]) {
        visibleIndexes.add(i);
        final data = widget.chartData[i];
        visibleSections.add(
          PieChartSectionData(
            color: data.color,
            value: data.y ?? 0,
            showTitle: false,
            radius: pieChartRadius,
          ),
        );
      }
    }

    return SizedBox(
      width: pieChartWidth,
      height: containerHeight,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: visibleSections,
              centerSpaceRadius: 0,
              sectionsSpace: 0,
              borderData: FlBorderData(show: false),
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? touchResponse) {
                  if (touchResponse != null &&
                      touchResponse.touchedSection != null) {
                    final int touchedIndex =
                        touchResponse.touchedSection!.touchedSectionIndex;
                    if (touchedIndex >= 0 &&
                        touchedIndex < visibleIndexes.length) {
                      _lastTouchedIndex = visibleIndexes[touchedIndex];
                    }
                  }
                },
              ),
            ),
            duration: const Duration(milliseconds: 400),
          ),
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _tapDownTime = DateTime.now();
              Future.delayed(const Duration(milliseconds: 10), () {
                if (_lastTouchedIndex != null) {
                  final int index = _lastTouchedIndex!;
                  final String label = widget.chartData[index].title ?? "";
                  _startTouchTimer(context, label, index);
                }
              });
            },
            onPointerUp: (event) {
              if (_lastTouchedIndex != null) {
                final int index = _lastTouchedIndex!;
                final String label = widget.chartData[index].title ?? "";
                _cancelTouchTimerAndScroll(context, label, index);
              }
            },
            onPointerCancel: (event) {
              _touchTimer?.cancel();
              _touchTimer = null;
              _lastTouchedIndex = null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: widget.chartData.length,
          itemBuilder: (context, index) {
            final String label = widget.chartData[index].title ?? "";
            return GestureDetector(
              onLongPress: () {
                _showTooltip(context, label,
                    widget.chartData[index].y?.toStringAsFixed(2));
              },
              onTap: () {
                setState(() {
                  _isVisible[index] = !_isVisible[index];
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 15,
                      height: 15,
                      color: widget.chartData[index].color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: ColorResources.themeTextColor(context),
                          decoration: _isVisible[index]
                              ? TextDecoration.none
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSumLabel(
      BuildContext context, AppSettingProvider appSettingProvider) {
    // Phase 5c-fixes — read from the screen's ``accountV2`` (V2
    // ``EvaluatedAccount``) instead of the v1 ``asaModel``. The v1
    // path computed "include NFTs total" as ``total.total + total.nft``
    // because v1 ``total.total`` excluded NFT; under V2 ``total.total``
    // already includes NFT, so the old arithmetic double-counts.
    //
    // We still access via ``widget.categoryScreenState`` (dynamic) since
    // each screen class exposes ``accountV2`` as a field. Same access
    // pattern as the existing ``.asaModel`` read; nothing to change at
    // the call sites.
    final accountV2 = widget.categoryScreenState.accountV2;
    final priceusdc = accountV2.total?.priceusdc ?? 1.0;
    final bool isUsd = appSettingProvider.currency == Currency.usd;

    double totalSum = 0;
    double visibleSum = 0;
    for (int i = 0; i < widget.chartData.length; i++) {
      final y = widget.chartData[i].y ?? 0;
      totalSum += y;
      if (_isVisible[i]) {
        visibleSum += y;
      }
    }

    double visibleAlgo;
    if (widget.type == CategoryType.asa) {
      final double base = accountV2.total?.asa ?? 0.0;
      visibleAlgo = totalSum > 0 ? (visibleSum / totalSum) * base : 0.0;
    } else if (widget.type == CategoryType.nft) {
      final double base = accountV2.total?.nft ?? 0.0;
      visibleAlgo = totalSum > 0 ? (visibleSum / totalSum) * base : 0.0;
    } else {
      // Ratio chart has 3 items: ["ALGO", "ASA", "NFT"] as % of full total.
      // Each item's real ALGO value = (item.y / totalSum) * fullTotal,
      // where ``fullTotal`` is the all-inclusive ``total.total`` under
      // V2 (was ``total.total + total.nft`` under V1's stripped-NFT
      // semantics). When the user has the "exclude NFTs" toggle on,
      // V2 also gives us ``total.totalwonft`` directly — no client-side
      // arithmetic and no segment-skipping math.
      final asaProvider = Provider.of<ASAProvider>(context, listen: false);
      final excludeNfts = asaProvider.getTotalWithoutNfts();
      final double base = excludeNfts
          ? (accountV2.total?.totalwonft ?? 0.0)
          : (accountV2.total?.total ?? 0.0);

      double effectiveVisibleSum = 0;
      for (int i = 0; i < widget.chartData.length; i++) {
        if (_isVisible[i]) {
          // When excludeNfts is on, the NFT segment shouldn't contribute
          // to the displayed total even if its checkbox is still on.
          if (excludeNfts && widget.chartData[i].title == 'NFT') continue;
          effectiveVisibleSum += widget.chartData[i].y ?? 0;
        }
      }

      // ``effectiveVisibleSum`` is in the same scale as ``totalSum``
      // (both sum the y-values of segments). When excludeNfts is on,
      // we also need to subtract the NFT segment's y from totalSum so
      // the ratio reflects "visible portion of the non-NFT total".
      double effectiveTotalSum = totalSum;
      if (excludeNfts) {
        for (int i = 0; i < widget.chartData.length; i++) {
          if (widget.chartData[i].title == 'NFT') {
            effectiveTotalSum -= widget.chartData[i].y ?? 0;
            break;
          }
        }
      }
      visibleAlgo = effectiveTotalSum > 0
          ? (effectiveVisibleSum / effectiveTotalSum) * base
          : 0.0;
    }

    final double displayValue = isUsd ? visibleAlgo / priceusdc : visibleAlgo;
    final String suffix = isUsd ? 'USD' : 'ALGO';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${displayValue.toStringAsFixed(2)} $suffix',
        style: TextStyle(
          color: ColorResources.themeTextColor(context),
          fontSize: Dimensions.FONT_SIZE_LARGE_18,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettingProvider = Provider.of<AppSettingProvider>(context);

    return LayoutBuilder(builder: (context, constraints) {
      final double containerHeight =
          constraints.hasBoundedHeight ? constraints.maxHeight : 200;
      final double totalWidth = constraints.maxWidth;

      // Define proportions.
      final double legendWidth = totalWidth * 0.3;
      final double spacerWidth = totalWidth * 0.1;
      final double pieChartWidth = totalWidth * 0.6;

      final double rowHeight = containerHeight - 25;

      // Compute pie chart radius.
      final double pieChartRadius = (pieChartWidth / 2) * 0.9;

      return Padding(
        padding: EdgeInsets.only(top: widget.paddingTop ?? 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: legendWidth,
                    height: rowHeight,
                    child: _buildLegend(context),
                  ),
                  SizedBox(width: spacerWidth),
                  _buildPieChart(pieChartWidth, rowHeight, pieChartRadius),
                ],
              ),
            ),
            _buildSumLabel(context, appSettingProvider),
          ],
        ),
      );
    });
  }
}
