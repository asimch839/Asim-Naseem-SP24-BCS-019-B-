import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/note_model.dart';

class SearchProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  String _query = '';
  List<NoteModel> _results = [];
  bool _searching = false;

  String get query => _query;
  List<NoteModel> get results => _results;
  bool get searching => _searching;
  bool get hasQuery => _query.isNotEmpty;

  Future<void> search(String query) async {
    _query = query;
    if (query.trim().isEmpty) {
      _results = [];
      _searching = false;
      notifyListeners();
      return;
    }
    _searching = true;
    notifyListeners();
    try {
      _results = await _db.searchNotes(query.trim());
    } catch (_) {
      _results = [];
    }
    _searching = false;
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _results = [];
    _searching = false;
    notifyListeners();
  }
}
