import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/note_model.dart';

class DashboardProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  int _totalNotes = 0;
  int _favoriteCount = 0;
  int _pinnedCount = 0;
  List<NoteModel> _recentNotes = [];
  Map<String, int> _categoryStats = {};
  bool _loading = false;

  int get totalNotes => _totalNotes;
  int get favoriteCount => _favoriteCount;
  int get pinnedCount => _pinnedCount;
  List<NoteModel> get recentNotes => _recentNotes;
  Map<String, int> get categoryStats => _categoryStats;
  bool get loading => _loading;

  Future<void> loadDashboard() async {
    _loading = true;
    notifyListeners();
    try {
      _totalNotes = await _db.getNoteCount();
      _favoriteCount = await _db.getFavoriteCount();
      _pinnedCount = await _db.getPinnedCount();

      final all = await _db.getAllActiveNotes();
      all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _recentNotes = all.take(6).toList();

      // Build category stats
      _categoryStats = {};
      for (final note in all) {
        _categoryStats[note.category] =
            (_categoryStats[note.category] ?? 0) + 1;
      }
    } catch (e) {
      print("Dashboard Error: $e");
    }
    _loading = false;
    notifyListeners();
  }
}
