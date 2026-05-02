import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C94FF);
  static const Color primaryDark = Color(0xFF4B43D9);
  static const Color secondary = Color(0xFFFF6584);
  static const Color accent = Color(0xFF43D9B3);

  // Light theme
  static const Color lightBackground = Color(0xFFF8F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E6FF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B8A);
  static const Color lightTextHint = Color(0xFFABABC0);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F0E17);
  static const Color darkSurface = Color(0xFF1A1929);
  static const Color darkCard = Color(0xFF211F36);
  static const Color darkBorder = Color(0xFF2D2B45);
  static const Color darkTextPrimary = Color(0xFFF5F4FF);
  static const Color darkTextSecondary = Color(0xFF9998B8);
  static const Color darkTextHint = Color(0xFF5C5A7A);

  // Priority colors
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityHigh = Color(0xFFFF5722);
  static const Color priorityUrgent = Color(0xFFE91E63);

  // Note card palette
  static const List<Color> noteCardColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF3E0),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFFFEBEE),
    Color(0xFFE0F7FA),
    Color(0xFFFFF8E1),
    Color(0xFFF1F8E9),
    Color(0xFFEDE7F6),
    Color(0xFFE8EAF6),
    Color(0xFFE0F2F1),
  ];

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Category colors
  static const List<Color> categoryColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43D9B3),
    Color(0xFFFFBF00),
    Color(0xFF4FC3F7),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9C94FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F0E17), Color(0xFF1A1929)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
