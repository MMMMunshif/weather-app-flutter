import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/cubit/app_settings_cubit.dart';
import '../../data/location_service.dart';
import '../../data/sample_weather_data.dart';
import '../../data/saved_location_service.dart';
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
  final SavedLocationService savedLocationService = SavedLocationService();

  WeatherLocation? currentWeather;
  List<WeatherLocation> savedWeatherLocations = [];

  bool isLoading = true;
  bool isSavedLocationsLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationWeather();
    _loadSavedLocationsWeather();
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      _loadCurrentLocationWeather(),
      _loadSavedLocationsWeather(),
    ]);
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

  Future<void> _loadSavedLocationsWeather() async {
    setState(() {
      isSavedLocationsLoading = true;
    });

    try {
      final savedLocations = await savedLocationService.getSavedLocations();

      final List<WeatherLocation> loadedWeatherLocations = [];

      for (final location in savedLocations) {
        final weather = await weatherApiService.getWeatherByCoordinates(
          latitude: location.latitude,
          longitude: location.longitude,
          city: location.city,
          country: location.country,
        );

        loadedWeatherLocations.add(weather);
      }

      if (!mounted) return;

      setState(() {
        savedWeatherLocations = loadedWeatherLocations;
        isSavedLocationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        savedWeatherLocations = [];
        isSavedLocationsLoading = false;
      });
    }
  }

  Future<void> _openAllLocationsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllLocationsPage(),
      ),
    );

    if (!mounted) return;

    await _loadSavedLocationsWeather();
  }

  Future<void> _removeSavedLocation(WeatherLocation location) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final settingsState = context.read<AppSettingsCubit>().state;

        return AlertDialog(
          backgroundColor: settingsState.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Remove Location?',
            style: TextStyle(
              color: settingsState.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to remove ${location.city} from My Locations?',
            style: TextStyle(
              color: settingsState.subTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: settingsState.subTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await savedLocationService.removeSavedLocation(
        city: location.city,
        country: location.country,
      );

      if (!mounted) return;

      setState(() {
        savedWeatherLocations.removeWhere(
              (item) =>
          item.city.toLowerCase() == location.city.toLowerCase() &&
              item.country.toLowerCase() == location.country.toLowerCase(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.city} removed from My Locations'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;

    return Scaffold(
      backgroundColor: settingsState.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: settingsState.accentColor,
          backgroundColor: settingsState.cardColor,
          onRefresh: _refreshHome,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 135),
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
                else if (currentWeather != null)
                    _TopWeatherCard(
                      location: currentWeather!,
                      onRefresh: _loadCurrentLocationWeather,
                      accentColor: settingsState.accentColor,
                    ),

                const SizedBox(height: 24),

                _LocationsHeader(
                  textColor: settingsState.textColor,
                  accentColor: settingsState.accentColor,
                  onAdd: _openAllLocationsPage,
                  onViewAll: _openAllLocationsPage,
                ),

                const SizedBox(height: 14),

                if (isSavedLocationsLoading)
                  SizedBox(
                    height: 158,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: settingsState.accentColor,
                      ),
                    ),
                  )
                else if (savedWeatherLocations.isEmpty)
                  _EmptySavedLocationsCard(
                    cardColor: settingsState.cardColor,
                    textColor: settingsState.textColor,
                    subTextColor: settingsState.subTextColor,
                    accentColor: settingsState.accentColor,
                    onAdd: _openAllLocationsPage,
                  )
                else
                  _SavedLocationsRow(
                    locations: savedWeatherLocations,
                    cardColor: settingsState.cardColor,
                    textColor: settingsState.textColor,
                    subTextColor: settingsState.subTextColor,
                    accentColor: settingsState.accentColor,
                    onRemove: _removeSavedLocation,
                  ),

                const SizedBox(height: 28),

                Text(
                  '5-Day Forecast',
                  style: TextStyle(
                    color: settingsState.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _FiveDayForecast(
                  location: currentWeather ?? sampleLocations.first,
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
      height: 330,
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
      height: 330,
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
            constraints: const BoxConstraints(
              minHeight: 330,
            ),
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 26),
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
                const Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
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
                const SizedBox(height: 10),
                Text(
                  location.temperature,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 68,
                    height: 0.9,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  location.condition,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Wind ${location.windSpeed}   Humidity ${location.humidity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -6,
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
              size: 26,
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
  final VoidCallback onAdd;
  final VoidCallback onViewAll;

  const _LocationsHeader({
    required this.textColor,
    required this.accentColor,
    required this.onAdd,
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 21,
            ),
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedLocationsRow extends StatelessWidget {
  final List<WeatherLocation> locations;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final ValueChanged<WeatherLocation> onRemove;

  const _SavedLocationsRow({
    required this.locations,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: locations.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 14);
        },
        itemBuilder: (context, index) {
          final location = locations[index];

          return SizedBox(
            width: 180,
            child: _SmallLocationCard(
              location: location,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              accentColor: accentColor,
              onRemove: () => onRemove(location),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeatherDetailPage(
                      location: location,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptySavedLocationsCard extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final VoidCallback onAdd;

  const _EmptySavedLocationsCard({
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_location_alt_rounded,
                color: accentColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No saved locations yet',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap here or press + to add your first city',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallLocationCard extends StatelessWidget {
  final WeatherLocation location;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SmallLocationCard({
    required this.location,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String title = location.country.isEmpty
        ? location.city
        : '${location.city}, ${location.country}';

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 158,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
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
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
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
                    fontSize: 30,
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
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ],
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
        minHeight: 140,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
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