import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/notes/note_editor_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/reminders/reminders_screen.dart';
import '../../screens/trash/trash_screen.dart';
import '../../screens/archive/archive_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../models/note_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String noteEditor = '/note-editor';
  static const String categories = '/categories';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String calendar = '/calendar';
  static const String reminders = '/reminders';
  static const String trash = '/trash';
  static const String archive = '/archive';
  static const String favorites = '/favorites';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case onboarding:
        return _slideRoute(const OnboardingScreen(), settings);
      case login:
        return _slideRoute(const LoginScreen(), settings);
      case register:
        return _slideRoute(const RegisterScreen(), settings);
      case forgotPassword:
        return _slideRoute(const ForgotPasswordScreen(), settings);
      case home:
        return _fadeRoute(const HomeScreen(), settings);
      case noteEditor:
        final note = settings.arguments as NoteModel?;
        return _slideRoute(NoteEditorScreen(note: note), settings);
      case categories:
        return _slideRoute(const CategoriesScreen(), settings);
      case profile:
        return _slideRoute(const ProfileScreen(), settings);
      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen(), settings);
      case search:
        return _fadeRoute(const SearchScreen(), settings);
      case calendar:
        return _slideRoute(const CalendarScreen(), settings);
      case reminders:
        return _slideRoute(const RemindersScreen(), settings);
      case trash:
        return _slideRoute(const TrashScreen(), settings);
      case archive:
        return _slideRoute(const ArchiveScreen(), settings);
      case favorites:
        return _slideRoute(const FavoritesScreen(), settings);
      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings routeSettings) {
    return PageRouteBuilder(
      settings: routeSettings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(
    Widget page,
    RouteSettings routeSettings,
  ) {
    return PageRouteBuilder(
      settings: routeSettings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
