import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database.dart';

class HistoryLineChart extends StatelessWidget {
  final List<JournalEntry> chartEntries;
  final double chartWidth;
  final int? selectedIndex;
  final ScrollController scrollController;
  final void Function(int index, Offset position) onSpotTap;

  const HistoryLineChart({
    super.key,
    required this.chartEntries,
    required this.chartWidth,
    required this.selectedIndex,
    required this.scrollController,
    required this.onSpotTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 || value.toInt() >= chartEntries.length) {
                      return const SizedBox.shrink();
                    }
                    final date = chartEntries[value.toInt()].capturedAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 30,
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                    );
                  },
                  interval: 20,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
                left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
                right: BorderSide.none,
                top: BorderSide.none,
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: const LineTouchTooltipData(), // Transparent default tooltip
              handleBuiltInTouches: false,
              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                  final spotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                  onSpotTap(spotIndex, event.localPosition);
                }
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: chartEntries.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), (e.value.fortuneScore ?? 50).toDouble());
                }).toList(),
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: selectedIndex == index ? 6 : 4,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: selectedIndex == index ? 2 : 0,
                      strokeColor: Theme.of(context).colorScheme.surface,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
