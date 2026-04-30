import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> historyData = prefs.getStringList('bmi_history') ?? [];
    
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _history = historyData
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('bmi_history');
    setState(() {
      _history = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isCurrentlyDark ? const Color(0xFF0A0E21) : const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: Text('Settings', 
            style: TextStyle(
                color: isCurrentlyDark ? Colors.white : Colors.black, 
                fontWeight: FontWeight.bold)),
        backgroundColor: isCurrentlyDark ? const Color(0xFF0A0E21) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isCurrentlyDark ? Colors.white : Colors.black),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('History'),
          if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isCurrentlyDark ? const Color(0xFF1D1E33) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('No BMI history found', 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isCurrentlyDark ? const Color(0xFF1D1E33) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          item['bmi'].toString(),
                          style: const TextStyle(
                              color: Colors.blue, 
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['result'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: isCurrentlyDark ? Colors.white : Colors.black),
                            ),
                            Text(
                              '${item['weight']}kg • ${item['height']}cm • Age: ${item['age']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['date'].toString().split('T')[0],
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History?'),
                    content: const Text('This will delete all saved BMI records.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                      TextButton(onPressed: () {
                        _clearHistory();
                        Navigator.pop(context);
                      }, child: const Text('CLEAR', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              label: const Text('Clear All History', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
          const SizedBox(height: 30),
          _buildSectionHeader('Preferences'),
          Container(
            decoration: BoxDecoration(
              color: isCurrentlyDark ? const Color(0xFF1D1E33) : Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: Colors.blue),
              title: Text('Dark Mode', 
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isCurrentlyDark ? Colors.white : Colors.black)),
              trailing: Switch(
                value: _isDarkMode,
                activeColor: const Color(0xFFEB1555),
                onChanged: (bool value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  BMICalculator.of(context)?.toggleTheme(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            icon: Icons.notifications_none_outlined,
            title: 'Notifications',
            subtitle: 'Reminders',
            isDark: isCurrentlyDark,
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About App',
            subtitle: 'Version 1.0.0',
            isDark: isCurrentlyDark,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BMI Calculator',
                applicationVersion: '1.0.0',
                children: [const Text('A professional BMI Calculator made with Flutter.')],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.blue.shade700, 
            fontWeight: FontWeight.bold, 
            fontSize: 12,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, 
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white54 : Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
