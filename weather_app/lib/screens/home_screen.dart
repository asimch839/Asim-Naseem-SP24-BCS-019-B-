import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/weather_controller.dart';
import '../widgets/weather_detail_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/weather_chart.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WeatherController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(() {
          final cityName = controller.weather.value?.cityName ?? "SkyCast";
          final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cityName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        }),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context, controller),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF1E88E5), Color(0xFF64B5F6)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => controller.getLocationAndFetchWeather(),
            child: Obx(() {
              if (controller.isLoading.value && controller.weather.value == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (controller.error.isNotEmpty && controller.weather.value == null) {
                return _buildErrorState(controller);
              }

              final weather = controller.weather.value;
              if (weather == null) return const Center(child: Text("No Data", style: TextStyle(color: Colors.white)));

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Icon(_getWeatherIcon(weather.condition), size: 70.sp, color: Colors.white),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${weather.temperature.round()}°",
                        style: TextStyle(fontSize: 80.sp, fontWeight: FontWeight.w200, color: Colors.white),
                      ),
                    ),
                    Text(
                      weather.description.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, letterSpacing: 2, color: Colors.white70),
                    ),

                    SizedBox(height: 25.h),
                    _buildSectionHeader("Temperature Trend"),
                    SizedBox(height: 10.h),
                    WeatherChart(hourlyForecast: weather.hourlyForecast),

                    SizedBox(height: 25.h),
                    _buildSectionHeader("Hourly Forecast"),
                    SizedBox(height: 15.h),
                    SizedBox(
                      height: 110.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weather.hourlyForecast.length.clamp(0, 12),
                        itemBuilder: (context, index) => ForecastCard(forecast: weather.hourlyForecast[index]),
                      ),
                    ),

                    SizedBox(height: 25.h),
                    _buildSectionHeader("Daily Forecast"),
                    SizedBox(height: 10.h),
                    _buildDailyForecastList(weather.dailyForecast),

                    SizedBox(height: 25.h),
                    _buildSectionHeader("Weather Details"),
                    SizedBox(height: 15.h),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 2.2,
                      children: [
                        WeatherDetailCard(label: "Feels Like", value: "${weather.feelsLike.round()}°", icon: Icons.thermostat),
                        WeatherDetailCard(label: "Humidity", value: "${weather.humidity}%", icon: Icons.water_drop),
                        WeatherDetailCard(label: "Wind", value: "${weather.windSpeed} km/h", icon: Icons.air),
                        WeatherDetailCard(label: "Visibility", value: "10 km", icon: Icons.visibility),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildDailyForecastList(List<dynamic> dailyData) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dailyData.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white12, height: 20.h),
        itemBuilder: (context, index) {
          final day = dailyData[index];
          DateTime date = DateTime.parse(day.date);
          String dayName = index == 0 ? "Today" : DateFormat('EEEE').format(date);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 80.w,
                child: Text(dayName, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              ),
              Icon(_getWeatherIcon(day.condition), color: Colors.white, size: 20.sp),
              SizedBox(
                width: 60.w,
                child: Text(
                  "${day.temp.round()}°",
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(WeatherController controller) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 60),
              SizedBox(height: 16.h),
              Text("Error Loading Data", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              Text(controller.error.value, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
              SizedBox(height: 20.h),
              ElevatedButton(onPressed: () => controller.getLocationAndFetchWeather(), child: const Text("Try Again")),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clouds': return Icons.cloud_queue;
      case 'rain': return Icons.umbrella;
      case 'clear': return Icons.wb_sunny;
      default: return Icons.wb_cloudy;
    }
  }

  void _showSearchDialog(BuildContext context, WeatherController controller) {
    final searchController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text("Search City", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Enter city name...", hintStyle: TextStyle(color: Colors.white54)),
          onSubmitted: (val) { if (val.isNotEmpty) { controller.fetchWeather(val); Get.back(); } },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { if (searchController.text.isNotEmpty) { controller.fetchWeather(searchController.text); Get.back(); } }, child: const Text("Search")),
        ],
      ),
    );
  }
}
