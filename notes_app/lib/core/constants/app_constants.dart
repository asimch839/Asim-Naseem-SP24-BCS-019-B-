import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = 'NoteVault';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Smart Notes Companion';

  // SharedPreferences keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyViewMode = 'view_mode'; // grid / list
  static const String keySortMode = 'sort_mode';

  // View modes
  static const String viewGrid = 'grid';
  static const String viewList = 'list';

  // Sort modes
  static const String sortNewest = 'newest';
  static const String sortOldest = 'oldest';
  static const String sortTitle = 'title';
  static const String sortPriority = 'priority';

  // Priority levels
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Medium';
  static const String priorityHigh = 'High';
  static const String priorityUrgent = 'Urgent';

  static const List<String> priorities = [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityUrgent,
  ];

  // Default categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Personal', 'icon': '👤', 'color': 0xFF6C63FF},
    {'name': 'Work', 'icon': '💼', 'color': 0xFF43D9B3},
    {'name': 'Study', 'icon': '📚', 'color': 0xFF4FC3F7},
    {'name': 'Business', 'icon': '🏢', 'color': 0xFFFFBF00},
    {'name': 'Ideas', 'icon': '💡', 'color': 0xFFFF9800},
    {'name': 'Important', 'icon': '⭐', 'color': 0xFFFF6584},
    {'name': 'Finance', 'icon': '💰', 'color': 0xFF4CAF50},
    {'name': 'Health', 'icon': '❤️', 'color': 0xFFE91E63},
  ];

  // Onboarding content
  static const List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Capture Your Thoughts',
      'subtitle':
          'Write notes instantly with rich text, images, and voice memos. Never lose an idea again.',
      'icon': Icons.edit_note_rounded,
      'color': 0xFF6C63FF,
    },
    {
      'title': 'Organize Everything',
      'subtitle':
          'Sort by categories, priorities, and tags. Find any note instantly with smart search.',
      'icon': Icons.folder_open_rounded,
      'color': 0xFFFF6584,
    },
    {
      'title': 'Stay on Track',
      'subtitle':
          'Set reminders, pin important notes, and track everything with a beautiful calendar view.',
      'icon': Icons.notifications_active_rounded,
      'color': 0xFF43D9B3,
    },
  ];

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 3);

  // Padding / spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 100.0;

  // Database
  static const String dbName = 'notevault.db';
  static const int dbVersion = 1;

  // Table names
  static const String tableNotes = 'notes';
  static const String tableCategories = 'categories';
  static const String tableReminders = 'reminders';
  static const String tablePreferences = 'user_preferences';
}
