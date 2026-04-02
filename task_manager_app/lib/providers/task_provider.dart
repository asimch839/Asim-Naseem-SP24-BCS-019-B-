import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/history_model.dart';
import '../services/notification_service.dart';

class TaskController extends GetxController {
  var tasks = <TaskModel>[].obs;
  var history = <HistoryModel>[].obs;
  var isDark = false.obs;
  var notificationSound = 'ding'.obs;
  final _notif = NotificationService();
  
  static const String _tasksKey = 'stored_tasks';
  static const String _historyKey = 'stored_history';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _notif.init();
    await loadTasks();
    await loadHistory();
  }

  Future<void> _loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    isDark.value = sp.getBool('isDark') ?? false;
    notificationSound.value = sp.getString('notificationSound') ?? 'ding';
  }

  Future<void> toggleTheme() async {
    isDark.value = !isDark.value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('isDark', isDark.value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _saveToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await sp.setString(_tasksKey, encodedData);
  }

  Future<void> _saveHistoryToPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(history.map((h) => h.toMap()).toList());
    await sp.setString(_historyKey, encodedData);
  }

  Future<void> loadTasks() async {
    final sp = await SharedPreferences.getInstance();
    final String? tasksString = sp.getString(_tasksKey);
    if (tasksString != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(tasksString);
        tasks.assignAll(decodedData.map((item) => TaskModel.fromMap(item)).toList());
      } catch (e) {
        tasks.clear();
      }
    }
  }

  Future<void> loadHistory() async {
    final sp = await SharedPreferences.getInstance();
    final String? historyString = sp.getString(_historyKey);
    if (historyString != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(historyString);
        history.assignAll(decodedData.map((item) => HistoryModel.fromMap(item)).toList());
      } catch (e) {
        history.clear();
      }
    }
  }

  void _addToHistory(String title, String action) {
    history.insert(0, HistoryModel(
      id: DateTime.now().toString(),
      taskTitle: title,
      action: action,
      timestamp: DateTime.now(),
    ));
    _saveHistoryToPrefs();
  }

  Future<void> addTask(TaskModel t, {bool scheduleNotification = true}) async {
    t.id = DateTime.now().millisecondsSinceEpoch;
    tasks.add(t);
    _addToHistory(t.title, 'added');
    if (scheduleNotification && t.dueDate.isAfter(DateTime.now())) {
      await scheduleTaskNotification(t);
    }
    await _saveToPrefs();
  }

  Future<void> updateTask(TaskModel t, {bool scheduleNotification = true}) async {
    final index = tasks.indexWhere((element) => element.id == t.id);
    if (index != -1) {
      _addToHistory(t.title, 'edited');
      if (tasks[index].notificationId.isNotEmpty) {
        final oldId = int.tryParse(tasks[index].notificationId) ?? -1;
        if (oldId != -1) await _notif.cancelNotification(oldId);
      }
      if (scheduleNotification && t.dueDate.isAfter(DateTime.now()) && !t.isCompleted) {
        await scheduleTaskNotification(t);
      } else {
        t.notificationId = '';
      }
      tasks[index] = t;
      await _saveToPrefs();
    }
  }

  Future<void> deleteTask(TaskModel t) async {
    _addToHistory(t.title, 'deleted');
    if (t.notificationId.isNotEmpty) {
      final nid = int.tryParse(t.notificationId) ?? -1;
      if (nid != -1) await _notif.cancelNotification(nid);
    }
    tasks.removeWhere((element) => element.id == t.id);
    await _saveToPrefs();
  }

  Future<void> toggleTaskCompletion(TaskModel t) async {
    t.isCompleted = !t.isCompleted;
    t.progress = t.isCompleted ? 1.0 : 0.0;
    _addToHistory(t.title, t.isCompleted ? 'completed' : 'incomplete');
    if (t.isCompleted && t.notificationId.isNotEmpty) {
      final nid = int.tryParse(t.notificationId) ?? -1;
      if (nid != -1) await _notif.cancelNotification(nid);
      t.notificationId = '';
    }
    await updateTask(t);
  }

  Future<void> scheduleTaskNotification(TaskModel t) async {
    if (!t.isCompleted && t.dueDate.isAfter(DateTime.now())) {
      final nid = await _notif.scheduleNotification(
        title: t.title,
        body: t.description.isEmpty ? 'Task due' : t.description,
        scheduledDate: t.dueDate,
        taskId: t.id!,
        sound: notificationSound.value,
      );
      t.notificationId = nid.toString();
    }
  }

  void clearHistory() {
    history.clear();
    _saveHistoryToPrefs();
  }
}
