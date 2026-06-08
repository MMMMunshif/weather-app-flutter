import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/settings/cubit/app_settings_cubit.dart';
import '../features/weather/data/sample_weather_data.dart';
import '../features/weather/data/weather_api_service.dart';
import '../features/weather/data/weather_search_service.dart';
import '../features/weather/models/weather_location.dart';
import '../features/weather/presentation/pages/weather_detail_page.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key});

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherSearchService _searchService = WeatherSearchService();
  final WeatherApiService _weatherApiService = WeatherApiService();

  List<SearchPlace> _searchResults = [];
  List<WeatherLocation> _tripLocations = [
    sampleLocations[1],
    sampleLocations[0],
  ];

  WeatherLocation? _selectedForecastLocation;

  bool _isSearching = false;
  bool _isAddingLocation = false;
  String _searchText = '';
  String? _searchError;

  DateTime _departureDate = DateTime(2025, 3, 21);
  DateTime _returnDate = DateTime(2025, 3, 25);

  @override
  void initState() {
    super.initState();
    _selectedForecastLocation = _tripLocations.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlace(String value) async {
    _searchText = value.trim();

    if (_searchText.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await _searchService.searchPlaces(_searchText);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchText = '';
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
    });
  }

  Future<void> _addSearchPlace(SearchPlace place) async {
    setState(() => _isAddingLocation = true);

    try {
      final weather = await _weatherApiService.getWeatherByCoordinates(
        latitude: place.latitude,
        longitude: place.longitude,
        city: place.name,
        country: place.country,
      );

      if (!mounted) return;

      final alreadyAdded = _tripLocations.any(
            (loc) =>
        loc.city.toLowerCase() == weather.city.toLowerCase() &&
            loc.country.toLowerCase() == weather.country.toLowerCase(),
      );

      setState(() {
        if (!alreadyAdded) {
          _tripLocations.add(weather);
        }

        _selectedForecastLocation = weather;
        _isAddingLocation = false;
        _searchController.clear();
        _searchText = '';
        _searchResults = [];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isAddingLocation = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A2744),
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _removeLocation(WeatherLocation location) {
    setState(() {
      _tripLocations.remove(location);

      if (_selectedForecastLocation == location) {
        _selectedForecastLocation =
        _tripLocations.isEmpty ? null : _tripLocations.first;
      }
    });
  }

  void _selectLocation(WeatherLocation location) {
    setState(() => _selectedForecastLocation = location);
  }

  void _openDetail(WeatherLocation location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherDetailPage(location: location),
      ),
    );
  }

  Future<void> _pickDate({
    required bool isDeparture,
    required _TripTheme theme,
  }) async {
    final initial = isDeparture ? _departureDate : _returnDate;
    final first = isDeparture ? DateTime.now() : _departureDate;
    final last = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: theme.isDark ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.accent,
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;

          if (_returnDate.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 1));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;
    final theme = _TripTheme(settingsState);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          _AmbientGlows(theme: theme),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _TopBar(
                    theme: theme,
                    onBack: () => Navigator.maybePop(context),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SearchRow(
                      theme: theme,
                      controller: _searchController,
                      onChanged: _searchPlace,
                      onClear: _clearSearch,
                    ),
                  ),
                ),

                if (_searchText.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    sliver: SliverToBoxAdapter(
                      child: _buildSearchPanel(theme),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    sliver: SliverToBoxAdapter(
                      child: _PlanSection(
                        theme: theme,
                        departureDate: _departureDate,
                        returnDate: _returnDate,
                        onPickDeparture: () {
                          _pickDate(
                            isDeparture: true,
                            theme: theme,
                          );
                        },
                        onPickReturn: () {
                          _pickDate(
                            isDeparture: false,
                            theme: theme,
                          );
                        },
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    sliver: SliverToBoxAdapter(
                      child: _MapCard(
                        theme: theme,
                        locations: _tripLocations,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    sliver: SliverToBoxAdapter(
                      child: _SectionLabel(
                        theme: theme,
                        text: 'Trip Locations (${_tripLocations.length})',
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final loc = _tripLocations[index];
                          final isSelected = _selectedForecastLocation == loc;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TripWeatherCard(
                              theme: theme,
                              location: loc,
                              isSelected: isSelected,
                              onTap: () {
                                _selectLocation(loc);
                                _openDetail(loc);
                              },
                              onSelect: () => _selectLocation(loc),
                              onRemove: () => _removeLocation(loc),
                            ),
                          );
                        },
                        childCount: _tripLocations.length,
                      ),
                    ),
                  ),

                  if (_selectedForecastLocation != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
                      sliver: SliverToBoxAdapter(
                        child: _ForecastCard(
                          theme: theme,
                          location: _selectedForecastLocation!,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          if (_isAddingLocation)
            _LoadingOverlay(
              theme: theme,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(_TripTheme theme) {
    if (_isSearching) {
      return SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(
            color: theme.accent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_searchError != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: theme.subText.withOpacity(0.7),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _searchError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                color: theme.subText.withOpacity(0.55),
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                'Search a city or country\nto add to your trip',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
            style: TextStyle(
              color: theme.subText,
              fontSize: 12,
            ),
          ),
        ),
        ...List.generate(_searchResults.length, (index) {
          final place = _searchResults[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SearchResultTile(
              theme: theme,
              place: place,
              onTap: () => _addSearchPlace(place),
            ),
          );
        }),
      ],
    );
  }
}

class _TripTheme {
  final AppSettingsState state;

  _TripTheme(this.state);

  bool get isDark => state.isDarkMode;

  Color get background => state.backgroundColor;

  Color get card => state.cardColor;

  Color get cardSoft =>
      isDark ? Colors.white.withOpacity(0.07) : Colors.white;

  Color get border =>
      isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD8E1F0);

  Color get selectedBg => state.accentColor.withOpacity(isDark ? 0.12 : 0.14);

  Color get selectedBorder => state.accentColor.withOpacity(0.55);

  Color get accent => state.accentColor;

  Color get text => state.textColor;

  Color get subText => state.subTextColor;

  Color get muted =>
      isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF8B95A7);

  Color get searchBg =>
      isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE8EEF8);

  Color get mapBg => isDark ? const Color(0xFF0B1828) : const Color(0xFFEAF3FF);

  Color get pillBg =>
      isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE8EEF8);

  Color get overlayBg =>
      isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.25);
}

class _AmbientGlows extends StatelessWidget {
  final _TripTheme theme;

  const _AmbientGlows({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (!theme.isDark) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: _Glow(
            size: 300,
            color: theme.accent.withOpacity(0.09),
          ),
        ),
        Positioned(
          bottom: 60,
          right: -80,
          child: _Glow(
            size: 250,
            color: theme.accent.withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final _TripTheme theme;
  final VoidCallback onBack;

  const _TopBar({
    required this.theme,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.cardSoft,
                border: Border.all(color: theme.border),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: theme.text,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'My Trip',
              style: TextStyle(
                color: theme.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.accent.withOpacity(0.15),
              border: Border.all(
                color: theme.accent.withOpacity(0.35),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '°C',
              style: TextStyle(
                color: theme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final _TripTheme theme;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchRow({
    required this.theme,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.searchBg,
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: theme.subText,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 13,
                    ),
                    cursorColor: theme.accent,
                    decoration: InputDecoration(
                      hintText: 'Search city or country...',
                      hintStyle: TextStyle(
                        color: theme.subText,
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
                  child: Icon(
                    Icons.close_rounded,
                    color: theme.subText,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Edit',
          style: TextStyle(
            color: theme.accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final _TripTheme theme;
  final String text;

  const _SectionLabel({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: theme.accent.withOpacity(0.85),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  final _TripTheme theme;
  final DateTime departureDate;
  final DateTime returnDate;
  final VoidCallback onPickDeparture;
  final VoidCallback onPickReturn;

  const _PlanSection({
    required this.theme,
    required this.departureDate,
    required this.returnDate,
    required this.onPickDeparture,
    required this.onPickReturn,
  });

  String _fmt(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          theme: theme,
          text: 'Plan your trip',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardSoft,
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  color: theme.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where do you want to go?',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Search above to add cities and compare weather',
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardSoft,
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: theme.subText,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Trip Dates',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${returnDate.difference(departureDate).inDays} nights',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      theme: theme,
                      label: 'DEPARTURE',
                      value: _fmt(departureDate),
                      icon: Icons.flight_takeoff_rounded,
                      onTap: onPickDeparture,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      theme: theme,
                      label: 'RETURN',
                      value: _fmt(returnDate),
                      icon: Icons.flight_land_rounded,
                      onTap: onPickReturn,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final _TripTheme theme;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateButton({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.10),
          border: Border.all(
            color: theme.accent.withOpacity(0.28),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.accent,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: theme.accent.withOpacity(0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _MapCard extends StatelessWidget {
  final _TripTheme theme;
  final List<WeatherLocation> locations;

  const _MapCard({
    required this.theme,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          theme: theme,
          text: 'Route Map',
        ),
        const SizedBox(height: 10),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: theme.mapBg,
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const height = 210.0;

                const pins = [
                  _PinData(
                    label: 'Dallas',
                    temp: '24°',
                    left: 0.22,
                    top: 0.28,
                  ),
                  _PinData(
                    label: 'New York',
                    temp: '18°',
                    left: 0.65,
                    top: 0.20,
                  ),
                  _PinData(
                    label: 'L.A.',
                    temp: '27°',
                    left: 0.10,
                    top: 0.62,
                  ),
                ];

                return Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: _GridPainter(
                        color: theme.isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.04),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      top: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              theme.accent.withOpacity(0.07),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.public_rounded,
                        color: theme.isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                        size: 130,
                      ),
                    ),
                    ...pins.map(
                          (pin) => Positioned(
                        left: width * pin.left,
                        top: height * pin.top,
                        child: _MapPinWidget(
                          theme: theme,
                          data: pin,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? Colors.black.withOpacity(0.38)
                              : Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Map preview · Tap a pin for details',
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PinData {
  final String label;
  final String temp;
  final double left;
  final double top;

  const _PinData({
    required this.label,
    required this.temp,
    required this.left,
    required this.top,
  });
}

class _MapPinWidget extends StatelessWidget {
  final _TripTheme theme;
  final _PinData data;

  const _MapPinWidget({
    required this.theme,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: theme.isDark
                ? const Color(0xCC0D1B35)
                : Colors.white.withOpacity(0.9),
            border: Border.all(
              color: theme.accent.withOpacity(0.45),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            data.label,
            style: TextStyle(
              color: theme.text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: theme.accent,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.temp,
          style: TextStyle(
            color: theme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 28.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TripWeatherCard extends StatelessWidget {
  final _TripTheme theme;
  final WeatherLocation location;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _TripWeatherCard({
    required this.theme,
    required this.location,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.selectedBg : theme.cardSoft,
          border: Border.all(
            color: isSelected ? theme.selectedBorder : theme.border,
            width: isSelected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  location.icon,
                  color: location.iconColor,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Text(
                  location.temperature,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${location.city}, ${location.country}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        location.condition,
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.pillBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: theme.subText,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onSelect,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.accent.withOpacity(0.2)
                              : theme.pillBg,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                            color: theme.accent.withOpacity(0.5),
                          )
                              : null,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? theme.accent : theme.subText,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoPill(
                  theme: theme,
                  icon: Icons.air_outlined,
                  text: 'Wind ${location.windSpeed}',
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  theme: theme,
                  icon: Icons.water_drop_outlined,
                  text: 'Humidity ${location.humidity}',
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Forecast ↓',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final _TripTheme theme;
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.theme,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.pillBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.subText,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: theme.subText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final _TripTheme theme;
  final WeatherLocation location;

  const _ForecastCard({
    required this.theme,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardSoft,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: theme.subText,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '5-Day Forecast · ${location.city}',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: location.dailyForecast.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      item.day.toUpperCase(),
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      item.icon,
                      color: item.iconColor,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.high,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.low,
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final _TripTheme theme;
  final SearchPlace place;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.theme,
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardSoft,
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                place.isCountry
                    ? Icons.flag_rounded
                    : Icons.location_on_rounded,
                color: theme.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (place.country.isNotEmpty)
                    Text(
                      place.country,
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color: theme.accent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final _TripTheme theme;

  const _LoadingOverlay({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.overlayBg,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: theme.card,
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: theme.accent,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              Text(
                'Fetching weather...',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}