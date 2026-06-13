import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/settings/cubit/app_settings_cubit.dart';
import '../features/weather/data/weather_search_service.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────

class ForecastData {
  final String period;
  final String avgHigh;
  final String avgLow;
  final String avgRain;
  final List<int> highTemps;
  final List<int> lowTemps;
  final List<double> rainValues;
  final List<String> weekLabels;

  const ForecastData({
    required this.period,
    required this.avgHigh,
    required this.avgLow,
    required this.avgRain,
    required this.highTemps,
    required this.lowTemps,
    required this.rainValues,
    required this.weekLabels,
  });
}

// ─────────────────────────────────────────────────────────────
// DYNAMIC THEME
// ─────────────────────────────────────────────────────────────

class _ForecastTheme {
  final AppSettingsState state;

  _ForecastTheme(this.state);

  bool get isDark => state.isDarkMode;

  Color get bg => state.backgroundColor;

  Color get surface => isDark ? const Color(0xFF0C1526) : Colors.white;

  Color get surfaceHi =>
      isDark ? const Color(0xFF111D33) : const Color(0xFFE8EEF8);

  Color get glass =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85);

  Color get border =>
      isDark ? const Color(0xFF1C2D4A) : const Color(0xFFD8E1F0);

  Color get borderHi =>
      isDark ? const Color(0xFF26406A) : const Color(0xFFB7C6DE);

  Color get sky => state.accentColor;

  Color get skyDim => state.accentColor.withOpacity(0.25);

  Color get skyGlow => state.accentColor.withOpacity(0.12);

  Color get amber => const Color(0xFFFFAA2E);

  Color get amberDim => const Color(0x40FFAA2E);

  Color get amberGlow => const Color(0x18FFAA2E);

  Color get rain => const Color(0xFF5B9BFF);

  Color get rainDim => const Color(0x405B9BFF);

  Color get textPrimary => state.textColor;

  Color get textSecond => state.subTextColor;

  Color get textMuted =>
      isDark ? const Color(0xFF3D5070) : const Color(0xFF8A98AA);

  Color get grid =>
      isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06);

  Color get selectedTabText =>
      isDark ? const Color(0xFF050B18) : Colors.white;
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
      avgHigh: '70°',
      avgLow: '52°',
      avgRain: '3.2"',
      highTemps: [70, 72, 75, 76, 80],
      lowTemps: [51, 53, 53, 57, 61],
      rainValues: [0.5, 0.4, 0.4, 0.2, 0.1],
      weekLabels: ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5'],
    ),
    ForecastData(
      period: 'March — May 2025',
      avgHigh: '74°',
      avgLow: '56°',
      avgRain: '7.8"',
      highTemps: [72, 75, 78, 81, 83],
      lowTemps: [53, 56, 58, 61, 64],
      rainValues: [1.2, 1.5, 1.8, 1.7, 1.6],
      weekLabels: ['Mar', 'Apr', 'May', 'Jun', 'Jul'],
    ),
    ForecastData(
      period: 'March — August 2025',
      avgHigh: '78°',
      avgLow: '60°',
      avgRain: '12.4"',
      highTemps: [74, 78, 82, 85, 88],
      lowTemps: [56, 60, 64, 67, 70],
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
                color: theme.sky.withOpacity(0.07),
                size: 380,
              ),
            ),
            Positioned(
              top: 260,
              right: -100,
              child: _GlowBlob(
                color: theme.amber.withOpacity(0.05),
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
          onTap: () {},
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
        '°F',
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
            color: Colors.black.withOpacity(theme.isDark ? 0.0 : 0.06),
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
                      color: theme.sky.withOpacity(0.35),
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
            value: data.avgHigh,
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
            value: data.avgLow,
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
            glow: theme.rainDim.withOpacity(0.15),
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
            color: Colors.black.withOpacity(theme.isDark ? 0.0 : 0.05),
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
// TEMPERATURE CARD
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
    return _ChartCard(
      theme: theme,
      title: 'Temperature Trend',
      trailing: Row(
        children: [
          _Dot(
            theme: theme,
            color: theme.amber,
            label: 'High',
          ),
          const SizedBox(width: 14),
          _Dot(
            theme: theme,
            color: theme.sky,
            label: 'Low',
          ),
        ],
      ),
      height: 220,
      child: CustomPaint(
        painter: _TempPainter(
          theme: theme,
          high: data.highTemps,
          low: data.lowTemps,
          labels: data.weekLabels,
        ),
        child: const SizedBox.expand(),
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
      height: 210,
      child: CustomPaint(
        painter: _RainPainter(
          theme: theme,
          values: data.rainValues,
          labels: data.weekLabels,
        ),
        child: const SizedBox.expand(),
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
    final highNum = int.tryParse(data.avgHigh.replaceAll('°', '')) ?? 70;

    final feel = highNum >= 82
        ? 'Warm & Humid'
        : highNum >= 74
        ? 'Mild & Comfortable'
        : 'Cool & Crisp';

    final feelColor = highNum >= 82
        ? theme.amber
        : highNum >= 74
        ? theme.sky
        : theme.rain;

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
              color: feelColor.withOpacity(0.12),
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
                '${data.highTemps.reduce(math.max)}°F',
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
// SHARED CHART CARD WRAPPER
// ─────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final _ForecastTheme theme;
  final String title;
  final Widget trailing;
  final double height;
  final Widget child;

  const _ChartCard({
    required this.theme,
    required this.title,
    required this.trailing,
    required this.height,
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
            color: Colors.black.withOpacity(theme.isDark ? 0.0 : 0.05),
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
          const SizedBox(height: 14),
          SizedBox(
            height: height,
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LEGEND DOT
// ─────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final _ForecastTheme theme;
  final Color color;
  final String label;

  const _Dot({
    required this.theme,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: theme.textSecond,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TEMPERATURE CHART PAINTER
// ─────────────────────────────────────────────────────────────

class _TempPainter extends CustomPainter {
  final _ForecastTheme theme;
  final List<int> high;
  final List<int> low;
  final List<String> labels;

  const _TempPainter({
    required this.theme,
    required this.high,
    required this.low,
    required this.labels,
  });

  static const _min = 44.0;
  static const _max = 92.0;
  static const _l = 38.0;
  static const _r = 12.0;
  static const _t = 8.0;
  static const _b = 28.0;

  double _y(double value, double height) {
    return _t + height - ((value - _min) / (_max - _min)) * height;
  }

  List<Offset> _points(List<int> values, double width, double height) {
    final count = values.length;

    return List.generate(count, (index) {
      return Offset(
        _l + (width / (count - 1)) * index,
        _y(values[index].toDouble(), height),
      );
    });
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i].dy,
      );

      final cp2 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i + 1].dy,
      );

      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _l - _r;
    final chartHeight = size.height - _t - _b;

    final gridPaint = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final value in [50, 60, 70, 80, 90]) {
      final y = _y(value.toDouble(), chartHeight);

      canvas.drawLine(
        Offset(_l, y),
        Offset(_l + chartWidth, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: '$value°',
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 10,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final highPoints = _points(high, chartWidth, chartHeight);
    final lowPoints = _points(low, chartWidth, chartHeight);

    for (int i = 0; i < labels.length; i++) {
      final x = _l + (chartWidth / (labels.length - 1)) * i;

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, _t + chartHeight + 10),
      );
    }

    void drawArea(List<Offset> points, Color color) {
      final area = _smoothPath(points)
        ..lineTo(points.last.dx, _t + chartHeight)
        ..lineTo(points.first.dx, _t + chartHeight)
        ..close();

      canvas.drawPath(
        area,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    drawArea(highPoints, theme.amberGlow);
    drawArea(lowPoints, theme.skyGlow);

    canvas.drawPath(
      _smoothPath(highPoints),
      Paint()
        ..color = theme.amber
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      _smoothPath(lowPoints),
      Paint()
        ..color = theme.sky
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    void drawDots(List<Offset> points, Color color) {
      for (final point in points) {
        canvas.drawCircle(point, 5, Paint()..color = color);
        canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
      }
    }

    drawDots(highPoints, theme.amber);
    drawDots(lowPoints, theme.sky);

    for (int i = 0; i < high.length; i++) {
      textPainter.text = TextSpan(
        text: '${high[i]}°',
        style: TextStyle(
          color: theme.amber,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          highPoints[i].dx - textPainter.width / 2,
          highPoints[i].dy - 17,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TempPainter oldDelegate) {
    return oldDelegate.high != high ||
        oldDelegate.low != low ||
        oldDelegate.theme.state != theme.state;
  }
}

// ─────────────────────────────────────────────────────────────
// PRECIPITATION CHART PAINTER
// ─────────────────────────────────────────────────────────────

class _RainPainter extends CustomPainter {
  final _ForecastTheme theme;
  final List<double> values;
  final List<String> labels;

  const _RainPainter({
    required this.theme,
    required this.values,
    required this.labels,
  });

  static const _l = 38.0;
  static const _r = 12.0;
  static const _t = 8.0;
  static const _b = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _l - _r;
    final chartHeight = size.height - _t - _b;

    final maxValue = values.reduce(math.max) * 1.2;

    final gridPaint = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int tick = 0; tick <= 4; tick++) {
      final value = (maxValue / 4) * tick;
      final y = _t + chartHeight - (value / maxValue) * chartHeight;

      canvas.drawLine(
        Offset(_l, y),
        Offset(_l + chartWidth, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: value == 0 ? '0' : value.toStringAsFixed(1),
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 10,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final itemWidth = chartWidth / values.length;
    final barWidth = itemWidth * 0.55;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * chartHeight;
      final x = _l + itemWidth * i + (itemWidth - barWidth) / 2;
      final y = _t + chartHeight - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);

      final roundedRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(7),
      );

      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.sky,
          theme.rain.withOpacity(0.6),
        ],
      ).createShader(rect);

      canvas.drawRRect(
        roundedRect,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.fill,
      );

      canvas.drawRRect(
        roundedRect,
        Paint()
          ..color = theme.sky.withOpacity(0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      textPainter.text = TextSpan(
        text: values[i].toStringAsFixed(1),
        style: TextStyle(
          color: theme.sky,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y - 14),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - textPainter.width / 2,
          _t + chartHeight + 10,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.theme.state != theme.state;
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