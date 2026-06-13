import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/cubit/app_settings_cubit.dart';
import '../../data/saved_location_service.dart';
import '../../data/weather_search_service.dart';

class AllLocationsPage extends StatefulWidget {
  const AllLocationsPage({super.key});

  @override
  State<AllLocationsPage> createState() => _AllLocationsPageState();
}

class _AllLocationsPageState extends State<AllLocationsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  final WeatherSearchService searchService = WeatherSearchService();
  final SavedLocationService savedLocationService = SavedLocationService();

  List<SearchPlace> searchResults = [];

  bool isSearching = false;
  bool isSavingLocation = false;

  String? searchError;
  String searchText = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    searchText = query.trim();

    if (searchText.isEmpty || searchText.length < 2) {
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
    searchFocusNode.unfocus();

    setState(() {
      searchText = '';
      searchResults = [];
      isSearching = false;
      searchError = null;
    });
  }

  Future<void> _saveSearchPlace(SearchPlace place) async {
    setState(() {
      isSavingLocation = true;
    });

    try {
      await savedLocationService.addSavedLocation(
        city: place.name,
        country: place.country,
        latitude: place.latitude,
        longitude: place.longitude,
      );

      if (!mounted) return;

      setState(() {
        isSavingLocation = false;
      });

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSavingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;

    return Scaffold(
      backgroundColor: settingsState.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ── Top section with gradient header ──
                  _GradientHeader(
                    textColor: settingsState.textColor,
                    subTextColor: settingsState.subTextColor,
                    accentColor: settingsState.accentColor,
                    isDarkMode: settingsState.isDarkMode,
                    onBack: () => Navigator.pop(context, false),
                    searchController: searchController,
                    searchFocusNode: searchFocusNode,
                    onSearchChanged: _searchLocation,
                    onClear: _clearSearch,
                    backgroundColor: settingsState.backgroundColor,
                  ),

                  // ── Results area ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: _buildBody(settingsState),
                    ),
                  ),
                ],
              ),
            ),

            // ── Saving overlay ──
            if (isSavingLocation)
              _SavingOverlay(
                cardColor: settingsState.cardColor,
                textColor: settingsState.textColor,
                accentColor: settingsState.accentColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppSettingsState settingsState) {
    if (searchText.isEmpty) {
      return _StartSearchView(
        cardColor: settingsState.cardColor,
        textColor: settingsState.textColor,
        subTextColor: settingsState.subTextColor,
        accentColor: settingsState.accentColor,
        isDarkMode: settingsState.isDarkMode,
      );
    }

    if (searchText.length < 2) {
      return _HintMessage(
        message: 'Type at least 2 letters to search',
        subTextColor: settingsState.subTextColor,
      );
    }

    if (isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                color: settingsState.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: settingsState.subTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (searchError != null) {
      return _ErrorView(
        message: searchError!,
        subTextColor: settingsState.subTextColor,
        accentColor: settingsState.accentColor,
      );
    }

    if (searchResults.isEmpty) {
      return _HintMessage(
        message: 'No city or country found for "$searchText"',
        subTextColor: settingsState.subTextColor,
        icon: Icons.location_off_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
          child: Text(
            '${searchResults.length} result${searchResults.length == 1 ? '' : 's'} found',
            style: TextStyle(
              color: settingsState.subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final place = searchResults[index];
              return _SearchResultTile(
                place: place,
                cardColor: settingsState.cardColor,
                textColor: settingsState.textColor,
                subTextColor: settingsState.subTextColor,
                accentColor: settingsState.accentColor,
                isDarkMode: settingsState.isDarkMode,
                onTap: () => _saveSearchPlace(place),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Gradient Header with back button + search bar
// ─────────────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final Color backgroundColor;
  final bool isDarkMode;
  final VoidCallback onBack;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _GradientHeader({
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.isDarkMode,
    required this.onBack,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1A2235)
            : const Color(0xFFF0F4FF),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDarkMode ? 0.12 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title row
          Row(
            children: [
              _BackButton(
                onTap: onBack,
                isDarkMode: isDarkMode,
                subTextColor: subTextColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Location',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Search any city worldwide',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // °C badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '°C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Search bar
          _SearchBar(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            onClear: onClear,
            isDarkMode: isDarkMode,
            textColor: textColor,
            subTextColor: subTextColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Back button with subtle background
// ─────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color subTextColor;

  const _BackButton({
    required this.onTap,
    required this.isDarkMode,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: subTextColor,
          size: 17,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search bar (pill shaped, no separate Add text)
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDarkMode;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isDarkMode,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: accentColor,
              decoration: InputDecoration(
                hintText: 'Search city or country...',
                hintStyle: TextStyle(
                  color: subTextColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: subTextColor,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty / start state
// ─────────────────────────────────────────────
class _StartSearchView extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final bool isDarkMode;

  const _StartSearchView({
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large globe illustration container
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.22),
                  accentColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              color: accentColor,
              size: 50,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Find a location',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Type a city or country name above.\nTap Add on a result to save it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Decorative pill hints
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SuggestionChip(
                label: '🌏  Tokyo',
                accentColor: accentColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _SuggestionChip(
                label: '🗼  Paris',
                accentColor: accentColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _SuggestionChip(
                label: '🌁  London',
                accentColor: accentColor,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isDarkMode;

  const _SuggestionChip({
    required this.label,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDarkMode ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Generic hint / empty message
// ─────────────────────────────────────────────
class _HintMessage extends StatelessWidget {
  final String message;
  final Color subTextColor;
  final IconData icon;

  const _HintMessage({
    required this.message,
    required this.subTextColor,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: subTextColor.withValues(alpha: 0.4), size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final Color subTextColor;
  final Color accentColor;

  const _ErrorView({
    required this.message,
    required this.subTextColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search result tile — refined card
// ─────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final SearchPlace place;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.place,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withValues(alpha: isDarkMode ? 0.08 : 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                place.isCountry
                    ? Icons.flag_rounded
                    : Icons.location_on_rounded,
                color: accentColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    place.isCountry ? 'Country' : place.country,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Add button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Saving overlay
// ─────────────────────────────────────────────
class _SavingOverlay extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final Color accentColor;

  const _SavingOverlay({
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 36,
            vertical: 30,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                width: 44,
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Saving location...',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
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