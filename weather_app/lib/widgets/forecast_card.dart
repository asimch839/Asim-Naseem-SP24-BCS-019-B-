import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class ForecastCard extends StatelessWidget {
  final ForecastDay forecast;

  const ForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    String time = "Now";
    try {
      DateTime dateTime = DateTime.parse(forecast.time);
      time = DateFormat('ha').format(dateTime);
    } catch (e) {
      time = "??";
    }

    return Container(
      width: 65.w, // Slightly narrower for better fit
      margin: EdgeInsets.only(right: 10.w),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FittedBox(
            child: Text(
              time,
              style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            ),
          ),
          _getWeatherIcon(forecast.condition),
          FittedBox(
            child: Text(
              "${forecast.temp.round()}°",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    switch (condition.toLowerCase()) {
      case 'clouds': iconData = Icons.cloud; break;
      case 'rain': iconData = Icons.umbrella; break;
      case 'clear': iconData = Icons.sunny; break;
      default: iconData = Icons.wb_cloudy_outlined;
    }
    return Icon(iconData, color: Colors.white, size: 22.sp);
  }
}
