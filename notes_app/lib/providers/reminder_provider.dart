import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/reminder_model.dart';

class ReminderProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<ReminderModel> _reminders = [];
  bool _loading = false;

  List<ReminderModel> get reminders => _reminders;
  bool get loading => _loading;

  List<ReminderModel> get upcomingReminders =>
      _reminders.where((r) => r.dateTime.isAfter(DateTime.now())).toList();

  Future<void> loadReminders() async {
    _loading = true;
    notifyListeners();
    _reminders = await _db.getUpcomingReminders();
    _loading = false;
    notifyListeners();
  }

  Future<void> addReminder(ReminderModel reminder) async {
    await _db.insertReminder(reminder);
    await loadReminders();
  }

  Future<void> removeReminderByNote(String noteId) async {
    await _db.deleteReminderByNoteId(noteId);
    await loadReminders();
  }
}
