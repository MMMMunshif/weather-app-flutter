import 'package:flutter/material.dart';

class WeatherLocation {
  final String city;
  final String country;
  final String localTime;
  final String userTime;
  final String temperature;
  final String condition;
  final String windSpeed;
  final String humidity;
  final String feelsLike;
  final String high;
  final String low;
  final IconData icon;
  final Color iconColor;
  final List<HourlyWeather> hourlyForecast;
  final List<DailyWeather> dailyForecast;

  WeatherLocation({
    required this.city,
    required this.country,
    required this.localTime,
    required this.userTime,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.humidity,
    required this.feelsLike,
    required this.high,
    required this.low,
    required this.icon,
    required this.iconColor,
    required this.hourlyForecast,
    required this.dailyForecast,
  });
}

class HourlyWeather {
  final String time;
  final String temperature;
  final IconData icon;
  final Color iconColor;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.icon,
    required this.iconColor,
  });
}

class DailyWeather {
  final String day;
  final String high;
  final String low;
  final IconData icon;
  final Color iconColor;

  DailyWeather({
    required this.day,
    required this.high,
    required this.low,
    required this.icon,
    required this.iconColor,
  });
}