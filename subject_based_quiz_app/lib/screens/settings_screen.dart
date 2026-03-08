import 'package:flutter/material.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return ListTile(
                title: const Text("Dark Mode"),
                subtitle: const Text("Enable professional dark theme"),
                trailing: Switch(
                  value: currentMode == ThemeMode.dark,
                  onChanged: (val) => themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light,
                ),
              );
            }
          ),
          ListTile(
            title: const Text("Notifications"), 
            subtitle: const Text("Manage quiz reminders"), 
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
          ),
          ListTile(
            title: const Text("Language"), 
            subtitle: const Text("Choose app language"), 
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen())),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(Icons.notifications_active, size: 64, color: AppColors.primary), 
            SizedBox(height: 16), 
            Text("Notifications are enabled", style: TextStyle(fontWeight: FontWeight.bold))
          ]
        )
      ),
    );
  }
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Language")),
      body: ListView(children: const [
        ListTile(title: Text("English (Default)"), trailing: Icon(Icons.check, color: AppColors.primary)),
        ListTile(title: Text("Urdu")),
        ListTile(title: Text("Spanish")),
      ]),
    );
  }
}
