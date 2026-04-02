import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/task_provider.dart'; // Now contains TaskController
import '../services/notification_service.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TaskController controller = Get.find<TaskController>();
  String? selectedSound;
  final List<String> sounds = ['ding', 'chime', 'alert', 'cool', 'urgent'];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSelectedSound();
  }

  Future<void> _loadSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSound = prefs.getString('notificationSound') ?? 'ding';
    });
  }

  Future<void> _saveSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', sound);

    // Update notification channel with new sound
    final service = NotificationService();
    await service.updateNotificationSound(sound);

    setState(() => selectedSound = sound);
    Get.snackbar('Success', '✅ "$sound" selected as notification sound', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.7), colorText: Colors.white);
  }

  // ✅ Instant sound preview using audioplayers
  Future<void> _previewSound(String sound) async {
    try {
      await _audioPlayer.stop(); // Stop previous sound
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3')); // Play instantly
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  // ✅ Export CSV
  Future<void> _exportCSV() async {
    final tasks = controller.tasks;

    final rows = [
      ['Title', 'Description', 'Due Date', 'Completed', 'Repeat Type'],
      ...tasks.map((t) => [
        t.title,
        t.description,
        t.dueDate.toString(),
        t.isCompleted ? 'Yes' : 'No',
        t.repeatType,
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tasks.csv');
    await file.writeAsString(csv);
    await Share.shareFiles([file.path], text: '📋 My exported task list');
  }

  // ✅ Export PDF
  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('📝 Task Report',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...controller.tasks.map(
                  (t) => pw.Text(
                  '${t.title} - ${t.isCompleted ? "✅ Completed" : "❌ Pending"} (${t.dueDate})'),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tasks.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareFiles([file.path], text: '📄 Task list PDF');
  }

  // ✅ Export via Email
  Future<void> _exportEmail() async {
    final tasks = controller.tasks;

    final buffer = StringBuffer();
    buffer.writeln("📋 Task Report\n");
    for (var t in tasks) {
      buffer.writeln(
          "- ${t.title} (${t.isCompleted ? '✅ Done' : '❌ Pending'}) | Due: ${t.dueDate}\n");
    }

    final email = Email(
      subject: '📝 My Task Report',
      body: buffer.toString(),
      recipients: [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      Get.snackbar('Email', '📨 Email composer opened successfully!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.7), colorText: Colors.white);
    } catch (e) {
      // fallback
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tasks.txt');
      await file.writeAsString(buffer.toString());
      await Share.shareFiles([file.path], text: '📋 My Task Report');

      Get.snackbar('Warning', '⚠️ No email client found — shared via available apps', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.withOpacity(0.7), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings & Export'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('🌓 Appearance'),
          _buildCard(
            context,
            child: Obx(() => SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontSize: 16)),
              value: controller.isDark.value,
              onChanged: (_) => controller.toggleTheme(),
              secondary: const Icon(Icons.dark_mode),
            )),
          ),
          const SizedBox(height: 10),
          _buildSectionTitle('📜 Activity Log'),
          _buildCard(
            context,
            child: ListTile(
              leading: Icon(Icons.history, color: colorScheme.primary),
              title: const Text('View Task History'),
              subtitle: const Text('See added, edited, deleted and completed tasks'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.to(() => const HistoryScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionTitle('🔔 Notification Sound'),
          _buildCard(
            context,
            child: Column(
              children: sounds.map((sound) {
                return ListTile(
                  leading: Radio<String>(
                    value: sound,
                    groupValue: selectedSound,
                    onChanged: (value) {
                      if (value != null) _saveSound(value);
                    },
                  ),
                  title: Text(
                    sound[0].toUpperCase() + sound.substring(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_arrow, color: colorScheme.primary),
                    onPressed: () => _previewSound(sound), // instant preview
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionTitle('📤 Export Options'),
          _buildCard(
            context,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.download, color: colorScheme.primary),
                  title: const Text('Export to CSV'),
                  onTap: () => _exportCSV(),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: colorScheme.primary),
                  title: const Text('Export to PDF'),
                  onTap: () => _exportPDF(),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.email, color: colorScheme.primary),
                  title: const Text('Export via Email'),
                  onTap: () => _exportEmail(),
                ),
              ],
            ),
          ),
          _buildSectionTitle('🧪 Test Notification'),
          _buildCard(
            context,
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: colorScheme.primary),
              title: const Text('Test Selected Sound'),
              subtitle: const Text('Play your chosen notification sound instantly'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final sound = prefs.getString('notificationSound') ?? 'ding';
                await _previewSound(sound); // instant preview
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    ),
  );

  Widget _buildCard(BuildContext context, {required Widget child}) => Card(
    elevation: 4,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: child,
    ),
  );
}
