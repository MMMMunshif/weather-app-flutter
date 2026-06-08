import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/weather_location.dart';

class WeatherApiService {
  Future<WeatherLocation> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
        'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'hourly': 'temperature_2m,weather_code',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': '5',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load weather data.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final current = data['current'] as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;

    final int weatherCode = _toInt(current['weather_code']);
    final condition = _conditionFromCode(weatherCode);

    final double temperature = _toDouble(current['temperature_2m']);
    final double feelsLike = _toDouble(current['apparent_temperature']);
    final double windSpeed = _toDouble(current['wind_speed_10m']);
    final int humidity = _toInt(current['relative_humidity_2m']);

    final List<HourlyWeather> hourlyForecast = _buildHourlyForecast(
      hourly: hourly,
      currentTime: current['time'].toString(),
    );

    final List<DailyWeather> dailyForecast = _buildDailyForecast(daily);

    final double high = _toDouble(
      (daily['temperature_2m_max'] as List).first,
    );
    final double low = _toDouble(
      (daily['temperature_2m_min'] as List).first,
    );

    return WeatherLocation(
      city: city,
      country: country,
      localTime: _formatTime(DateTime.now()),
      userTime: _formatTime(DateTime.now()),
      temperature: '${temperature.round()}°',
      condition: condition.name,
      windSpeed: '${windSpeed.round()} km/h',
      humidity: '$humidity%',
      feelsLike: '${feelsLike.round()}°',
      high: '${high.round()}°',
      low: '${low.round()}°',
      icon: condition.icon,
      iconColor: condition.color,
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
    );
  }

  List<HourlyWeather> _buildHourlyForecast({
    required Map<String, dynamic> hourly,
    required String currentTime,
  }) {
    final List times = hourly['time'] as List;
    final List temps = hourly['temperature_2m'] as List;
    final List codes = hourly['weather_code'] as List;

    int startIndex = times.indexWhere(
          (time) => time.toString().compareTo(currentTime) >= 0,
    );

    if (startIndex < 0) {
      startIndex = 0;
    }

    final List<HourlyWeather> result = [];

    for (int i = startIndex; i < startIndex + 6 && i < times.length; i++) {
      final condition = _conditionFromCode(_toInt(codes[i]));

      result.add(
        HourlyWeather(
          time: i == startIndex ? 'Now' : _hourLabel(times[i].toString()),
          temperature: '${_toDouble(temps[i]).round()}°',
          icon: condition.icon,
          iconColor: condition.color,
        ),
      );
    }

    return result;
  }

  List<DailyWeather> _buildDailyForecast(Map<String, dynamic> daily) {
    final List times = daily['time'] as List;
    final List highs = daily['temperature_2m_max'] as List;
    final List lows = daily['temperature_2m_min'] as List;
    final List codes = daily['weather_code'] as List;

    final List<DailyWeather> result = [];

    for (int i = 0; i < times.length && i < 5; i++) {
      final condition = _conditionFromCode(_toInt(codes[i]));

      result.add(
        DailyWeather(
          day: _dayLabel(times[i].toString()),
          high: '${_toDouble(highs[i]).round()}°',
          low: '${_toDouble(lows[i]).round()}°',
          icon: condition.icon,
          iconColor: condition.color,
        ),
      );
    }

    return result;
  }

  WeatherCondition _conditionFromCode(int code) {
    if (code == 0) {
      return WeatherCondition(
        name: 'Sunny',
        icon: Icons.wb_sunny_rounded,
        color: Colors.yellow,
      );
    }

    if (code == 1 || code == 2 || code == 3) {
      return WeatherCondition(
        name: 'Partly Cloudy',
        icon: Icons.wb_cloudy_rounded,
        color: Colors.lightBlueAccent,
      );
    }

    if (code == 45 || code == 48) {
      return WeatherCondition(
        name: 'Foggy',
        icon: Icons.cloud_rounded,
        color: Colors.blueGrey,
      );
    }

    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return WeatherCondition(
        name: 'Rainy',
        icon: Icons.water_drop_rounded,
        color: Colors.lightBlueAccent,
      );
    }

    if (code >= 71 && code <= 77) {
      return WeatherCondition(
        name: 'Snowy',
        icon: Icons.ac_unit_rounded,
        color: Colors.white,
      );
    }

    if (code >= 95) {
      return WeatherCondition(
        name: 'Thunderstorm',
        icon: Icons.thunderstorm_rounded,
        color: Colors.lightBlueAccent,
      );
    }

    return WeatherCondition(
      name: 'Cloudy',
      icon: Icons.cloud_rounded,
      color: Colors.lightBlueAccent,
    );
  }

  String _dayLabel(String dateText) {
    final date = DateTime.parse(dateText);

    switch (date.weekday) {
      case DateTime.monday:
        return 'MON';
      case DateTime.tuesday:
        return 'TUE';
      case DateTime.wednesday:
        return 'WED';
      case DateTime.thursday:
        return 'THU';
      case DateTime.friday:
        return 'FRI';
      case DateTime.saturday:
        return 'SAT';
      case DateTime.sunday:
        return 'SUN';
      default:
        return '';
    }
  }

  String _hourLabel(String timeText) {
    final date = DateTime.parse(timeText);
    return date.hour.toString().padLeft(2, '0');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
        ? 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class WeatherCondition {
  final String name;
  final IconData icon;
  final Color color;

  WeatherCondition({
    required this.name,
    required this.icon,
    required this.color,
  });
}