import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/weather_model.dart';

class WeatherChart extends StatelessWidget {
  final List<ForecastDay> hourlyForecast;

  const WeatherChart({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    // Take first 8 points (approx 24 hours) for the graph
    final data = hourlyForecast.take(8).toList();

    return Container(
      height: 180.h,
      padding: EdgeInsets.only(right: 20.w, top: 20.h, bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    // Show time for every 2nd point to avoid crowding
                    if (index % 2 == 0) {
                      String time = data[index].time.split(' ')[1].substring(0, 5);
                      return Text(time, style: TextStyle(color: Colors.white70, fontSize: 10.sp));
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35.w,
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()}°", style: TextStyle(color: Colors.white70, fontSize: 10.sp));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.temp);
              }).toList(),
              isCurved: true,
              color: Colors.white,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
