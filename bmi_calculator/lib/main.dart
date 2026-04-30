import 'package:flutter/material.dart';
import 'screens/input_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? true;
  runApp(BMICalculator(isDarkMode: isDarkMode));
}

class BMICalculator extends StatefulWidget {
  final bool isDarkMode;
  const BMICalculator({super.key, required this.isDarkMode});

  static BMICalculatorState? of(BuildContext context) =>
      context.findAncestorStateOfType<BMICalculatorState>();

  @override
  State<BMICalculator> createState() => BMICalculatorState();
}

class BMICalculatorState extends State<BMICalculator> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: InputPage(),
    );
  }

  final ThemeData _darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0A0E21),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0E21),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: const Color(0xFFEB1555),
      secondary: const Color(0xFF1D1E33),
      surface: const Color(0xFF1D1E33),
    ),
  );

  final ThemeData _lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFFBFBFE),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: const Color(0xFF2D62ED),
      secondary: Colors.white,
      surface: Colors.white,
    ),
  );
}
