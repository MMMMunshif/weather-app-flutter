import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSettingsState {
  final bool isDarkMode;
  final int themeIndex;

  // New settings
  final String temperatureUnit; // C or F
  final String windSpeedUnit; // kmh or mph

  const AppSettingsState({
    required this.isDarkMode,
    required this.themeIndex,
    required this.temperatureUnit,
    required this.windSpeedUnit,
  });

  AppSettingsState copyWith({
    bool? isDarkMode,
    int? themeIndex,
    String? temperatureUnit,
    String? windSpeedUnit,
  }) {
    return AppSettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeIndex: themeIndex ?? this.themeIndex,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      windSpeedUnit: windSpeedUnit ?? this.windSpeedUnit,
    );
  }

  bool get isCelsius => temperatureUnit.toUpperCase() == 'C';

  bool get isFahrenheit => temperatureUnit.toUpperCase() == 'F';

  bool get isKmh => windSpeedUnit.toLowerCase() == 'kmh';

  bool get isMph => windSpeedUnit.toLowerCase() == 'mph';

  String get temperatureSymbol {
    return isCelsius ? '°C' : '°F';
  }

  String get shortTemperatureSymbol {
    return isCelsius ? '°C' : '°F';
  }

  Color get accentColor {
    const colors = [
      Color(0xFF35B8FF),
      Color(0xFFD600FF),
      Color(0xFFFF2D2D),
      Color(0xFF00E85A),
      Color(0xFFFF8C1A),
      Color(0xFFFFC21A),
    ];

    if (themeIndex < 0 || themeIndex >= colors.length) {
      return colors.first;
    }

    return colors[themeIndex];
  }

  Color get backgroundColor {
    return isDarkMode ? const Color(0xFF050505) : const Color(0xFFF4F7FB);
  }

  Color get cardColor {
    return isDarkMode ? const Color(0xFF42557A) : Colors.white;
  }

  Color get textColor {
    return isDarkMode ? Colors.white : const Color(0xFF111827);
  }

  Color get subTextColor {
    return isDarkMode ? const Color(0xFFB6C0D4) : const Color(0xFF6B7280);
  }

  Color get softCardColor {
    return isDarkMode ? const Color(0xFF1A2744) : const Color(0xFFFFFFFF);
  }

  Color get borderColor {
    return isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFD8E1F0);
  }

  String formatTemperature(String value) {
    final double? number = _extractNumber(value);

    if (number == null) {
      return value;
    }

    if (isCelsius) {
      return '${number.round()}°';
    }

    final double fahrenheit = (number * 9 / 5) + 32;
    return '${fahrenheit.round()}°';
  }

  String formatTemperatureWithUnit(String value) {
    final double? number = _extractNumber(value);

    if (number == null) {
      return value;
    }

    if (isCelsius) {
      return '${number.round()}°C';
    }

    final double fahrenheit = (number * 9 / 5) + 32;
    return '${fahrenheit.round()}°F';
  }

  String formatWindSpeed(String value) {
    final double? number = _extractNumber(value);

    if (number == null) {
      return value;
    }

    final String lowerValue = value.toLowerCase();

    if (isKmh) {
      if (lowerValue.contains('mph')) {
        final double kmh = number / 0.621371;
        return '${kmh.round()} km/h';
      }

      return '${number.round()} km/h';
    }

    if (lowerValue.contains('mph')) {
      return '${number.round()} mph';
    }

    final double mph = number * 0.621371;
    return '${mph.round()} mph';
  }

  static double? _extractNumber(String value) {
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(value);

    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0) ?? '');
  }
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit()
      : super(
    const AppSettingsState(
      isDarkMode: true,
      themeIndex: 0,
      temperatureUnit: 'C',
      windSpeedUnit: 'kmh',
    ),
  );

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> loadSettings() async {
    final user = firebaseAuth.currentUser;

    if (user == null) return;

    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) return;

      final settings = data['settings'] as Map<String, dynamic>? ?? {};

      final bool darkMode = settings['darkMode'] ?? true;
      final int themeIndex = (settings['themeIndex'] as num?)?.toInt() ?? 0;

      final String temperatureUnit =
      (settings['temperatureUnit'] ?? 'C').toString().toUpperCase();

      final String windSpeedUnit =
      (settings['windSpeedUnit'] ?? 'kmh').toString().toLowerCase();

      emit(
        AppSettingsState(
          isDarkMode: darkMode,
          themeIndex: themeIndex,
          temperatureUnit: temperatureUnit == 'F' ? 'F' : 'C',
          windSpeedUnit: windSpeedUnit == 'mph' ? 'mph' : 'kmh',
        ),
      );
    } catch (_) {
      // If loading failed, keep default settings.
    }
  }

  Future<void> updateDarkMode(bool value) async {
    emit(
      state.copyWith(
        isDarkMode: value,
      ),
    );

    await _saveSetting('darkMode', value);
  }

  Future<void> updateThemeIndex(int index) async {
    emit(
      state.copyWith(
        themeIndex: index,
      ),
    );

    await _saveSetting('themeIndex', index);
  }

  Future<void> updateTemperatureUnit(String unit) async {
    final String value = unit.toUpperCase() == 'F' ? 'F' : 'C';

    emit(
      state.copyWith(
        temperatureUnit: value,
      ),
    );

    await _saveSetting('temperatureUnit', value);
  }

  Future<void> updateWindSpeedUnit(String unit) async {
    final String value = unit.toLowerCase() == 'mph' ? 'mph' : 'kmh';

    emit(
      state.copyWith(
        windSpeedUnit: value,
      ),
    );

    await _saveSetting('windSpeedUnit', value);
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final user = firebaseAuth.currentUser;

    if (user == null) return;

    try {
      await firestore.collection('users').doc(user.uid).set(
        {
          'settings': {
            key: value,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Later we can show error snackbar if needed.
    }
  }
}