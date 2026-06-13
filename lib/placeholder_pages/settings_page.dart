import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/settings/cubit/app_settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  String userName = 'User';
  String userEmail = '';

  bool isFahrenheit = false;
  bool isMph = false;

  bool severeWeatherAlerts = true;
  bool dailyForecast = true;
  bool precipitationAlerts = true;
  bool darkMode = true;

  int selectedThemeIndex = 0;

  final List<Color> themeColors = const [
    Color(0xFF35B8FF),
    Color(0xFFD600FF),
    Color(0xFFFF2D2D),
    Color(0xFF00E85A),
    Color(0xFFFF8C1A),
    Color(0xFFFFC21A),
  ];

  Color get accentColor {
    if (selectedThemeIndex < 0 || selectedThemeIndex >= themeColors.length) {
      return themeColors.first;
    }

    return themeColors[selectedThemeIndex];
  }

  Color get backgroundColor {
    return darkMode ? const Color(0xFF050505) : const Color(0xFFF4F7FB);
  }

  Color get cardColor {
    return darkMode ? const Color(0xFF42557A) : Colors.white;
  }

  Color get secondCardColor {
    return darkMode ? const Color(0xFF2B3650) : const Color(0xFFE8EEF8);
  }

  Color get textColor {
    return darkMode ? Colors.white : const Color(0xFF111827);
  }

  Color get subTextColor {
    return darkMode ? const Color(0xFFB6C0D4) : const Color(0xFF6B7280);
  }

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) {
        setState(() {
          userName = user.displayName ?? 'User';
          userEmail = user.email ?? '';
          isLoading = false;
        });
        return;
      }

      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      final int savedThemeIndex =
          (settings['themeIndex'] as num?)?.toInt() ?? 0;

      setState(() {
        userName = (data['name'] ?? user.displayName ?? 'User').toString();
        userEmail = (data['email'] ?? user.email ?? '').toString();

        isFahrenheit = settings['temperatureUnit'] == 'F';
        isMph = settings['windSpeedUnit'] == 'mph';
        darkMode = settings['darkMode'] ?? true;

        severeWeatherAlerts = settings['severeWeatherAlerts'] ?? true;
        dailyForecast = settings['dailyForecast'] ?? true;
        precipitationAlerts = settings['precipitationAlerts'] ?? true;

        selectedThemeIndex = savedThemeIndex
            .clamp(0, themeColors.length - 1)
            .toInt();

        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load settings.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
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
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save setting.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: backgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _ProfileCard(
                  name: userName,
                  email: userEmail,
                  cardColor: cardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

                const SizedBox(height: 24),

                _SectionLabel(
                  title: 'Units',
                  textColor: textColor,
                ),

                const SizedBox(height: 8),

                _UnitTile(
                  title: 'Temperature',
                  leftLabel: '°C',
                  rightLabel: '°F',
                  isRightSelected: isFahrenheit,
                  cardColor: cardColor,
                  toggleBgColor: secondCardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (value) {
                    setState(() => isFahrenheit = value);

                    context.read<AppSettingsCubit>().updateTemperatureUnit(
                      value ? 'F' : 'C',
                    );
                  },
                ),

                const SizedBox(height: 8),

                _UnitTile(
                  title: 'Wind Speed',
                  leftLabel: 'km/h',
                  rightLabel: 'mph',
                  isRightSelected: isMph,
                  cardColor: cardColor,
                  toggleBgColor: secondCardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (value) {
                    setState(() => isMph = value);

                    context.read<AppSettingsCubit>().updateWindSpeedUnit(
                      value ? 'mph' : 'kmh',
                    );
                  },
                ),

                const SizedBox(height: 24),

                _SectionLabel(
                  title: 'Notifications',
                  textColor: textColor,
                ),

                const SizedBox(height: 8),

                _SwitchTile(
                  title: 'Severe Weather Alerts',
                  value: severeWeatherAlerts,
                  cardColor: cardColor,
                  switchOffColor: secondCardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  onChanged: (value) {
                    setState(() => severeWeatherAlerts = value);
                    _updateSetting('severeWeatherAlerts', value);
                  },
                ),

                const SizedBox(height: 8),

                _SwitchTile(
                  title: 'Daily Forecast',
                  value: dailyForecast,
                  cardColor: cardColor,
                  switchOffColor: secondCardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  onChanged: (value) {
                    setState(() => dailyForecast = value);
                    _updateSetting('dailyForecast', value);
                  },
                ),

                const SizedBox(height: 8),

                _SwitchTile(
                  title: 'Precipitation Alerts',
                  value: precipitationAlerts,
                  cardColor: cardColor,
                  switchOffColor: secondCardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  onChanged: (value) {
                    setState(() => precipitationAlerts = value);
                    _updateSetting('precipitationAlerts', value);
                  },
                ),

                const SizedBox(height: 24),

                _SectionLabel(
                  title: 'Appearance',
                  textColor: textColor,
                ),

                const SizedBox(height: 8),

                _SwitchTile(
                  title: 'Dark Mode',
                  value: darkMode,
                  cardColor: cardColor,
                  switchOffColor: secondCardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  onChanged: (value) {
                    setState(() => darkMode = value);

                    // Important: idhu global cubit update pannum.
                    // So Home / Trip / Forecast pages immediate-a change aagum.
                    context.read<AppSettingsCubit>().updateDarkMode(value);
                  },
                ),

                const SizedBox(height: 8),

                _ColorThemeTile(
                  colors: themeColors,
                  selectedIndex: selectedThemeIndex,
                  cardColor: cardColor,
                  textColor: textColor,
                  onSelected: (index) {
                    setState(() => selectedThemeIndex = index);

                    // Important: idhu global cubit update pannum.
                    // So other pages immediate-a selected color use pannum.
                    context.read<AppSettingsCubit>().updateThemeIndex(index);
                  },
                ),

                const SizedBox(height: 24),

                _SectionLabel(
                  title: 'Account',
                  textColor: textColor,
                ),

                const SizedBox(height: 8),

                _LogoutTile(
                  onLogout: _logout,
                ),

                const SizedBox(height: 24),

                _SectionLabel(
                  title: 'About Us',
                  textColor: textColor,
                ),

                const SizedBox(height: 8),

                _AboutTile(
                  cardColor: cardColor,
                  accentColor: accentColor,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'User' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty || name.trim().isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final Color textColor;

  const _SectionLabel({
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final String title;
  final String leftLabel;
  final String rightLabel;
  final bool isRightSelected;
  final Color cardColor;
  final Color toggleBgColor;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final ValueChanged<bool> onChanged;

  const _UnitTile({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.isRightSelected,
    required this.cardColor,
    required this.toggleBgColor,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 50,
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _SegmentedToggle(
            leftLabel: leftLabel,
            rightLabel: rightLabel,
            isRightSelected: isRightSelected,
            bgColor: toggleBgColor,
            accentColor: accentColor,
            subTextColor: subTextColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isRightSelected;
  final Color bgColor;
  final Color accentColor;
  final Color subTextColor;
  final ValueChanged<bool> onChanged;

  const _SegmentedToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isRightSelected,
    required this.bgColor,
    required this.accentColor,
    required this.subTextColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: leftLabel,
            isSelected: !isRightSelected,
            accentColor: accentColor,
            subTextColor: subTextColor,
            onTap: () => onChanged(false),
          ),
          _Segment(
            label: rightLabel,
            isSelected: isRightSelected,
            accentColor: accentColor,
            subTextColor: subTextColor,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color subTextColor;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.subTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 28,
        constraints: const BoxConstraints(
          minWidth: 42,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : subTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final Color cardColor;
  final Color switchOffColor;
  final Color accentColor;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.cardColor,
    required this.switchOffColor,
    required this.accentColor,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _Toggle(
            value: value,
            accentColor: accentColor,
            offColor: switchOffColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  final Color accentColor;
  final Color offColor;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.value,
    required this.accentColor,
    required this.offColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 28,
        width: 50,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? accentColor : offColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            height: 22,
            width: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorThemeTile extends StatelessWidget {
  final List<Color> colors;
  final int selectedIndex;
  final Color cardColor;
  final Color textColor;
  final ValueChanged<int> onSelected;

  const _ColorThemeTile({
    required this.colors,
    required this.selectedIndex,
    required this.cardColor,
    required this.textColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color Theme',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(colors.length, (index) {
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 14),
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: colors[index].withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 17,
                  )
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutTile({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.35),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.redAccent,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final Color cardColor;
  final Color accentColor;
  final Color textColor;

  const _AboutTile({
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Designed by Mohammed Munshif',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'in',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}