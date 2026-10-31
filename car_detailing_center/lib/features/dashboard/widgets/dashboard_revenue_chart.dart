import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class DashboardRevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isLine;
  final String currency;

  const DashboardRevenueChart({
    super.key,
    required this.data,
    required this.isLine,
    this.currency = 'Rs.',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.textDarkMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            const Text(
              'No financial transactions recorded for this period',
              style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Revenue (Income)', AppColors.primary, isDark),
            const SizedBox(width: 18),
            _buildLegendItem('Garage Expense', AppColors.error, isDark),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isLine ? _buildLineChart(isDark) : _buildBarChart(isDark),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(bool isDark) {
    double maxY = 0;
    for (final item in data) {
      final inc = (item['income'] as num?)?.toDouble() ?? 0.0;
      final exp = (item['expense'] as num?)?.toDouble() ?? 0.0;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    if (maxY == 0) maxY = 1000;
    maxY = maxY * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  Formatters.compactCurrency(value, symbol: ''),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final label = (data[index]['label'] as String?) ?? '';
                  final parts = label.split('-');
                  final text = parts.length >= 2 ? '${parts.last}/${parts[parts.length - 2]}' : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIncome ? "Income" : "Expense"}: ${Formatters.compactCurrency(spot.y, symbol: currency)}',
                  TextStyle(
                    color: isIncome ? AppColors.primary : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // Income Bar
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              final inc = (e.value['income'] as num?)?.toDouble() ?? 0.0;
              return FlSpot(e.key.toDouble(), inc);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          // Expense Bar
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              final exp = (e.value['expense'] as num?)?.toDouble() ?? 0.0;
              return FlSpot(e.key.toDouble(), exp);
            }).toList(),
            isCurved: true,
            color: AppColors.error,
            barWidth: 2.5,
            dashArray: [5, 4],
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    double maxY = 0;
    for (final item in data) {
      final inc = (item['income'] as num?)?.toDouble() ?? 0.0;
      final exp = (item['expense'] as num?)?.toDouble() ?? 0.0;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    if (maxY == 0) maxY = 1000;
    maxY = maxY * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  Formatters.compactCurrency(value, symbol: ''),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final label = (data[index]['label'] as String?) ?? '';
                  final parts = label.split('-');
                  final text = parts.length >= 2 ? '${parts.last}/${parts[parts.length - 2]}' : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isIncome = rodIndex == 0;
              return BarTooltipItem(
                '${isIncome ? "Income" : "Expense"}\n${Formatters.compactCurrency(rod.toY, symbol: currency)}',
                TextStyle(
                  color: isIncome ? AppColors.primary : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: data.asMap().entries.map((e) {
          final inc = (e.value['income'] as num?)?.toDouble() ?? 0.0;
          final exp = (e.value['expense'] as num?)?.toDouble() ?? 0.0;

          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: inc,
                color: AppColors.primary,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: exp,
                color: AppColors.error,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
