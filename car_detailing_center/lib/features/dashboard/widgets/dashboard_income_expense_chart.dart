import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class DashboardIncomeExpenseChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String currency;

  const DashboardIncomeExpenseChart({
    super.key,
    required this.data,
    this.currency = 'Rs.',
  });

  @override
  State<DashboardIncomeExpenseChart> createState() => _DashboardIncomeExpenseChartState();
}

class _DashboardIncomeExpenseChartState extends State<DashboardIncomeExpenseChart> {
  // 0: Donut Circle, 1: Grouped Bars, 2: Smooth Trend Lines
  int _chartType = 0;
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 40, color: AppColors.textDarkMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            const Text(
              'No comparative cashflow records found',
              style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 450;

        return Column(
          children: [
            // Top Toolbar: Chart Type Selector & Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildLegend(isDark)),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardElevated : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypeBtn(0, isCompact ? '' : 'Circle', Icons.pie_chart_rounded, isDark),
                      _buildTypeBtn(1, isCompact ? '' : 'Bars', Icons.bar_chart_rounded, isDark),
                      _buildTypeBtn(2, isCompact ? '' : 'Lines', Icons.show_chart_rounded, isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildChartContent(isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeBtn(int type, String label, IconData icon, bool isDark) {
    final isSelected = _chartType == type;

    return InkWell(
      onTap: () => setState(() => _chartType = type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem('Income', AppColors.primary, isDark),
          const SizedBox(width: 14),
          _legendItem('Expenses', AppColors.error, isDark),
          const SizedBox(width: 14),
          _legendItem('Net Margin', AppColors.success, isDark),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChartContent(bool isDark) {
    switch (_chartType) {
      case 0:
        return _buildDonutChart(isDark);
      case 1:
        return _buildGroupedBarChart(isDark);
      case 2:
      default:
        return _buildTrendLinesChart(isDark);
    }
  }

  Widget _buildDonutChart(bool isDark) {
    double totalInc = 0;
    double totalExp = 0;
    for (final item in widget.data) {
      totalInc += (item['income'] as num?)?.toDouble() ?? 0.0;
      totalExp += (item['expense'] as num?)?.toDouble() ?? 0.0;
    }

    final netMargin = totalInc - totalExp;
    final totalCashflow = totalInc + totalExp;

    if (totalCashflow <= 0) {
      return Center(
        child: Text(
          'Total period volume is zero',
          style: TextStyle(color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
        ),
      );
    }

    final incPct = ((totalInc / totalCashflow) * 100).toStringAsFixed(1);
    final expPct = ((totalExp / totalCashflow) * 100).toStringAsFixed(1);

    final bool hasBoth = totalInc > 0 && totalExp > 0;
    final List<PieChartSectionData> sections = [];

    if (totalInc > 0) {
      final isTouched = _touchedPieIndex == 0;
      sections.add(
        PieChartSectionData(
          color: AppColors.primary,
          value: totalInc,
          title: hasBoth ? '$incPct%' : '100%',
          radius: isTouched ? 46 : 40,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (totalExp > 0) {
      final expSectionIndex = sections.isEmpty ? 0 : 1;
      final isTouched = _touchedPieIndex == expSectionIndex;
      sections.add(
        PieChartSectionData(
          color: AppColors.error,
          value: totalExp,
          title: hasBoth ? '$expPct%' : '100%',
          radius: isTouched ? 46 : 40,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieResponse == null ||
                                pieResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: hasBoth ? 3 : 0,
                      centerSpaceRadius: 46,
                      sections: sections,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.donut_large_rounded,
                        size: 20,
                        color: hasBoth
                            ? AppColors.primary
                            : (totalInc > 0 ? AppColors.primary : AppColors.error),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cashflow',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricSummaryRow('Total Income', Formatters.compactCurrency(totalInc, symbol: widget.currency), AppColors.primary, isDark),
              const SizedBox(height: 12),
              _metricSummaryRow('Total Expenses', Formatters.compactCurrency(totalExp, symbol: widget.currency), AppColors.error, isDark),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _metricSummaryRow(
                'Net Income',
                Formatters.compactCurrency(netMargin, symbol: widget.currency),
                netMargin >= 0 ? AppColors.success : AppColors.error,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricSummaryRow(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedBarChart(bool isDark) {
    double maxY = 0;
    for (final item in widget.data) {
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
              reservedSize: 44,
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
                if (index >= 0 && index < widget.data.length) {
                  final label = (widget.data[index]['label'] as String?) ?? '';
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
        barGroups: widget.data.asMap().entries.map((e) {
          final inc = (e.value['income'] as num?)?.toDouble() ?? 0.0;
          final exp = (e.value['expense'] as num?)?.toDouble() ?? 0.0;

          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: inc,
                color: AppColors.primary,
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: exp,
                color: AppColors.error,
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendLinesChart(bool isDark) {
    double maxY = 0;
    for (final item in widget.data) {
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
              reservedSize: 44,
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
                if (index >= 0 && index < widget.data.length) {
                  final label = (widget.data[index]['label'] as String?) ?? '';
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
        lineBarsData: [
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) {
              final inc = (e.value['income'] as num?)?.toDouble() ?? 0.0;
              return FlSpot(e.key.toDouble(), inc);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) {
              final exp = (e.value['expense'] as num?)?.toDouble() ?? 0.0;
              return FlSpot(e.key.toDouble(), exp);
            }).toList(),
            isCurved: true,
            color: AppColors.error,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
