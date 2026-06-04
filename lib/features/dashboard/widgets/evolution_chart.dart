import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Barras agrupadas ingresos vs gastos, 6 meses (réplica del bar chart web).
class EvolutionChart extends StatelessWidget {
  const EvolutionChart({
    super.key,
    required this.ingresos,
    required this.gastos,
    required this.labels,
  });

  final List<double> ingresos;
  final List<double> gastos;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxVal = [
      ...ingresos,
      ...gastos,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.darkBorder, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i],
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.darkMuted)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < labels.length; i++)
              BarChartGroupData(x: i, barsSpace: 3, barRods: [
                BarChartRodData(
                    toY: ingresos[i],
                    color: AppColors.teal,
                    width: 7,
                    borderRadius: BorderRadius.circular(2)),
                BarChartRodData(
                    toY: gastos[i],
                    color: AppColors.red,
                    width: 7,
                    borderRadius: BorderRadius.circular(2)),
              ]),
          ],
        ),
      ),
    );
  }
}
