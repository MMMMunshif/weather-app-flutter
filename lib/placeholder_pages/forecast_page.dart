import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/settings/cubit/app_settings_cubit.dart';
import '../features/weather/data/weather_search_service.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODEL
// Base temperature values are stored in Fahrenheit.
// UI converts them to Celsius/Fahrenheit based on Settings.
// ─────────────────────────────────────────────────────────────

class ForecastData {
  final String period;
  final int avgHighF;
  final int avgLowF;
  final String avgRain;
  final List<int> highTempsF;
  final List<int> lowTempsF;
  final List<double> rainValues;
  final List<String> weekLabels;

  const ForecastData({
    required this.period,
    required this.avgHighF,
    required this.avgLowF,
    required this.avgRain,
    required this.highTempsF,
    required this.lowTempsF,
    required this.rainValues,
    required this.weekLabels,
  });
}

// ─────────────────────────────────────────────────────────────
// DYNAMIC THEME + UNIT FORMATTER
// ─────────────────────────────────────────────────────────────

class _ForecastTheme {
  final AppSettingsState state;

  _ForecastTheme(this.state);

  bool get isDark => state.isDarkMode;

  Color get bg => state.backgroundColor;
  Color get surface => isDark ? const Color(0xFF0C1526) : Colors.white;
  Color get surfaceHi =>
      isDark ? const Color(0xFF111D33) : const Color(0xFFE8EEF8);

  Color get glass => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.85);

  Color get border =>
      isDark ? const Color(0xFF1C2D4A) : const Color(0xFFD8E1F0);

  Color get borderHi =>
      isDark ? const Color(0xFF26406A) : const Color(0xFFB7C6DE);

  Color get sky => state.accentColor;
  Color get skyDim => state.accentColor.withValues(alpha: 0.25);
  Color get skyGlow => state.accentColor.withValues(alpha: 0.12);

  Color get amber => const Color(0xFFFFAA2E);
  Color get amberGlow => const Color(0x18FFAA2E);

  Color get rain => const Color(0xFF5B9BFF);
  Color get rainDim => const Color(0x405B9BFF);

  Color get textPrimary => state.textColor;
  Color get textSecond => state.subTextColor;

  Color get textMuted =>
      isDark ? const Color(0xFF3D5070) : const Color(0xFF8A98AA);

  Color get selectedTabText =>
      isDark ? const Color(0xFF050B18) : Colors.white;

  String get temperatureSymbol => state.temperatureSymbol;

  bool get isFahrenheit {
    return temperatureSymbol.toUpperCase().contains('F');
  }

  int convertTempFromF(num fahrenheit) {
    if (isFahrenheit) {
      return fahrenheit.round();
    }

    return ((fahrenheit - 32) * 5 / 9).round();
  }

  String formatTempFromF(num fahrenheit) {
    return '${convertTempFromF(fahrenheit)}°';
  }

  String get fullTemperatureUnit {
    return isFahrenheit ? 'Fahrenheit' : 'Celsius';
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage>
    with SingleTickerProviderStateMixin {
  int _tab = 0;

  late AnimationController _anim;
  late Animation<double> _fade;

  final WeatherSearchService _searchService = WeatherSearchService();

  String _selectedCity = 'New York';
  String _selectedCountry = 'USA';

  static const _tabs = ['1 Month', '3 Month', '6 Month'];

  static const _datasets = [
    ForecastData(
      period: 'March 18 — April 18, 2025',
      avgHighF: 70,
      avgLowF: 52,
      avgRain: '3.2"',
      highTempsF: [70, 72, 75, 76, 80],
      lowTempsF: [51, 53, 53, 57, 61],
      rainValues: [0.5, 0.4, 0.4, 0.2, 0.1],
      weekLabels: ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5'],
    ),
    ForecastData(
      period: 'March — May 2025',
      avgHighF: 74,
      avgLowF: 56,
      avgRain: '7.8"',
      highTempsF: [72, 75, 78, 81, 83],
      lowTempsF: [53, 56, 58, 61, 64],
      rainValues: [1.2, 1.5, 1.8, 1.7, 1.6],
      weekLabels: ['Mar', 'Apr', 'May', 'Jun', 'Jul'],
    ),
    ForecastData(
      period: 'March — August 2025',
      avgHighF: 78,
      avgLowF: 60,
      avgRain: '12.4"',
      highTempsF: [74, 78, 82, 85, 88],
      lowTempsF: [56, 60, 64, 67, 70],
      rainValues: [2.0, 2.3, 2.6, 2.8, 2.7],
      weekLabels: ['Mar', 'Apr', 'May', 'Jun', 'Aug'],
    ),
  ];

  ForecastData get _data => _datasets[_tab];

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fade = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOut,
    );

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _tab) return;

    _anim.forward(from: 0);

    setState(() {
      _tab = index;
    });
  }

  Future<void> _openLocationSearch(_ForecastTheme theme) async {
    final selectedPlace = await showModalBottomSheet<SearchPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LocationSearchSheet(
          theme: theme,
          searchService: _searchService,
        );
      },
    );

    if (selectedPlace == null) return;

    setState(() {
      _selectedCity = selectedPlace.name;
      _selectedCountry = selectedPlace.country;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;
    final theme = _ForecastTheme(settingsState);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          if (theme.isDark) ...[
            Positioned(
              top: -120,
              left: -80,
              child: _GlowBlob(
                color: theme.sky.withValues(alpha: 0.07),
                size: 380,
              ),
            ),
            Positioned(
              top: 260,
              right: -100,
              child: _GlowBlob(
                color: theme.amber.withValues(alpha: 0.05),
                size: 300,
              ),
            ),
          ],
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(theme: theme),
                    const SizedBox(height: 20),
                    _LocationPill(
                      theme: theme,
                      city: _selectedCity,
                      country: _selectedCountry,
                      onChange: () => _openLocationSearch(theme),
                    ),
                    const SizedBox(height: 16),
                    _TabBar(
                      theme: theme,
                      tabs: _tabs,
                      selected: _tab,
                      onTap: _switchTab,
                    ),
                    const SizedBox(height: 24),
                    _PeriodLabel(
                      theme: theme,
                      label: _data.period,
                    ),
                    const SizedBox(height: 20),
                    _StatsRow(
                      theme: theme,
                      data: _data,
                    ),
                    const SizedBox(height: 16),
                    _TempCard(
                      theme: theme,
                      data: _data,
                    ),
                    const SizedBox(height: 16),
                    _RainCard(
                      theme: theme,
                      data: _data,
                    ),
                    const SizedBox(height: 16),
                    _HumidityHintCard(
                      theme: theme,
                      data: _data,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GLOW BLOB
// ─────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    required this.size,
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

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _ForecastTheme theme;

  const _Header({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IconBtn(
          theme: theme,
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Long-Term',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'Forecast',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        _UnitBadge(theme: theme),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final _ForecastTheme theme;
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Icon(
          icon,
          color: theme.textSecond,
          size: 18,
        ),
      ),
    );
  }
}

class _UnitBadge extends StatelessWidget {
  final _ForecastTheme theme;

  const _UnitBadge({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.skyGlow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.skyDim),
      ),
      child: Text(
        theme.temperatureSymbol,
        style: TextStyle(
          color: theme.sky,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOCATION PILL
// ─────────────────────────────────────────────────────────────

class _LocationPill extends StatelessWidget {
  final _ForecastTheme theme;
  final String city;
  final String country;
  final VoidCallback onChange;

  const _LocationPill({
    required this.theme,
    required this.city,
    required this.country,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final locationText = country.isEmpty ? city : '$city, $country';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.0 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.skyGlow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: theme.sky,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.surfaceHi,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.border),
              ),
              child: Text(
                'Change',
                style: TextStyle(
                  color: theme.sky,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final _ForecastTheme theme;
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onTap;

  const _TabBar({
    required this.theme,
    required this.tabs,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isOn = selected == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isOn ? theme.sky : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isOn
                      ? [
                    BoxShadow(
                      color: theme.sky.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isOn ? theme.selectedTabText : theme.textSecond,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PERIOD LABEL
// ─────────────────────────────────────────────────────────────

class _PeriodLabel extends StatelessWidget {
  final _ForecastTheme theme;
  final String label;

  const _PeriodLabel({
    required this.theme,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: theme.sky,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme.textSecond,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final _ForecastTheme theme;
  final ForecastData data;

  const _StatsRow({
    required this.theme,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            theme: theme,
            label: 'AVG HIGH',
            value: theme.formatTempFromF(data.avgHighF),
            color: theme.amber,
            icon: Icons.wb_sunny_rounded,
            glow: theme.amberGlow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            theme: theme,
            label: 'AVG LOW',
            value: theme.formatTempFromF(data.avgLowF),
            color: theme.sky,
            icon: Icons.ac_unit_rounded,
            glow: theme.skyGlow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            theme: theme,
            label: 'AVG RAIN',
            value: data.avgRain,
            color: theme.rain,
            icon: Icons.water_drop_rounded,
            glow: theme.rainDim.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final _ForecastTheme theme;
  final String label;
  final String value;
  final Color color;
  final Color glow;
  final IconData icon;

  const _StatCard({
    required this.theme,
    required this.label,
    required this.value,
    required this.color,
    required this.glow,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.0 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: glow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TEMPERATURE TREND CARD
// ─────────────────────────────────────────────────────────────

class _TempCard extends StatelessWidget {
  final _ForecastTheme theme;
  final ForecastData data;

  const _TempCard({
    required this.theme,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxHigh = data.highTempsF.reduce(math.max);

    return _ChartCard(
      theme: theme,
      title: 'Temperature Trend',
      trailing: Text(
        theme.fullTemperatureUnit,
        style: TextStyle(
          color: theme.sky,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Column(
        children: List.generate(data.weekLabels.length, (index) {
          final highF = data.highTempsF[index];
          final lowF = data.lowTempsF[index];

          final highText = theme.formatTempFromF(highF);
          final lowText = theme.formatTempFromF(lowF);

          final progress = (highF / maxHigh).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    data.weekLabels[index],
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            lowText,
                            style: TextStyle(
                              color: theme.sky,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            highText,
                            style: TextStyle(
                              color: theme.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: theme.surfaceHi,
                          color: theme.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RAIN CARD
// ─────────────────────────────────────────────────────────────

class _RainCard extends StatelessWidget {
  final _ForecastTheme theme;
  final ForecastData data;

  const _RainCard({
    required this.theme,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxRain = data.rainValues.reduce(math.max);

    return _ChartCard(
      theme: theme,
      title: 'Precipitation Forecast',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.skyGlow,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'inches',
          style: TextStyle(
            color: theme.sky,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        children: List.generate(data.weekLabels.length, (index) {
          final rain = data.rainValues[index];
          final progress = (rain / maxRain).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    data.weekLabels[index],
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: theme.surfaceHi,
                      color: theme.rain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 38,
                  child: Text(
                    rain.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: theme.rain,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HUMIDITY HINT CARD
// ─────────────────────────────────────────────────────────────

class _HumidityHintCard extends StatelessWidget {
  final _ForecastTheme theme;
  final ForecastData data;

  const _HumidityHintCard({
    required this.theme,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final highNumF = data.avgHighF;

    final feel = highNumF >= 82
        ? 'Warm & Humid'
        : highNumF >= 74
        ? 'Mild & Comfortable'
        : 'Cool & Crisp';

    final feelColor = highNumF >= 82
        ? theme.amber
        : highNumF >= 74
        ? theme.sky
        : theme.rain;

    final peakF = data.highTempsF.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: feelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.thermostat_rounded,
              color: feelColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Feel',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feel,
                  style: TextStyle(
                    color: feelColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Peak',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                theme.formatTempFromF(peakF),
                style: TextStyle(
                  color: theme.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED CARD WRAPPER
// ─────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final _ForecastTheme theme;
  final String title;
  final Widget trailing;
  final Widget child;

  const _ChartCard({
    required this.theme,
    required this.title,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.0 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOCATION SEARCH SHEET
// ─────────────────────────────────────────────────────────────

class _LocationSearchSheet extends StatefulWidget {
  final _ForecastTheme theme;
  final WeatherSearchService searchService;

  const _LocationSearchSheet({
    required this.theme,
    required this.searchService,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _controller = TextEditingController();

  List<SearchPlace> _results = [];
  bool _isLoading = false;
  String? _error;

  _ForecastTheme get theme => widget.theme;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.searchService.searchPlaces(query);

      if (!mounted) return;

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _results = [];
        _isLoading = false;
        _error = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            width: 46,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Change Forecast Location',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: theme.textSecond,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _search,
                    autofocus: true,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                    ),
                    cursorColor: theme.sky,
                    decoration: InputDecoration(
                      hintText: 'Search city or country',
                      hintStyle: TextStyle(
                        color: theme.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.sky,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textSecond,
            fontSize: 14,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Type at least 2 letters to search',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final place = _results[index];

        return GestureDetector(
          onTap: () {
            Navigator.pop(context, place);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Icon(
                  place.isCountry
                      ? Icons.flag_rounded
                      : Icons.location_on_rounded,
                  color: theme.sky,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    place.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textSecond,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}