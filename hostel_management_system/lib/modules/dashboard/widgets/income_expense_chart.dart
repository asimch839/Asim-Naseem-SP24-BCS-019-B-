import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/repositories/report_repository.dart';

class IncomeExpenseChart extends StatefulWidget {
  final List<ChartDataPoint> data;

  const IncomeExpenseChart({
    super.key,
    required this.data,
  });

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends State<IncomeExpenseChart> {
  // 0: Grouped Bar Chart, 1: Smooth Trend Lines, 2: Circle (Pie) Breakdown, 3: Area Waves, 4: Net Profit/Loss Margin, 5: Stacked Cashflow
  int _selectedChartType = 2; // Default to Circle chart as requested
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('No income/expense records found for chart'));
    }

    return Column(
      children: [
        // Top Toolbar: Chart Type Selector & Dynamic Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dynamic Legend based on active graph
            Expanded(child: _buildDynamicLegend()),
            const SizedBox(width: 8),

            // Graph Selector Toggle Buttons
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeBtn(2, 'Circle', Icons.pie_chart_rounded),
                    _buildTypeBtn(0, 'Bars', Icons.bar_chart_rounded),
                    _buildTypeBtn(1, 'Lines', Icons.show_chart_rounded),
                    _buildTypeBtn(3, 'Area Wave', Icons.area_chart_rounded),
                    _buildTypeBtn(4, 'Net P&L', Icons.waterfall_chart_rounded),
                    _buildTypeBtn(5, 'Stacked', Icons.stacked_bar_chart_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Active Chart Display
        Expanded(
          child: _buildActiveChart(),
        ),
      ],
    );
  }

  Widget _buildTypeBtn(int index, String label, IconData icon) {
    final isSelected = _selectedChartType == index;
    return InkWell(
      onTap: () => setState(() => _selectedChartType = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicLegend() {
    switch (_selectedChartType) {
      case 1:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Rent Income', AppColors.primaryLight),
            const SizedBox(width: 14),
            _buildLegendItem('Expenses', AppColors.danger),
            const SizedBox(width: 14),
            _buildLegendItem('Net Surplus', AppColors.success),
          ],
        );
      case 2:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Total Income', AppColors.primary),
            const SizedBox(width: 14),
            _buildLegendItem('Total Expenses', AppColors.danger),
          ],
        );
      case 3:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Income Wave', AppColors.primary),
            const SizedBox(width: 14),
            _buildLegendItem('Expense Wave', AppColors.danger),
          ],
        );
      case 4:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Net Profit (+)', AppColors.success),
            const SizedBox(width: 14),
            _buildLegendItem('Net Deficit (-)', AppColors.danger),
          ],
        );
      case 5:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Expenses Paid', AppColors.danger),
            const SizedBox(width: 14),
            _buildLegendItem('Retained Profit', AppColors.success),
          ],
        );
      case 0:
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Rent Income', AppColors.primaryLight),
            const SizedBox(width: 14),
            _buildLegendItem('Expenses', AppColors.danger),
          ],
        );
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActiveChart() {
    switch (_selectedChartType) {
      case 1:
        return _buildTrendLineChart();
      case 2:
        return _buildBreakdownChart();
      case 3:
        return _buildAreaWaveChart();
      case 4:
        return _buildNetProfitBarChart();
      case 5:
        return _buildStackedCashflowChart();
      case 0:
      default:
        return _buildGroupedBarChart();
    }
  }

  // -------------------------------------------------------------
  // GRAPH 1: GROUPED BAR CHART (Side-by-Side Comparison)
  // -------------------------------------------------------------
  Widget _buildGroupedBarChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox.shrink();
                return Text('${(value / 1000).toInt()}k', style: AppStyles.caption);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => _formatBottomTitle(value.toInt()),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value1,
                color: AppColors.primaryLight,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: e.value.value2,
                color: AppColors.danger,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------
  // GRAPH 2: MULTI-LINE TREND CURVES (Income, Expense, Net)
  // -------------------------------------------------------------
  Widget _buildTrendLineChart() {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final netSpots = <FlSpot>[];

    double maxY = 1000;
    for (int i = 0; i < widget.data.length; i++) {
      final p = widget.data[i];
      incomeSpots.add(FlSpot(i.toDouble(), p.value1));
      expenseSpots.add(FlSpot(i.toDouble(), p.value2));
      netSpots.add(FlSpot(i.toDouble(), p.value3));
      maxY = max(maxY, max(p.value1, max(p.value2, p.value3)));
    }
    maxY = maxY * 1.18;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox.shrink();
                return Text('${(value / 1000).toInt()}k', style: AppStyles.caption);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => _formatBottomTitle(value.toInt()),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Income Line
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primaryLight,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryLight.withValues(alpha: 0.12),
            ),
          ),
          // Expense Line
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.danger,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.danger.withValues(alpha: 0.08),
            ),
          ),
          // Net Profit Line
          LineChartBarData(
            spots: netSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.success,
            barWidth: 2.5,
            dashArray: [5, 4],
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // GRAPH 3: NET PROFIT & LOSS MARGIN (Surplus vs Deficit)
  // -------------------------------------------------------------
  Widget _buildNetProfitBarChart() {
    double maxVal = 1000;
    double minVal = 0;
    for (final p in widget.data) {
      if (p.value3 > maxVal) maxVal = p.value3;
      if (p.value3 < minVal) minVal = p.value3;
    }
    final maxY = max(maxVal * 1.2, 1000.0);
    final minY = min(minVal * 1.2, 0.0);

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) {
            if (val == 0) {
              return const FlLine(color: AppColors.textPrimary, strokeWidth: 1.5);
            }
            return const FlLine(color: AppColors.border, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('0', style: AppStyles.caption);
                return Text('${(value / 1000).toInt()}k', style: AppStyles.caption);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => _formatBottomTitle(value.toInt()),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.data.asMap().entries.map((e) {
          final isProfit = e.value.value3 >= 0;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value3,
                color: isProfit ? AppColors.success : AppColors.danger,
                width: 18,
                borderRadius: isProfit
                    ? const BorderRadius.vertical(top: Radius.circular(4))
                    : const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------
  // GRAPH 4: STACKED CASHFLOW VOLUME CHART
  // -------------------------------------------------------------
  Widget _buildStackedCashflowChart() {
    double maxY = 1000;
    for (final p in widget.data) {
      final total = max(p.value1, p.value2);
      if (total > maxY) maxY = total;
    }
    maxY = maxY * 1.18;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox.shrink();
                return Text('${(value / 1000).toInt()}k', style: AppStyles.caption);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => _formatBottomTitle(value.toInt()),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.data.asMap().entries.map((e) {
          final income = e.value.value1;
          final expense = e.value.value2;

          List<BarChartRodStackItem> stackItems = [];
          double rodToY = 0;

          if (income >= expense) {
            // Expense at bottom, Profit on top
            stackItems = [
              BarChartRodStackItem(0, expense, AppColors.danger),
              BarChartRodStackItem(expense, income, AppColors.success),
            ];
            rodToY = income;
          } else {
            // Income covered at bottom, Uncovered Expense on top
            stackItems = [
              BarChartRodStackItem(0, income, AppColors.primaryLight),
              BarChartRodStackItem(income, expense, AppColors.danger),
            ];
            rodToY = expense;
          }

          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: rodToY,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                rodStackItems: stackItems,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _formatBottomTitle(int index) {
    if (index >= 0 && index < widget.data.length) {
      final label = widget.data[index].label;
      final parts = label.split('-');
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : label,
          style: AppStyles.caption.copyWith(fontSize: 10),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // -------------------------------------------------------------
  // GRAPH 5: AREA WAVE CHART (Smooth Filled Gradients)
  // -------------------------------------------------------------
  Widget _buildAreaWaveChart() {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    double maxY = 1000;
    for (int i = 0; i < widget.data.length; i++) {
      final p = widget.data[i];
      incomeSpots.add(FlSpot(i.toDouble(), p.value1));
      expenseSpots.add(FlSpot(i.toDouble(), p.value2));
      maxY = max(maxY, max(p.value1, p.value2));
    }
    maxY = maxY * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                final label = isIncome ? 'Income' : 'Expense';
                return LineTooltipItem(
                  '$label: Rs. ${spot.y.toInt()}',
                  TextStyle(
                    color: isIncome ? AppColors.primaryLight : AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox.shrink();
                return Text('${(value / 1000).toInt()}k', style: AppStyles.caption);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => _formatBottomTitle(value.toInt()),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Income Wave (Primary)
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.40),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          // Expense Wave (Danger)
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.danger,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.danger.withValues(alpha: 0.35),
                  AppColors.danger.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // GRAPH 6: DONUT RATIO & FINANCIAL SUMMARY BREAKDOWN
  // -------------------------------------------------------------
  Widget _buildBreakdownChart() {
    double totalIncome = 0;
    double totalExpense = 0;
    for (final p in widget.data) {
      totalIncome += p.value1;
      totalExpense += p.value2;
    }
    final netProfit = totalIncome - totalExpense;
    final isProfit = netProfit >= 0;
    final totalCombined = totalIncome + totalExpense;

    if (totalCombined <= 0) {
      return const Center(child: Text('No transaction values to analyze'));
    }

    final incomePct = (totalIncome / totalCombined * 100);
    final expensePct = (totalExpense / totalCombined * 100);

    return Row(
      children: [
        // Interactive Circle (Pie) Chart with Center Dynamic Card
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: 44,
                  sections: [
                    // Section 0: Total Rent Income
                    PieChartSectionData(
                      value: totalIncome > 0 ? totalIncome : 0.001,
                      color: AppColors.primary,
                      title: '${incomePct.toStringAsFixed(0)}%',
                      radius: _touchedPieIndex == 0 ? 46 : 38,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    // Section 1: Total Expenses
                    PieChartSectionData(
                      value: totalExpense > 0 ? totalExpense : 0.001,
                      color: AppColors.danger,
                      title: '${expensePct.toStringAsFixed(0)}%',
                      radius: _touchedPieIndex == 1 ? 46 : 38,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Dynamic Center Badge
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_touchedPieIndex == 0) ...[
                    Text(
                      'Income',
                      style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rs. ${(totalIncome / 1000).toStringAsFixed(1)}k',
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                  ] else if (_touchedPieIndex == 1) ...[
                    Text(
                      'Expense',
                      style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rs. ${(totalExpense / 1000).toStringAsFixed(1)}k',
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                    ),
                  ] else ...[
                    Text(
                      '${isProfit ? '+' : ''}${totalIncome > 0 ? ((netProfit / totalIncome) * 100).toStringAsFixed(0) : '0'}%',
                      style: AppStyles.h3.copyWith(
                        color: isProfit ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Net Margin',
                      style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Key Summary Metric Tiles
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBreakdownMetricTile(
                title: 'Total Rent Income',
                amount: 'Rs. ${totalIncome.toInt()}',
                color: AppColors.primary,
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 8),
              _buildBreakdownMetricTile(
                title: 'Total Expenses Paid',
                amount: 'Rs. ${totalExpense.toInt()}',
                color: AppColors.danger,
                icon: Icons.payments_rounded,
              ),
              const SizedBox(height: 8),
              _buildBreakdownMetricTile(
                title: isProfit ? 'Net Profit Retained' : 'Net Cash Deficit',
                amount: 'Rs. ${netProfit.abs().toInt()}',
                color: isProfit ? AppColors.success : AppColors.danger,
                icon: isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownMetricTile({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            amount,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
