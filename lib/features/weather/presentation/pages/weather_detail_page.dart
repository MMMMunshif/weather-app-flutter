import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/weather_location.dart';

class WeatherDetailPage extends StatelessWidget {
  final WeatherLocation location;

  const WeatherDetailPage({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  location.city,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _TimeCard(location: location),
              const SizedBox(height: 12),
              _MainWeatherCard(location: location),
              const SizedBox(height: 16),
              const Text(
                'Hourly Forecast',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _HourlyForecast(location: location),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _AirQualityCard()),
                  const SizedBox(width: 10),
                  Expanded(child: _PrecipitationCard()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.grey,
            size: 22,
          ),
        ),
        const Spacer(),
        Container(
          height: 28,
          width: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF4B4B4B),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            '°F',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final WeatherLocation location;

  const _TimeCard({
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _TimeInfo(
            label: 'Local Time',
            value: location.localTime,
          ),
          const Spacer(),
          _TimeInfo(
            label: 'Your Time',
            value: location.userTime,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _TimeInfo({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MainWeatherCard extends StatelessWidget {
  final WeatherLocation location;

  const _MainWeatherCard({
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            location.icon,
            color: location.iconColor,
            size: 70,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.temperature,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 48,
                    height: 0.9,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  'Feels Like ${location.feelsLike}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'H: ${location.high}        L: ${location.low}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Wind  ${location.windSpeed}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Humidity  ${location.humidity}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyForecast extends StatelessWidget {
  final WeatherLocation location;

  const _HourlyForecast({
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: location.hourlyForecast.map((hour) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hour.time,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  hour.icon,
                  color: hour.iconColor,
                  size: 22,
                ),
                Text(
                  hour.temperature,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AirQualityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Air Quality',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'AQI: 37 (Good)',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                ],
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Air quality is good.\nPerfect for outdoor activities.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrecipitationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precipitation',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '20%',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Rainfall: 0.2 in expected\nLight rain expected\nin the evening.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}