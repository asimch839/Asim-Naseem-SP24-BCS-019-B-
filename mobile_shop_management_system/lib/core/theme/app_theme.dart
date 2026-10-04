import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF0284C7); // Rich cyan blue
  static const Color darkNavy = Color(0xFF0F172A); // Slate 900
  static const Color sidebarBgLight = Color(0xFF1E293B); // Slate 800
  static const Color successGreen = Color(0xFF10B981); // Emerald
  static const Color warningOrange = Color(0xFFF59E0B); // Amber
  static const Color dangerRed = Color(0xFFEF4444); // Rose red
  static const Color purpleRepair = Color(0xFF8B5CF6); // Violet

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      surface: const Color(0xFFF8FAFC),
      error: dangerRed,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
        fontSize: 13,
      ),
      dataTextStyle: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 13,
      ),
      dividerThickness: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF38BDF8),
      surface: const Color(0xFF1E293B),
      error: dangerRed,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1120),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE2E8F0),
        side: const BorderSide(color: Color(0xFF475569)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFFE2E8F0),
        fontSize: 13,
      ),
      dataTextStyle: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 13,
      ),
      dividerThickness: 1,
    ),
  );
}
