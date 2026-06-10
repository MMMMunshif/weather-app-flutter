import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/cubit/app_settings_cubit.dart';
import '../../models/weather_location.dart';

class WeatherDetailPage extends StatelessWidget {
  final WeatherLocation location;

  const WeatherDetailPage({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;

    return Scaffold(
      backgroundColor: settingsState.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                onBack: () => Navigator.pop(context),
                badgeColor: settingsState.isDarkMode
                    ? const Color(0xFF4B4B4B)
                    : const Color(0xFFE3ECF8),
                badgeTextColor: settingsState.isDarkMode
                    ? Colors.white
                    : settingsState.textColor,
              ),

              const SizedBox(height: 18),

              Center(
                child: Text(
                  location.city,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: settingsState.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _TimeCard(
                location: location,
                cardColor: settingsState.cardColor,
                textColor: settingsState.textColor,
                subTextColor: settingsState.subTextColor,
              ),

              const SizedBox(height: 14),

              _MainWeatherCard(
                location: location,
                cardColor: settingsState.cardColor,
                textColor: settingsState.textColor,
                subTextColor: settingsState.subTextColor,
              ),

              const SizedBox(height: 20),

              Text(
                'Hourly Forecast',
                style: TextStyle(
                  color: settingsState.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              _HourlyForecast(
                location: location,
                cardColor: settingsState.cardColor,
                textColor: settingsState.textColor,
                subTextColor: settingsState.subTextColor,
              ),

              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AirQualityCard(
                      cardColor: settingsState.cardColor,
                      textColor: settingsState.textColor,
                      subTextColor: settingsState.subTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrecipitationCard(
                      cardColor: settingsState.cardColor,
                      textColor: settingsState.textColor,
                      subTextColor: settingsState.subTextColor,
                    ),
                  ),
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
  final Color badgeColor;
  final Color badgeTextColor;

  const _TopBar({
    required this.onBack,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF9CA3AF),
            size: 22,
          ),
        ),
        const Spacer(),
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '°C',
            style: TextStyle(
              color: badgeTextColor,
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
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _TimeCard({
    required this.location,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TimeInfo(
            label: 'Local Time',
            value: location.localTime,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          const Spacer(),
          _TimeInfo(
            label: 'Your Time',
            value: location.userTime,
            textColor: textColor,
            subTextColor: subTextColor,
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
  final Color textColor;
  final Color subTextColor;
  final bool alignRight;

  const _TimeInfo({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subTextColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MainWeatherCard extends StatelessWidget {
  final WeatherLocation location;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _MainWeatherCard({
    required this.location,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            location.icon,
            color: location.iconColor,
            size: 72,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.temperature,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 54,
                    height: 0.9,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Feels Like ${location.feelsLike}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'H: ${location.high}     L: ${location.low}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Wind  ${location.windSpeed}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Humidity  ${location.humidity}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
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
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _HourlyForecast({
    required this.location,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: location.hourlyForecast.map((hour) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hour.time,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  hour.icon,
                  color: hour.iconColor,
                  size: 24,
                ),
                Text(
                  hour.temperature,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _AirQualityCard({
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 134,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Air Quality',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'AQI: 37 (Good)',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            height: 6,
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

          Text(
            'Air quality is good.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Perfect for outdoor activities.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subTextColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrecipitationCard extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _PrecipitationCard({
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 134,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precipitation',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '20%',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Rainfall: 0.2 in expected',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Light rain expected in the evening.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subTextColor,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}