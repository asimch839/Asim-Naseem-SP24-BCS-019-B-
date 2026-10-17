import 'package:flutter/material.dart';

/// Design tokens and luxury color palette for AutoDetail Pro
class AppColors {
  // Brand Primaries
  static const Color primary = Color(0xFF0284C7); // Sky / Electric Cyan
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color accent = Color(0xFF06B6D4);

  // Dark Theme Backgrounds & Surfaces (Luxury Dark Mode)
  static const Color darkBackground = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF161F30);
  static const Color darkCardElevated = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF26334D);

  // Aliases for compatibility
  static const Color backgroundDark = darkBackground;
  static const Color cardDark = darkCard;
  static const Color borderDark = darkBorder;
  static const Color secondary = accent;

  // Light Theme Backgrounds & Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textLightPrimary = Color(0xFF0F172A);
  static const Color textLightSecondary = Color(0xFF64748B);
  static const Color textLightMuted = Color(0xFF94A3B8);

  static const Color textDarkPrimary = Color(0xFFF8FAFC);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textDarkMuted = Color(0xFF64748B);
  static const Color textDark = textDarkPrimary;
  static const Color textLight = textLightPrimary;

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFFDBEAFE);

  // Status Badges Colors for Jobs
  static Color getJobStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFF3B82F6); // Blue
      case 'Inspection Pending':
        return const Color(0xFF8B5CF6); // Purple
      case 'Waiting':
        return const Color(0xFFF59E0B); // Amber
      case 'In Progress':
        return const Color(0xFF06B6D4); // Cyan
      case 'Completed':
        return const Color(0xFF10B981); // Emerald
      case 'Ready for Delivery':
        return const Color(0xFF6366F1); // Indigo
      case 'Delivered':
        return const Color(0xFF059669); // Dark Green
      case 'Cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF161F30), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
