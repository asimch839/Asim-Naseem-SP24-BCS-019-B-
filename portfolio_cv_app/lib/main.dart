import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/contact_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asim Portfolio',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F2027),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int? _hoveredIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AboutScreen(),
    const SkillsScreen(),
    const ProjectsScreen(),
    const ContactScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.person_rounded, 'label': 'About'},
    {'icon': Icons.code_rounded, 'label': 'Skills'},
    {'icon': Icons.rocket_launch_rounded, 'label': 'Projects'},
    {'icon': Icons.mail_rounded, 'label': 'Contact'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3339).withOpacity(0.95),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_navItems.length, (index) {
            bool isSelected = _selectedIndex == index;
            bool isHovered = _hoveredIndex == index;
            bool showLabel = isSelected || isHovered;
            
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: showLabel ? 18 : 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.blueAccent.withOpacity(0.2) 
                        : (isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: showLabel ? 1.2 : 1.0,
                        child: Icon(
                          _navItems[index]['icon'],
                          color: isSelected 
                              ? Colors.blueAccent 
                              : (isHovered ? Colors.white : Colors.white54),
                          size: 24,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: showLabel ? 18 : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: showLabel ? 1.0 : 0.0,
                          child: Text(
                            _navItems[index]['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.blueAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      extendBody: true,
    );
  }
}
