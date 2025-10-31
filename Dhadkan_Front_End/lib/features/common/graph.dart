import 'package:dhadkan/utils/constants/colors.dart';
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Graph extends StatelessWidget {
  final List<double> times, diastolic, systolic, weight, hr;
  final double width;

  const Graph({
    super.key,
    required this.times,
    required this.diastolic,
    required this.systolic,
    required this.weight,
    required this.hr,
    required this.width,
  });

  bool get hasData {
    return systolic.any((v) => v > 0) ||
        diastolic.any((v) => v > 0) ||
        weight.any((v) => v > 0) ||
        hr.any((v) => v > 0);
  }

  @override
  Widget build(BuildContext context) {
    // Default values for empty graph
    const double defaultMinY = 0;
    const double defaultMaxY = 100;
    const double defaultInterval = 20;

    // Calculate actual min/max if we have data
    double minY = defaultMinY;
    double maxY = defaultMaxY;
    double interval = defaultInterval;

    if (hasData) {
      final allDataPoints = [...systolic, ...diastolic, ...weight, ...hr];
      maxY = allDataPoints.reduce((a, b) => a > b ? a : b);
      minY = allDataPoints.reduce((a, b) => a < b ? a : b);

      // Adjust y-axis range with padding
      minY = (minY - 20).clamp(0, double.infinity);
      maxY = maxY + 20;

      // Adjust interval based on range
      interval = ((maxY - minY) / 5).roundToDouble().clamp(10, 40);
    }

    return Column(
      children: [
        SizedBox(
          width: width,
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                horizontalInterval: interval,
                verticalInterval: hasData ? 1 : 5,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: MyTextTheme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    interval: interval,
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Row(
                        children: [
                          const SizedBox(width: 2),
                          Text(
                            '${value.toInt()}',
                            style: MyTextTheme.textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border.symmetric(
                  horizontal: BorderSide(
                    color: Colors.transparent,
                    width: 0,
                  ),
                  vertical: BorderSide(
                    color: Colors.black54,
                    width: 1,
                  ),
                ),
              ),
              lineBarsData: hasData
                  ? [
                _buildLineChartBarData(
                  times,
                  systolic,
                  MyColors.sColor,
                  'Systolic',
                  true,
                ),
                _buildLineChartBarData(
                  times,
                  diastolic,
                  MyColors.dColor,
                  'Diastolic',
                  true,
                ),
                _buildLineChartBarData(
                  times,
                  weight,
                  MyColors.weightColor,
                  'Weight',
                  true,
                ),
                _buildLineChartBarData(
                  times,
                  hr,
                  MyColors.hrColor,
                  'Heart Rate',
                  true,
                ),
              ]
                  : [], // Empty array shows just the axes
              minY: minY,
              maxY: maxY,
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            SizedBox(
              width: width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(MyColors.sColor, 'Systolic BP'),
                  _buildLegendItem(MyColors.dColor, 'Diastolic BP'),
                  _buildLegendItem(MyColors.weightColor, 'Weight'),
                  _buildLegendItem(MyColors.hrColor, 'Heart Rate'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  LineChartBarData _buildLineChartBarData(
      List<double> xValues,
      List<double> yValues,
      Color color,
      String label,
      bool showDots,
      ) {
    if (xValues.length != yValues.length) {
      throw Exception("Mismatch: xValues and yValues must be the same length.");
    }

    return LineChartBarData(
      spots: List.generate(
        yValues.length,
            (index) => FlSpot(xValues[index], yValues[index]),
      ),
      color: color,
      isCurved: false,
      barWidth: 2,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 1.5,
          strokeColor: color,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: MyTextTheme.textTheme.bodySmall,
        ),
      ],
    );
  }
}