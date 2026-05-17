import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class WeatherController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var isLoading = true.obs;
  var weather = Rxn<WeatherModel>();
  var error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('App started with API Key: ${AppConstants.apiKey}');
    getLocationAndFetchWeather();
  }

  Future<void> getLocationAndFetchWeather() async {
    try {
      isLoading(true);
      error('');
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        weather.value = await _apiService.fetchFullWeatherData(position.latitude, position.longitude);
      } else {
        // Default to London if permission denied
        fetchWeather('London');
      }
    } catch (e) {
      debugPrint('Location/Fetch Error: $e');
      // If location fails, try a default city to test the API key
      fetchWeather('London');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchWeather(String city) async {
    try {
      isLoading(true);
      error('');
      weather.value = await _apiService.fetchWeatherByCity(city);
    } catch (e) {
      error(e.toString().replaceAll('Exception: ', ''));
      debugPrint('City Fetch Error: $e');
    } finally {
      isLoading(false);
    }
  }
}
