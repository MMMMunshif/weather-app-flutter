import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/app_shell/presentation/pages/app_shell_page.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/settings/cubit/app_settings_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              details.exceptionAsString(),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const WeatherTravelApp());
  } catch (error) {
    runApp(
      FirebaseErrorApp(
        errorMessage: error.toString(),
      ),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String errorMessage;

  const FirebaseErrorApp({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Text(
              'Firebase initialization error:\n\n$errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherTravelApp extends StatelessWidget {
  const WeatherTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<AppSettingsCubit>(
          create: (context) => AppSettingsCubit()..loadSettings(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<AppSettingsCubit>().loadSettings();
          }
        },
        child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, settingsState) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Weather Travel App',
              theme: _buildTheme(settingsState),
              builder: (context, child) {
                return Container(
                  color: settingsState.backgroundColor,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 430,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return _SplashLoadingPage(
                      backgroundColor: settingsState.backgroundColor,
                      accentColor: settingsState.accentColor,
                    );
                  }

                  if (state is AuthAuthenticated) {
                    return const AppShellPage();
                  }

                  return const LoginPage();
                },
              ),
              routes: {
                '/login': (context) => const LoginPage(),
                '/signup': (context) => const SignupPage(),
                '/app': (context) => const AppShellPage(),
              },
              onUnknownRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme(AppSettingsState settingsState) {
    return ThemeData(
      useMaterial3: true,
      brightness:
      settingsState.isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: settingsState.backgroundColor,
      primaryColor: settingsState.accentColor,
      fontFamily: 'Roboto',

      colorScheme: ColorScheme.fromSeed(
        seedColor: settingsState.accentColor,
        brightness:
        settingsState.isDarkMode ? Brightness.dark : Brightness.light,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: settingsState.backgroundColor,
        foregroundColor: settingsState.textColor,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: settingsState.isDarkMode
            ? const Color(0xFF2E3B59)
            : const Color(0xFFE8EEF8),
        hintStyle: TextStyle(
          color: settingsState.subTextColor,
        ),
        labelStyle: TextStyle(
          color: settingsState.textColor,
        ),
        prefixIconColor: settingsState.subTextColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: settingsState.accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: settingsState.backgroundColor,
        selectedItemColor: settingsState.accentColor,
        unselectedItemColor: settingsState.textColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _SplashLoadingPage extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;

  const _SplashLoadingPage({
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      ),
    );
  }
}