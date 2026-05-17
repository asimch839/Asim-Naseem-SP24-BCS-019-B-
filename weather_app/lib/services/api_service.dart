import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../utils/constants.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<WeatherModel> fetchFullWeatherData(double lat, double lon) async {
    final String key = AppConstants.apiKey.trim();

    try {
      debugPrint('Fetching weather for Lat: $lat, Lon: $lon');

      // 1. Fetch Current Weather
      final currentRes = await _dio.get(
        '${AppConstants.baseUrl}/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': key,
          'units': 'metric',
        },
      );

      List<dynamic> forecastData = [];

      // 2. Fetch Forecast (Wrapped in try-catch so app doesn't crash if forecast is restricted)
      try {
        final forecastRes = await _dio.get(
          '${AppConstants.baseUrl}/forecast',
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'appid': key,
            'units': 'metric',
          },
        );
        if (forecastRes.statusCode == 200) {
          forecastData = forecastRes.data['list'];
        }
      } catch (e) {
        debugPrint('Forecast failed: $e. Using current weather only.');
      }

      if (currentRes.statusCode == 200) {
        return WeatherModel.fromJson(currentRes.data, forecastData);
      } else {
        throw Exception('Failed to load weather data');
      }
    } on DioException catch (e) {
      debugPrint('Dio Error: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('API Key 401 Unauthorized. Verify email and FULL RESTART app.');
      }
      throw Exception('Network Error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<WeatherModel> fetchWeatherByCity(String city) async {
    try {
      final String key = AppConstants.apiKey.trim();
      debugPrint('Searching for city: $city');

      final currentRes = await _dio.get(
        '${AppConstants.baseUrl}/weather',
        queryParameters: {
          'q': city,
          'appid': key,
          'units': 'metric',
        },
      );

      final lat = currentRes.data['coord']['lat'];
      final lon = currentRes.data['coord']['lon'];

      return await fetchFullWeatherData(lat, lon);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw Exception('City not found');
      if (e.response?.statusCode == 401) throw Exception('API Key Unauthorized');
      rethrow;
    } catch (e) {
      throw Exception('Error fetching weather for $city: $e');
    }
  }
}
