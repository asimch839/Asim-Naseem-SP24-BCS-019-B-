import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/sale.dart';
import '../../core/utils/formatters.dart';

class RevenueChart extends StatelessWidget {
  final List<Sale> sales;
  final bool isDark;

  const RevenueChart({super.key, required this.sales, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Generate simple data: group sales by day (for the last 7 days)
    final now = DateTime.now();
    final Map<int, double> dailyRevenue = {};
    for (int i = 6; i >= 0; i--) {
      dailyRevenue[i] = 0;
    }

    for (var s in sales) {
      final diff = now.difference(s.saleDate).inDays;
      if (diff >= 0 && diff <= 6) {
        dailyRevenue[6 - diff] = (dailyRevenue[6 - diff] ?? 0) + s.grandTotal;
      }
    }

    final spots = dailyRevenue.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    double maxY = 1000;
    for (var val in dailyRevenue.values) {
      if (val > maxY) maxY = val;
    }
    maxY = maxY * 1.2; // Add some headroom

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Overview (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 5 ? maxY / 5 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
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
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final daysAgo = 6 - value.toInt();
                        if (daysAgo < 0 || daysAgo > 6) return const SizedBox.shrink();
                        final d = now.subtract(Duration(days: daysAgo));
                        final label = daysAgo == 0 ? 'Today' : '${d.day}/${d.month}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY > 5 ? maxY / 5 : 1,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY) return const SizedBox.shrink();
                        return Text(
                          value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.15),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          AppFormatters.currency(spot.y),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
