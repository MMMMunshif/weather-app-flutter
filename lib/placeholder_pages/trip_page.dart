import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/settings/cubit/app_settings_cubit.dart';
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
  final TextEditingController searchController = TextEditingController();

  final WeatherSearchService searchService = WeatherSearchService();
  final WeatherApiService weatherApiService = WeatherApiService();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<SearchPlace> searchResults = [];
  List<WeatherLocation> tripLocations = [];
  final Map<String, _TripLocationMeta> locationMeta = {};

  WeatherLocation? selectedForecastLocation;

  bool isLoadingTrip = true;
  bool isSearching = false;
  bool isAddingLocation = false;
  bool isSavingTrip = false;
  bool isDeletingTrip = false;

  String searchText = '';
  String? searchError;
  bool hasUnsavedChanges = false;

  late DateTime departureDate;
  late DateTime returnDate;

  @override
  void initState() {
    super.initState();

    final today = _dateOnly(DateTime.now());
    departureDate = today.add(const Duration(days: 7));
    returnDate = today.add(const Duration(days: 11));

    _loadTrip();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>>? get _tripDoc {
    final user = firebaseAuth.currentUser;

    if (user == null) return null;

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc('current_trip');
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _locationKey(String city, String country) {
    return '${city}_${country}'.toLowerCase().replaceAll(' ', '_');
  }

  String _weatherKey(WeatherLocation location) {
    return _locationKey(location.city, location.country);
  }

  DateTime _readDate(dynamic value, DateTime fallback) {
    if (value is Timestamp) return _dateOnly(value.toDate());
    if (value is DateTime) return _dateOnly(value);
    if (value is String) {
      return _dateOnly(DateTime.tryParse(value) ?? fallback);
    }

    return fallback;
  }

  Future<void> _loadTrip() async {
    setState(() {
      isLoadingTrip = true;
    });

    try {
      final docRef = _tripDoc;

      if (docRef == null) {
        setState(() {
          isLoadingTrip = false;
        });
        return;
      }

      final snapshot = await docRef.get();

      if (!mounted) return;

      if (!snapshot.exists || snapshot.data() == null) {
        setState(() {
          tripLocations = [];
          locationMeta.clear();
          selectedForecastLocation = null;
          isLoadingTrip = false;
          hasUnsavedChanges = false;
        });
        return;
      }

      final data = snapshot.data()!;
      final today = _dateOnly(DateTime.now());

      final List locationsData = data['locations'] as List? ?? [];

      final List<WeatherLocation> loadedLocations = [];
      final Map<String, _TripLocationMeta> loadedMeta = {};

      for (final item in locationsData) {
        final map = Map<String, dynamic>.from(item as Map);

        final city = (map['city'] ?? '').toString();
        final country = (map['country'] ?? '').toString();
        final latitude = (map['latitude'] as num?)?.toDouble() ?? 0.0;
        final longitude = (map['longitude'] as num?)?.toDouble() ?? 0.0;

        if (city.isEmpty) continue;

        final weather = await weatherApiService.getWeatherByCoordinates(
          latitude: latitude,
          longitude: longitude,
          city: city,
          country: country,
        );

        loadedLocations.add(weather);

        loadedMeta[_locationKey(city, country)] = _TripLocationMeta(
          city: city,
          country: country,
          latitude: latitude,
          longitude: longitude,
        );
      }

      if (!mounted) return;

      setState(() {
        departureDate = _readDate(
          data['departureDate'],
          today.add(const Duration(days: 7)),
        );
        returnDate = _readDate(
          data['returnDate'],
          today.add(const Duration(days: 11)),
        );

        if (returnDate.isBefore(departureDate)) {
          returnDate = departureDate.add(const Duration(days: 1));
        }

        tripLocations = loadedLocations;
        locationMeta
          ..clear()
          ..addAll(loadedMeta);

        selectedForecastLocation =
        tripLocations.isEmpty ? null : tripLocations.first;

        isLoadingTrip = false;
        hasUnsavedChanges = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingTrip = false;
      });

      _showMessage(
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _saveTrip() async {
    if (tripLocations.isEmpty) {
      _showMessage('Please add at least one destination.', isError: true);
      return;
    }

    setState(() {
      isSavingTrip = true;
    });

    try {
      final docRef = _tripDoc;

      if (docRef == null) {
        throw Exception('Please login first.');
      }

      final locations = tripLocations.map((location) {
        final meta = locationMeta[_weatherKey(location)];

        return {
          'city': location.city,
          'country': location.country,
          'latitude': meta?.latitude ?? 0.0,
          'longitude': meta?.longitude ?? 0.0,
          'temperature': location.temperature,
          'condition': location.condition,
          'windSpeed': location.windSpeed,
          'humidity': location.humidity,
        };
      }).toList();

      await docRef.set(
        {
          'title': 'My Weather Trip',
          'departureDate': Timestamp.fromDate(departureDate),
          'returnDate': Timestamp.fromDate(returnDate),
          'locations': locations,
          'locationCount': locations.length,
          'selectedLocation': selectedForecastLocation == null
              ? null
              : {
            'city': selectedForecastLocation!.city,
            'country': selectedForecastLocation!.country,
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        isSavingTrip = false;
        hasUnsavedChanges = false;
      });

      _showMessage('Trip saved successfully.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSavingTrip = false;
      });

      _showMessage(
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _clearTrip(_TripTheme theme) async {
    if (tripLocations.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Clear Trip?',
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to remove this trip plan?',
            style: TextStyle(
              color: theme.subText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.subText,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Clear',
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

    setState(() {
      isDeletingTrip = true;
    });

    try {
      await _tripDoc?.delete();

      if (!mounted) return;

      final today = _dateOnly(DateTime.now());

      setState(() {
        tripLocations = [];
        locationMeta.clear();
        selectedForecastLocation = null;
        departureDate = today.add(const Duration(days: 7));
        returnDate = today.add(const Duration(days: 11));
        isDeletingTrip = false;
        hasUnsavedChanges = false;
      });

      _showMessage('Trip cleared.', isError: true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isDeletingTrip = false;
      });

      _showMessage(
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _searchPlace(String value) async {
    searchText = value.trim();

    if (searchText.length < 2) {
      setState(() {
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
      searchResults = [];
      searchError = null;
      isSearching = false;
    });
  }

  Future<void> _addSearchPlace(SearchPlace place) async {
    setState(() {
      isAddingLocation = true;
    });

    try {
      final weather = await weatherApiService.getWeatherByCoordinates(
        latitude: place.latitude,
        longitude: place.longitude,
        city: place.name,
        country: place.country,
      );

      if (!mounted) return;

      final key = _weatherKey(weather);
      final alreadyAdded = tripLocations.any((item) => _weatherKey(item) == key);

      setState(() {
        if (!alreadyAdded) {
          tripLocations.add(weather);
          locationMeta[key] = _TripLocationMeta(
            city: weather.city,
            country: weather.country,
            latitude: place.latitude,
            longitude: place.longitude,
          );
        }

        selectedForecastLocation = weather;
        isAddingLocation = false;
        hasUnsavedChanges = true;

        searchController.clear();
        searchText = '';
        searchResults = [];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isAddingLocation = false;
      });

      _showMessage(
        error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _removeLocation(WeatherLocation location) {
    setState(() {
      tripLocations.removeWhere((item) => _weatherKey(item) == _weatherKey(location));
      locationMeta.remove(_weatherKey(location));

      if (selectedForecastLocation != null &&
          _weatherKey(selectedForecastLocation!) == _weatherKey(location)) {
        selectedForecastLocation =
        tripLocations.isEmpty ? null : tripLocations.first;
      }

      hasUnsavedChanges = true;
    });
  }

  void _selectLocation(WeatherLocation location) {
    setState(() {
      selectedForecastLocation = location;
      hasUnsavedChanges = true;
    });
  }

  Future<void> _pickDate({
    required bool isDeparture,
    required _TripTheme theme,
  }) async {
    final today = _dateOnly(DateTime.now());
    final initial = isDeparture ? departureDate : returnDate;
    final first = isDeparture ? today : departureDate;
    final last = today.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
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

    if (picked == null) return;

    setState(() {
      if (isDeparture) {
        departureDate = _dateOnly(picked);

        if (returnDate.isBefore(departureDate)) {
          returnDate = departureDate.add(const Duration(days: 1));
        }
      } else {
        returnDate = _dateOnly(picked);
      }

      hasUnsavedChanges = true;
    });
  }

  void _openDetail(WeatherLocation location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherDetailPage(location: location),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;
    final theme = _TripTheme(settingsState);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          SafeArea(
            child: isLoadingTrip
                ? Center(
              child: CircularProgressIndicator(
                color: theme.accent,
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    theme: theme,
                    hasUnsavedChanges: hasUnsavedChanges,
                  ),
                  const SizedBox(height: 16),
                  _SearchBox(
                    theme: theme,
                    controller: searchController,
                    onChanged: _searchPlace,
                    onClear: _clearSearch,
                  ),
                  if (searchText.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SearchPanel(
                      theme: theme,
                      isSearching: isSearching,
                      searchError: searchError,
                      searchResults: searchResults,
                      onAdd: _addSearchPlace,
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    _PlanCard(
                      theme: theme,
                      departureDate: departureDate,
                      returnDate: returnDate,
                      isSaving: isSavingTrip,
                      hasUnsavedChanges: hasUnsavedChanges,
                      canSave: tripLocations.isNotEmpty,
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
                      onSave: _saveTrip,
                      onClear: () => _clearTrip(theme),
                    ),
                    const SizedBox(height: 18),
                    _MapCard(
                      theme: theme,
                      locations: tripLocations,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'TRIP LOCATIONS (${tripLocations.length})',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (tripLocations.isEmpty)
                      _EmptyTripCard(theme: theme)
                    else
                      ...tripLocations.map((location) {
                        final isSelected =
                            selectedForecastLocation != null &&
                                _weatherKey(selectedForecastLocation!) ==
                                    _weatherKey(location);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TripLocationCard(
                            theme: theme,
                            location: location,
                            isSelected: isSelected,
                            onTap: () {
                              _selectLocation(location);
                              _openDetail(location);
                            },
                            onSelect: () => _selectLocation(location),
                            onRemove: () => _removeLocation(location),
                          ),
                        );
                      }),
                    if (selectedForecastLocation != null) ...[
                      const SizedBox(height: 8),
                      _ForecastCard(
                        theme: theme,
                        location: selectedForecastLocation!,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (isAddingLocation || isSavingTrip || isDeletingTrip)
            _LoadingOverlay(
              theme: theme,
              text: isSavingTrip
                  ? 'Saving trip...'
                  : isDeletingTrip
                  ? 'Clearing trip...'
                  : 'Fetching weather...',
            ),
        ],
      ),
    );
  }
}

class _TripLocationMeta {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  const _TripLocationMeta({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class _TripTheme {
  final AppSettingsState state;

  _TripTheme(this.state);

  bool get isDark => state.isDarkMode;

  Color get background => state.backgroundColor;
  Color get card => state.cardColor;
  Color get text => state.textColor;
  Color get subText => state.subTextColor;
  Color get accent => state.accentColor;

  Color get softCard => isDark ? Colors.white.withOpacity(0.07) : Colors.white;
  Color get border =>
      isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD8E1F0);
  Color get searchBg =>
      isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE8EEF8);
  Color get pillBg =>
      isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE8EEF8);
  Color get mapBg => isDark ? const Color(0xFF0B1828) : const Color(0xFFEAF3FF);
  Color get overlayBg =>
      isDark ? Colors.black.withOpacity(0.60) : Colors.black.withOpacity(0.25);
}

class _TopBar extends StatelessWidget {
  final _TripTheme theme;
  final bool hasUnsavedChanges;

  const _TopBar({
    required this.theme,
    required this.hasUnsavedChanges,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'My Trip',
          style: TextStyle(
            color: theme.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (hasUnsavedChanges) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Unsaved',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '°C',
            style: TextStyle(
              color: theme.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  final _TripTheme theme;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.theme,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.searchBg,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(22),
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
                fontSize: 14,
              ),
              cursorColor: theme.accent,
              decoration: InputDecoration(
                hintText: 'Search city or country...',
                hintStyle: TextStyle(
                  color: theme.subText,
                  fontSize: 14,
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
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final _TripTheme theme;
  final bool isSearching;
  final String? searchError;
  final List<SearchPlace> searchResults;
  final ValueChanged<SearchPlace> onAdd;

  const _SearchPanel({
    required this.theme,
    required this.isSearching,
    required this.searchError,
    required this.searchResults,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: theme.accent,
          ),
        ),
      );
    }

    if (searchError != null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            searchError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.subText,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Search a city or country\nto add to your trip',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.subText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Column(
      children: searchResults.map((place) {
        return GestureDetector(
          onTap: () => onAdd(place),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.softCard,
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  place.isCountry
                      ? Icons.flag_rounded
                      : Icons.location_on_rounded,
                  color: theme.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    place.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.15),
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
      }).toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _TripTheme theme;
  final DateTime departureDate;
  final DateTime returnDate;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final bool canSave;
  final VoidCallback onPickDeparture;
  final VoidCallback onPickReturn;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const _PlanCard({
    required this.theme,
    required this.departureDate,
    required this.returnDate,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.canSave,
    required this.onPickDeparture,
    required this.onPickReturn,
    required this.onSave,
    required this.onClear,
  });

  String _formatDate(DateTime date) {
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
    final nights = returnDate.difference(departureDate).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.softCard,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: theme.subText,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                'Trip Dates',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$nights nights',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  theme: theme,
                  label: 'DEPARTURE',
                  value: _formatDate(departureDate),
                  icon: Icons.flight_takeoff_rounded,
                  onTap: onPickDeparture,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  theme: theme,
                  label: 'RETURN',
                  value: _formatDate(returnDate),
                  icon: Icons.flight_land_rounded,
                  onTap: onPickReturn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: isSaving
                      ? 'Saving...'
                      : hasUnsavedChanges
                      ? 'Save Trip'
                      : 'Saved',
                  icon: Icons.save_rounded,
                  backgroundColor: canSave ? theme.accent : theme.pillBg,
                  textColor: canSave ? Colors.white : theme.subText,
                  onTap: canSave && !isSaving ? onSave : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Clear Trip',
                  icon: Icons.delete_outline_rounded,
                  backgroundColor: Colors.redAccent.withOpacity(0.15),
                  textColor: Colors.redAccent,
                  onTap: onClear,
                ),
              ),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.10),
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
                      color: theme.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: textColor,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
    final displayLocations = locations.take(4).toList();

    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: theme.mapBg,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.public_rounded,
              color: theme.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
              size: 130,
            ),
          ),
          if (displayLocations.isEmpty)
            Center(
              child: Text(
                'Add destinations to preview your route',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayLocations.map((location) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.softCard,
                      border: Border.all(color: theme.accent.withOpacity(0.35)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${location.city} ${location.temperature}',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTripCard extends StatelessWidget {
  final _TripTheme theme;

  const _EmptyTripCard({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.softCard,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_location_alt_rounded,
            color: theme.accent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search and add cities to create your trip plan.',
              style: TextStyle(
                color: theme.subText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripLocationCard extends StatelessWidget {
  final _TripTheme theme;
  final WeatherLocation location;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _TripLocationCard({
    required this.theme,
    required this.location,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title = location.country.isEmpty
        ? location.city
        : '${location.city}, ${location.country}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? theme.accent.withOpacity(0.12) : theme.softCard,
          border: Border.all(
            color: isSelected ? theme.accent.withOpacity(0.55) : theme.border,
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
                  size: 42,
                ),
                const SizedBox(width: 12),
                Text(
                  location.temperature,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                      child: Icon(
                        Icons.close_rounded,
                        color: theme.subText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onSelect,
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? theme.accent : theme.subText,
                        size: 20,
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
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.softCard,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '5-Day Forecast · ${location.city}',
            style: TextStyle(
              color: theme.subText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
                        fontWeight: FontWeight.bold,
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

class _LoadingOverlay extends StatelessWidget {
  final _TripTheme theme;
  final String text;

  const _LoadingOverlay({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.overlayBg,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: theme.accent,
              ),
              const SizedBox(height: 14),
              Text(
                text,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
