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
    if (widget.type == CategoryType.asa) {
      if (parentScreenState.asaModel.values != null) {
        for (var value in parentScreenState.asaModel.values!) {
          if (value.asa?.unit == label) {
            selectedAssetId = value.asa?.id.toString() ?? label;
            break;
          }
        }
      }
    } else if (widget.type == CategoryType.nft) {
      if (parentScreenState.asaModel.nftValues != null) {
        for (var value in parentScreenState.asaModel.nftValues!) {
          if (value.collection == label) {
            selectedAssetId = value.collection.toString();
            break;
          }
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
                    if (touchedIndex < visibleIndexes.length) {
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
