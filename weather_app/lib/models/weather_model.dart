class WeatherModel {
  final String cityName;
  final double temperature;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final List<ForecastDay> hourlyForecast;
  final List<DailyForecast> dailyForecast;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json, List<dynamic> forecastList) {
    List<ForecastDay> hourly = forecastList.map((e) => ForecastDay.fromJson(e)).toList();

    // Grouping 3-hour data into Daily data (OpenWeatherMap Free gives 5 days / 3 hours)
    Map<String, DailyForecast> dayMap = {};
    for (var item in forecastList) {
      String date = item['dt_txt'].split(' ')[0];
      if (!dayMap.containsKey(date)) {
        dayMap[date] = DailyForecast(
          date: date,
          temp: (item['main']['temp'] as num).toDouble(),
          condition: item['weather'][0]['main'],
        );
      }
    }

    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      hourlyForecast: hourly,
      dailyForecast: dayMap.values.toList(),
    );
  }
}

class ForecastDay {
  final String time;
  final double temp;
  final String condition;

  ForecastDay({required this.time, required this.temp, required this.condition});

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      time: json['dt_txt'] ?? '',
      temp: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
    );
  }
}

class DailyForecast {
  final String date;
  final double temp;
  final String condition;

  DailyForecast({required this.date, required this.temp, required this.condition});
}
