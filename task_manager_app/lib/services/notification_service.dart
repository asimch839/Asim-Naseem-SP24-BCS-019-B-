import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/view_task_screen.dart';
import '../models/task_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String channelName = 'Task Notifications';
  static const String channelDescription = 'Reminders for your tasks';

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _createOrUpdateChannel();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'pending_tasks_channel',
      'Pending Tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await flutterLocalNotificationsPlugin.show(
      1000,
      title,
      body,
      details,
    );
  }

  Future<void> _handleNotificationTap(String payload) async {
    if (payload.startsWith('task:')) {
      final parts = payload.split(':');
      if (parts.length > 1) {
        final taskId = int.tryParse(parts[1]);
        if (taskId != null) {
          // Load task from SharedPreferences
          final sp = await SharedPreferences.getInstance();
          final String? tasksString = sp.getString('stored_tasks');
          if (tasksString != null) {
            final List<dynamic> decodedData = jsonDecode(tasksString);
            final tasks = decodedData.map((item) => TaskModel.fromMap(item)).toList();
            final task = tasks.firstWhere((t) => t.id == taskId);

            // Use Get.to for navigation (No navigatorKey needed)
            Get.to(() => ViewTaskScreen(task: task));
          }
        }
      }
    }
  }

  Future<void> _createOrUpdateChannel({String? soundName}) async {
    final prefs = await SharedPreferences.getInstance();
    final chosenSound = soundName ?? prefs.getString('notificationSound') ?? 'ding';
    final channelId = 'task_channel_$chosenSound';

    final androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(chosenSound),
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final channels = await androidPlugin?.getNotificationChannels();
    if (channels != null) {
      for (var ch in channels) {
        if (ch.id.startsWith('task_channel_') && ch.id != channelId) {
          await androidPlugin?.deleteNotificationChannel(ch.id);
        }
      }
    }

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  Future<void> updateNotificationSound(String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', soundName);
    await _createOrUpdateChannel(soundName: soundName);
  }

  Future<void> previewSound(String soundName) async {
    final androidDetails = AndroidNotificationDetails(
      'preview_channel_$soundName',
      'Preview Channel',
      channelDescription: 'Sound preview',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    final iosDetails = DarwinNotificationDetails(sound: '$soundName.mp3');

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 10000,
      '🔔 Sound Preview',
      'Playing "$soundName"',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int taskId,
    String? sound,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return -1;

    final prefs = await SharedPreferences.getInstance();
    final chosenSound = sound ?? prefs.getString('notificationSound') ?? 'ding';
    final channelId = 'task_channel_$chosenSound';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(chosenSound),
    );

    final iosDetails = DarwinNotificationDetails(sound: '$chosenSound.mp3');

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:$taskId',
    );

    return id;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
