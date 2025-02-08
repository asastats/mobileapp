import 'dart:ffi';

import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/models/body/chart_data_model.dart';
import 'package:asa_stats/utility/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Chart extends StatelessWidget {
  final List<ChartData> chartData;
  final CategoryType type;
  final dynamic categoryScreenState;
  final double? paddingTop;

  const Chart({
    super.key,
    required this.chartData,
    required this.type,
    required this.categoryScreenState,
    this.paddingTop,
  });

  @override
  Widget build(BuildContext context) {
    late DateTime tapStartTime;
    return Padding(
      padding: EdgeInsets.only(top: paddingTop ?? 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLegend(context),
          const SizedBox(width: 8),
          SizedBox(
            height: 200,
            width: 200,
            child: PieChart(
              PieChartData(
                sections: chartData
                    .map(
                      (data) => PieChartSectionData(
                        color: data.color,
                        value: data.y ?? 0,
                        showTitle: false,
                        radius: 90,
                        // TODO: radius needs fix, must be relative to screen size? see implementation of this Chart class, on the screens.
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
                    // Null checks for safe interaction
                    if (!event.isInterestedForInteractions ||
                        touchResponse == null ||
                        touchResponse.touchedSection == null) {
                      return;
                    }

                    String? title = chartData[
                            touchResponse.touchedSection!.touchedSectionIndex]
                        .title;
                    String? percentage =
                        (touchResponse.touchedSection!.touchedSection!.value)
                            .toStringAsFixed(2);
                    print('$title $percentage %');
                    _showTooltip(context, title, percentage);

                    // Uncomment and adjust the code below if you want to handle short vs long presses.
                    // if (event is FlTapDownEvent) {
                    //   tapStartTime = DateTime.now();
                    // } else if (event is FlTapUpEvent) {
                    //   final tapDuration = DateTime.now().difference(tapStartTime);
                    //   if (tapDuration.inMilliseconds < 500) {
                    //     _handleSectionSelected(title ?? "", touchResponse.touchedSection!.touchedSectionIndex);
                    //   } else {
                    //     print("Long press");
                    //   }
                    //   tapStartTime = DateTime(0);
                    // }
                  },
                ),
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLegend(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 200,
      child: Stack(
        children: [
          ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: chartData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 15,
                      height: 15,
                      color: chartData[index].color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        chartData[index].title ?? '',
                        style: TextStyle(
                          color: ColorResources.themeTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0)
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
                      Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(0.0),
                      Theme.of(context).scaffoldBackgroundColor
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSectionSelected(String label, int index) {
    categoryScreenState.selectedLabel = label;
    categoryScreenState.asaId = label;

    if (categoryScreenState.controller.position.maxScrollExtent >
        (MediaQuery.of(categoryScreenState.context).size.height - 250)) {
      if (label.toLowerCase() == "nft") {
        categoryScreenState.controller.animateTo(
          (270.h) +
              ((categoryScreenState.asaModel.values?.length ?? 0) * 57.h) +
              21.h,
          duration: const Duration(seconds: 2),
          curve: Curves.fastOutSlowIn,
        );
        return;
      }
      categoryScreenState.controller.animateTo(
        (270.h) + (index * 57.h),
        duration: const Duration(seconds: 2),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _showTooltip(BuildContext context, String? title, String? percentage) {
    ToastService.show('$title $percentage %', gravity: ToastGravity.BOTTOM);
  }
}
