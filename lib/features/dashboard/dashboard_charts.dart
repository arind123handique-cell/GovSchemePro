import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class StatusPieChart extends StatelessWidget {
  final Map<String, int> data;

  const StatusPieChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, int>> entries =
        data.entries.where((MapEntry<String, int> e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const SizedBox(
          height: 180, child: Center(child: Text('No data')));
    }
    final int total = entries.fold(0, (int s, MapEntry<String, int> e) => s + e.value);
    return SizedBox(
      height: 200,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 38,
                sections: <PieChartSectionData>[
                  for (int i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      title:
                          '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                      color: AppColors
                          .chartPalette[i % AppColors.chartPalette.length],
                      radius: 52,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.chartPalette[
                                i % AppColors.chartPalette.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${entries[i].key} (${entries[i].value})',
                            style: const TextStyle(fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleBarChart extends StatelessWidget {
  final Map<String, double> data;
  final bool currency;
  final Color color;

  const SimpleBarChart(
    this.data, {
    super.key,
    this.currency = true,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> entries = data.entries.toList();
    if (entries.isEmpty || entries.every((MapEntry<String, double> e) => e.value == 0)) {
      return const SizedBox(
          height: 180, child: Center(child: Text('No data')));
    }
    final double maxVal = entries
        .map((MapEntry<String, double> e) => e.value)
        .reduce((double a, double b) => a > b ? a : b);
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (BarChartGroupData group, int groupIndex,
                  BarChartRodData rod, int rodIndex) {
                return BarTooltipItem(
                  currency
                      ? Formatters.compactCurrency(rod.toY)
                      : rod.toY.toStringAsFixed(0),
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final String label = entries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label.length > 8 ? '${label.substring(0, 8)}…' : label,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: <BarChartGroupData>[
            for (int i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: entries[i].value,
                    color: color,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress gauge used for physical / financial progress.
class GaugeCard extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const GaugeCard({
    super.key,
    required this.label,
    required this.percent,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 96,
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                height: 96,
                width: 96,
                child: CircularProgressIndicator(
                  value: (percent / 100).clamp(0, 1),
                  strokeWidth: 9,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                Formatters.percent(percent),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
