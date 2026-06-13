import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/cubit/app_settings_cubit.dart';
import '../../../../features/weather/presentation/pages/weather_home_page.dart';
import '../../../../placeholder_pages/forecast_page.dart';
import '../../../../placeholder_pages/settings_page.dart';
import '../../../../placeholder_pages/trip_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    WeatherHomePage(),
    TripPage(),
    ForecastPage(),
    SettingsPage(),
  ];

  void _changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<AppSettingsCubit>().state;

    return Scaffold(
      backgroundColor: settingsState.backgroundColor,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: selectedIndex,
        onTap: _changeTab,
        backgroundColor: settingsState.backgroundColor,
        barColor: settingsState.isDarkMode
            ? const Color(0xFF050505)
            : const Color(0xFFF4F7FB),
        borderColor: settingsState.isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        selectedColor: settingsState.accentColor,
        unselectedColor: settingsState.isDarkMode
            ? Colors.white.withValues(alpha: 0.92)
            : const Color(0xFF111827),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;
  final Color barColor;
  final Color borderColor;
  final Color selectedColor;
  final Color unselectedColor;

  const _CustomBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.backgroundColor,
    required this.barColor,
    required this.borderColor,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          width: double.infinity,
          decoration: BoxDecoration(
            color: barColor,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                index: 0,
                selectedIndex: selectedIndex,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.flight_rounded,
                index: 1,
                selectedIndex: selectedIndex,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                index: 2,
                selectedIndex: selectedIndex,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                index: 3,
                selectedIndex: selectedIndex,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int selectedIndex;
  final Color selectedColor;
  final Color unselectedColor;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.selectedIndex,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? selectedColor : unselectedColor,
            ),
          ),
        ),
      ),
    );
  }
}