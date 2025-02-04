import 'package:asa_stats/config/app_constants.dart';
import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/config/dimensions.dart';
import 'package:asa_stats/config/enums.dart';
import 'package:asa_stats/models/body/chart_data_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Chart extends StatelessWidget {
  final List<ChartData> chartData;
  final CategoryType type;
  final dynamic
      categoryScreenState; // Using dynamic since it might be different for each screen

  const Chart({
    Key? key,
    required this.chartData,
    required this.type,
    required this.categoryScreenState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                        title: data.title ?? '',
                        radius: 55,
                        titleStyle: TextStyle(
                          color: ColorResources.themeTextColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: Dimensions.FONT_SIZE_SMALL,
                          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                        ),
                      ))
                  .toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 0,
              borderData: FlBorderData(show: false),
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? touchResponse) {
                  if (!event.isInterestedForInteractions ||
                      touchResponse == null ||
                      touchResponse.touchedSection == null) {
                    return;
                  }
                  final touchedSection = touchResponse.touchedSection!;
                  final int touchedIndex = touchedSection.touchedSectionIndex;
                  final selectedLabel = chartData[touchedIndex].title ?? "";
                  _handleSectionSelected(selectedLabel, touchedIndex);
                },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 400),
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
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chartData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.all(4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 15,
                  height: 15,
                  color: chartData[index].color,
                ),
                SizedBox(width: 4),
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
}
