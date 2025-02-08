import 'dart:async';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/models/body/chart_data_model.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Chart extends StatefulWidget {
  final List<ChartData> chartData;
  final CategoryType type;
  final dynamic categoryScreenState;
  final ScrollController? scrollController;
  final double? paddingTop;

  const Chart({
    super.key,
    required this.chartData,
    required this.type,
    required this.categoryScreenState,
    this.scrollController,
    this.paddingTop,
  });

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  Timer? _touchTimer;
  int? _lastTouchedIndex;
  // ignore: unused_field
  DateTime? _tapDownTime;

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
      _handleSectionSelected(context, label, index);
    }
    _lastTouchedIndex = null;
  }

  void _handleSectionSelected(BuildContext context, String label, int index) {
    widget.categoryScreenState.selectedLabel = label;
    widget.categoryScreenState.asaId = label;

    final ScrollController sc =
        widget.scrollController ?? widget.categoryScreenState.controller;

    if (sc.position.maxScrollExtent >
        (MediaQuery.of(context).size.height - 250)) {
      if (label.toLowerCase() == "nft") {
        sc.animateTo(
          (270.h) +
              ((widget.categoryScreenState.asaModel.values?.length ?? 0) *
                  57.h) +
              21.h,
          duration: const Duration(seconds: 2),
          curve: Curves.fastOutSlowIn,
        );
        return;
      }
      sc.animateTo(
        (270.h) + (index * 57.h),
        duration: const Duration(seconds: 2),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _showTooltip(BuildContext context, String? title, String? percentage) {
    ToastService.show('$title $percentage %', gravity: ToastGravity.BOTTOM);
  }

  Widget _buildPieChart(
      double pieChartWidth, double containerHeight, double pieChartRadius) {
    return SizedBox(
      width: pieChartWidth,
      height: containerHeight,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: widget.chartData
                  .map(
                    (data) => PieChartSectionData(
                      color: data.color,
                      value: data.y ?? 0,
                      showTitle: false,
                      radius: pieChartRadius,
                    ),
                  )
                  .toList(),
              centerSpaceRadius: 0,
              sectionsSpace: 0,
              borderData: FlBorderData(show: false),
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? touchResponse) {
                  if (touchResponse != null &&
                      touchResponse.touchedSection != null) {
                    _lastTouchedIndex =
                        touchResponse.touchedSection!.touchedSectionIndex;
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
              onTapDown: (_) => _startTouchTimer(context, label, index),
              onTapUp: (_) => _cancelTouchTimerAndScroll(context, label, index),
              onTapCancel: () {
                _touchTimer?.cancel();
                _touchTimer = null;
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Top gradient overlay.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double containerHeight =
          constraints.hasBoundedHeight ? constraints.maxHeight : 200;
      final double totalWidth = constraints.maxWidth;

      // Define proportions.
      final double legendWidth = totalWidth * 0.3;
      final double spacerWidth = totalWidth * 0.1;
      final double pieChartWidth = totalWidth * 0.6;

      // Compute pie chart radius.
      final double pieChartRadius = (pieChartWidth / 2) * 0.9;

      return Padding(
        padding: EdgeInsets.only(top: widget.paddingTop ?? 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: legendWidth,
              height: containerHeight,
              child: _buildLegend(context),
            ),
            SizedBox(width: spacerWidth),
            _buildPieChart(pieChartWidth, containerHeight, pieChartRadius),
          ],
        ),
      );
    });
  }
}
