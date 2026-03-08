import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/subject_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class AppColors {
  static const Color primary = Color(0xFF4e73df);
  static const Color secondary = Color(0xFF1cc88a);
  static const Color error = Colors.red;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quiz App',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primary,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/subjects': (context) => const SubjectScreen(),
            '/quiz': (context) => const QuizScreen(),
            '/result': (context) => const ResultScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/history': (context) => const HistoryScreen(),
          },
        );
      },
    );
  }
}