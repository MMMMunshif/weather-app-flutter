import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSettingsState {
  final bool isDarkMode;
  final int themeIndex;

  const AppSettingsState({
    required this.isDarkMode,
    required this.themeIndex,
  });

  AppSettingsState copyWith({
    bool? isDarkMode,
    int? themeIndex,
  }) {
    return AppSettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeIndex: themeIndex ?? this.themeIndex,
    );
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
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit()
      : super(
    const AppSettingsState(
      isDarkMode: true,
      themeIndex: 0,
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

      emit(
        AppSettingsState(
          isDarkMode: darkMode,
          themeIndex: themeIndex,
        ),
      );
    } catch (_) {
      // If loading failed, keep default dark blue theme.
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