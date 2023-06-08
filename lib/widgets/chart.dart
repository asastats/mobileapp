import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../config/app_constants.dart';
import '../config/color.dart';
import '../config/dimensions.dart';
import '../config/enums.dart';
import '../models/body/chart_data_model.dart';

class Chart extends StatelessWidget {
  final List<ChartData> chartData;
  final CategoryType type;
  final categoryScreenState;
  const Chart({
    Key? key,
    required this.chartData,
    required this.type,
    required this.categoryScreenState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: chartData.isEmpty
          ? Container()
          : SfCircularChart(
              legend: Legend(
                position: LegendPosition.bottom,
                orientation: LegendItemOrientation.horizontal,
                isVisible: true,
                height: "30%",
                isResponsive: true,
                toggleSeriesVisibility: true,
                iconWidth: 15,
                iconHeight: 15,
                padding: 12.w,
                // width: type != CategoryType.all ? "100%" : "60%",
                alignment: ChartAlignment.center,
                overflowMode: LegendItemOverflowMode.scroll,
                textStyle: TextStyle(
                  color: ColorResources.themeTextColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: Dimensions.FONT_SIZE_SMALL,
                  fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
                ),
              ),
              onLegendTapped: (legend) {
                // setState(() {});
              },
              onDataLabelTapped: (DataLabelTapDetails data) {},
              series: <CircularSeries>[
                PieSeries<ChartData, String>(
                  dataSource: chartData,
                  legendIconType: LegendIconType.rectangle,
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) {
                      categoryScreenState.selectedLabel =
                          chartData[details.pointIndex ?? -1].title ?? "";
                      categoryScreenState.asaId =
                          categoryScreenState.selectedLabel;
                    }
                    if (categoryScreenState
                            .controller.position.maxScrollExtent >
                        (MediaQuery.of(context).size.height - 250)) {
                      if (categoryScreenState.selectedLabel.toLowerCase() ==
                          "nft") {
                        categoryScreenState.controller.animateTo(
                          ((270.h) +
                              ((categoryScreenState.asaModel.values?.length ??
                                      0) *
                                  57.h) +
                              21.h), // Top padding + total asa padding + space
                          duration: const Duration(seconds: 2),
                          curve: Curves.fastOutSlowIn,
                        );
                        return;
                      }
                      categoryScreenState.controller.animateTo(
                        (270.h) +
                            ((details.pointIndex ?? 0) *
                                57.h), // Top padding + above total asa padding
                        duration: const Duration(seconds: 2),
                        curve: Curves.fastOutSlowIn,
                      );
                    }
                  },
                  pointColorMapper: (ChartData data, i) => data.color,
                  xValueMapper: (ChartData data, _) => data.title,
                  yValueMapper: (ChartData data, _) => data.y,
                  animationDelay: 400,
                  // Radius of pie
                  radius: '100%',
                )
              ],
            ),
    );
  }
}
