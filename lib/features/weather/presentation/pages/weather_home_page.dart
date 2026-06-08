import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/cubit/app_settings_cubit.dart';
import '../../data/location_service.dart';
import '../../data/sample_weather_data.dart';
import '../../data/weather_api_service.dart';
import '../../models/weather_location.dart';
import 'all_locations_page.dart';
import 'weather_detail_page.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final LocationService locationService = LocationService();
  final WeatherApiService weatherApiService = WeatherApiService();

  WeatherLocation? currentWeather;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationWeather();
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final place = await locationService.getCurrentPlace();

      final weather = await weatherApiService.getWeatherByCoordinates(
        latitude: place.latitude,
        longitude: place.longitude,
        city: place.city,
        country: place.country,
      );

      if (!mounted) return;

      setState(() {
        currentWeather = weather;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;
    final myLocations = sampleLocations.skip(1).take(2).toList();

    return Scaffold(
      backgroundColor: settingsState.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: settingsState.accentColor,
          backgroundColor: settingsState.cardColor,
          onRefresh: _loadCurrentLocationWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  _LoadingWeatherCard(
                    accentColor: settingsState.accentColor,
                  )
                else if (errorMessage != null)
                  _ErrorWeatherCard(
                    message: errorMessage!,
                    onRetry: _loadCurrentLocationWeather,
                    accentColor: settingsState.accentColor,
                  )
                else
                  _TopWeatherCard(
                    location: currentWeather!,
                    onRefresh: _loadCurrentLocationWeather,
                    accentColor: settingsState.accentColor,
                  ),

                const SizedBox(height: 20),

                _LocationsHeader(
                  textColor: settingsState.textColor,
                  accentColor: settingsState.accentColor,
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllLocationsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    for (int i = 0; i < myLocations.length; i++) ...[
                      Expanded(
                        child: _SmallLocationCard(
                          location: myLocations[i],
                          cardColor: settingsState.cardColor,
                          textColor: settingsState.textColor,
                          subTextColor: settingsState.subTextColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeatherDetailPage(
                                  location: myLocations[i],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (i != myLocations.length - 1)
                        const SizedBox(width: 14),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  '5-Day Forecast',
                  style: TextStyle(
                    color: settingsState.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                if (currentWeather != null)
                  _FiveDayForecast(
                    location: currentWeather!,
                    cardColor: settingsState.cardColor,
                    textColor: settingsState.textColor,
                    subTextColor: settingsState.subTextColor,
                  )
                else
                  _FiveDayForecast(
                    location: sampleLocations.first,
                    cardColor: settingsState.cardColor,
                    textColor: settingsState.textColor,
                    subTextColor: settingsState.subTextColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingWeatherCard extends StatelessWidget {
  final Color accentColor;

  const _LoadingWeatherCard({
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor,
            const Color(0xFF04C3FF),
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ErrorWeatherCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color accentColor;

  const _ErrorWeatherCard({
    required this.message,
    required this.onRetry,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor,
            const Color(0xFF04C3FF),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: Colors.white,
            size: 50,
          ),
          const SizedBox(height: 12),
          const Text(
            'Location Weather Not Available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _TopWeatherCard extends StatelessWidget {
  final WeatherLocation location;
  final VoidCallback onRefresh;
  final Color accentColor;

  const _TopWeatherCard({
    required this.location,
    required this.onRefresh,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final String title = location.country.isEmpty
        ? location.city
        : '${location.city}, ${location.country}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeatherDetailPage(location: location),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor,
                  const Color(0xFF04C3FF),
                ],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Live Weather · ${location.localTime}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Icon(
                  location.icon,
                  color: location.iconColor,
                  size: 64,
                ),
                const SizedBox(height: 8),
                Text(
                  location.temperature,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 66,
                    height: 0.9,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.condition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Wind ${location.windSpeed}   Humidity ${location.humidity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: -8,
          right: -2,
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.95),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: onRefresh,
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationsHeader extends StatelessWidget {
  final Color textColor;
  final Color accentColor;
  final VoidCallback onViewAll;

  const _LocationsHeader({
    required this.textColor,
    required this.accentColor,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'My Locations',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          height: 22,
          width: 22,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 16,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View All',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallLocationCard extends StatelessWidget {
  final WeatherLocation location;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onTap;

  const _SmallLocationCard({
    required this.location,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 155,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              location.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              location.localTime,
              style: TextStyle(
                color: subTextColor,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            Icon(
              location.icon,
              color: location.iconColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              location.temperature,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                height: 0.9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                location.condition,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiveDayForecast extends StatelessWidget {
  final WeatherLocation location;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _FiveDayForecast({
    required this.location,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(
        minHeight: 132,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: location.dailyForecast.map((item) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.day,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  item.high,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.low,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
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