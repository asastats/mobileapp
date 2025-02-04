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

  const Chart({
    super.key,
    required this.chartData,
    required this.type,
    required this.categoryScreenState,
  });

  @override
  Widget build(BuildContext context) {
    late DateTime tapStartTime;
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: chartData
                  .map((data) => PieChartSectionData(
                        color: data.color,
                        value: data.y ?? 0,
                        showTitle: false,
                        radius: 80,

                        /// TODO: radius needs fix, must be relative to screen size? see implementation of this Chart class, on the screens.
                      ))
                  .toList(),
              centerSpaceRadius: 0,
              sectionsSpace: 0,
              borderData: FlBorderData(show: false),
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? touchResponse) {
                  // this is some null guard
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

                  // final touchedSection = touchResponse.touchedSection!;
                  // final int touchedIndex = touchedSection.touchedSectionIndex;
                  // final selectedLabel = chartData[touchedIndex].title ?? "";

                  // if (event is FlTapDownEvent) {
                  //   tapStartTime = DateTime.now();
                  // } else if (event is FlTapUpEvent) {
                  //   final tapDuration = DateTime.now().difference(tapStartTime);
                  //   if (tapDuration.inMilliseconds < 500) {
                  //     _handleSectionSelected(selectedLabel, touchedIndex);
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
        buildLegend(context),
      ],
    );
  }

  void _handleSectionSelected(String label, int index) {
    // Assuming all screen states have similar properties
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

  Widget buildLegend(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
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
                Text(chartData[index].title ?? '',
                    style: TextStyle(
                        color: ColorResources.themeTextColor(context))),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTooltip(BuildContext context, String? title, String? percentage) {
    ToastService.show('$title $percentage %', gravity: ToastGravity.BOTTOM);
  }
}
