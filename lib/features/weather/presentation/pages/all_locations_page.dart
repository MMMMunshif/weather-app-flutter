import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/sample_weather_data.dart';
import '../../data/weather_api_service.dart';
import '../../data/weather_search_service.dart';
import '../../models/weather_location.dart';
import 'weather_detail_page.dart';

class AllLocationsPage extends StatefulWidget {
  const AllLocationsPage({super.key});

  @override
  State<AllLocationsPage> createState() => _AllLocationsPageState();
}

class _AllLocationsPageState extends State<AllLocationsPage> {
  final TextEditingController searchController = TextEditingController();
  final WeatherSearchService searchService = WeatherSearchService();
  final WeatherApiService weatherApiService = WeatherApiService();

  List<WeatherLocation> filteredLocations = sampleLocations;
  List<SearchPlace> searchResults = [];

  bool isSearching = false;
  bool isOpeningWeather = false;
  String? searchError;
  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    searchText = query.trim();

    if (searchText.isEmpty) {
      setState(() {
        filteredLocations = sampleLocations;
        searchResults = [];
        isSearching = false;
        searchError = null;
      });
      return;
    }

    if (searchText.length < 2) {
      setState(() {
        final value = searchText.toLowerCase();

        filteredLocations = sampleLocations.where((location) {
          final city = location.city.toLowerCase();
          final country = location.country.toLowerCase();
          final condition = location.condition.toLowerCase();

          return city.contains(value) ||
              country.contains(value) ||
              condition.contains(value);
        }).toList();

        searchResults = [];
        isSearching = false;
        searchError = null;
      });
      return;
    }

    setState(() {
      isSearching = true;
      searchError = null;
    });

    try {
      final results = await searchService.searchPlaces(searchText);

      if (!mounted) return;

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        searchResults = [];
        isSearching = false;
        searchError = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _clearSearch() {
    searchController.clear();

    setState(() {
      searchText = '';
      filteredLocations = sampleLocations;
      searchResults = [];
      isSearching = false;
      searchError = null;
    });
  }

  Future<void> _openSearchPlace(SearchPlace place) async {
    setState(() {
      isOpeningWeather = true;
    });

    try {
      final weather = await weatherApiService.getWeatherByCoordinates(
        latitude: place.latitude,
        longitude: place.longitude,
        city: place.name,
        country: place.country,
      );

      if (!mounted) return;

      setState(() {
        isOpeningWeather = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeatherDetailPage(location: weather),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isOpeningWeather = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void _openStaticLocation(WeatherLocation location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherDetailPage(location: location),
      ),
    );
  }

  bool get showApiResults => searchText.length >= 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              child: Column(
                children: [
                  _TopBar(onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SearchBox(
                          controller: searchController,
                          onChanged: _searchLocation,
                          onClear: _clearSearch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _buildBody(),
                  ),
                ],
              ),
            ),
          ),
          if (isOpeningWeather)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (showApiResults) {
      if (isSearching) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        );
      }

      if (searchError != null) {
        return Center(
          child: Text(
            searchError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 15,
            ),
          ),
        );
      }

      if (searchResults.isEmpty) {
        return const Center(
          child: Text(
            'No worldwide city or country found',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final place = searchResults[index];

          return _SearchResultTile(
            place: place,
            onTap: () => _openSearchPlace(place),
          );
        },
      );
    }

    if (filteredLocations.isEmpty) {
      return const Center(
        child: Text(
          'No location found',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredLocations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final location = filteredLocations[index];

        return _LocationListTile(
          location: location,
          onTap: () => _openStaticLocation(location),
        );
      },
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
            '°C',
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              cursorColor: AppColors.primaryBlue,
              decoration: const InputDecoration(
                hintText: 'Search city or country',
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchPlace place;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(
              place.isCountry
                  ? Icons.flag_rounded
                  : Icons.location_on_rounded,
              color: AppColors.primaryBlue,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                place.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationListTile extends StatelessWidget {
  final WeatherLocation location;
  final VoidCallback onTap;

  const _LocationListTile({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 96,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(
              location.icon,
              color: location.iconColor,
              size: 42,
            ),
            const SizedBox(width: 12),
            Text(
              location.temperature,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${location.city}, ${location.country}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        location.localTime,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    location.condition,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wind  ${location.windSpeed}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Humidity  ${location.humidity}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}