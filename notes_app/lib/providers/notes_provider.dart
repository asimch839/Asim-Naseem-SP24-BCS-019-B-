import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/note_model.dart';
import '../core/constants/app_constants.dart';

enum NotesStatus { idle, loading, loaded, error }

class NotesProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  final _uuid = const Uuid();

  List<NoteModel> _allNotes = [];
  List<NoteModel> _filteredNotes = [];
  NotesStatus _status = NotesStatus.idle;
  String _error = '';
  String _selectedCategory = '';
  String _selectedPriority = '';
  String _sortMode = AppConstants.sortNewest;
  String _viewMode = AppConstants.viewGrid;

  List<NoteModel> get allNotes => _allNotes;
  List<NoteModel> get filteredNotes => _filteredNotes;
  NotesStatus get status => _status;
  String get error => _error;
  String get selectedCategory => _selectedCategory;
  String get selectedPriority => _selectedPriority;
  String get sortMode => _sortMode;
  String get viewMode => _viewMode;

  List<NoteModel> get pinnedNotes => _allNotes
      .where((n) => n.isPinned && !n.isDeleted && !n.isArchived)
      .toList();

  List<NoteModel> get recentNotes {
    final active =
        _allNotes.where((n) => !n.isDeleted && !n.isArchived).toList();
    active.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active.take(10).toList();
  }

  Future<void> loadNotes() async {
    _status = NotesStatus.loading;
    notifyListeners();
    try {
      _allNotes = await _db.getAllActiveNotes();
      _applyFiltersAndSort();
      _status = NotesStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = NotesStatus.error;
    }
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    var notes = List<NoteModel>.from(_allNotes);

    if (_selectedCategory.isNotEmpty) {
      notes = notes.where((n) => n.category == _selectedCategory).toList();
    }
    if (_selectedPriority.isNotEmpty) {
      notes = notes.where((n) => n.priority == _selectedPriority).toList();
    }

    switch (_sortMode) {
      case AppConstants.sortNewest:
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case AppConstants.sortOldest:
        notes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case AppConstants.sortTitle:
        notes.sort((a, b) => a.title.compareTo(b.title));
        break;
      case AppConstants.sortPriority:
        const order = {
          AppConstants.priorityUrgent: 0,
          AppConstants.priorityHigh: 1,
          AppConstants.priorityMedium: 2,
          AppConstants.priorityLow: 3,
        };
        notes.sort((a, b) =>
            (order[a.priority] ?? 3).compareTo(order[b.priority] ?? 3));
        break;
    }

    // Pinned always on top
    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();
    _filteredNotes = [...pinned, ...unpinned];
  }

  void setCategory(String category) {
    _selectedCategory = _selectedCategory == category ? '' : category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setPriority(String priority) {
    _selectedPriority = _selectedPriority == priority ? '' : priority;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortMode(String mode) {
    _sortMode = mode;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }

  Future<NoteModel> createNote({
    required String title,
    String subtitle = '',
    String description = '',
    String category = 'Personal',
    String priority = 'Low',
    List<String> tags = const [],
    int colorValue = 0xFFFFFFFF,
    String? imagePath,
    DateTime? reminderDate,
  }) async {
    final note = NoteModel(
      id: _uuid.v4(),
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      priority: priority,
      tags: tags,
      colorValue: colorValue,
      imagePath: imagePath,
      reminderDate: reminderDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.insertNote(note);
    await loadNotes();
    return note;
  }

  Future<void> updateNote(NoteModel note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _db.updateNote(updated);
    await loadNotes();
  }

  Future<void> togglePin(NoteModel note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> toggleFavorite(NoteModel note) async {
    await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  Future<void> archiveNote(NoteModel note) async {
    await updateNote(note.copyWith(isArchived: true, isPinned: false));
  }

  Future<void> unarchiveNote(NoteModel note) async {
    await updateNote(note.copyWith(isArchived: false));
  }

  Future<void> moveToTrash(NoteModel note) async {
    await updateNote(
        note.copyWith(isDeleted: true, isArchived: false, isPinned: false));
  }

  Future<void> restoreFromTrash(NoteModel note) async {
    await updateNote(note.copyWith(isDeleted: false));
  }

  Future<void> deletePermanently(String id) async {
    await _db.deleteNotePermanently(id);
    await loadNotes();
  }

  Future<NoteModel> duplicateNote(NoteModel note) async {
    return await createNote(
      title: '${note.title} (Copy)',
      subtitle: note.subtitle,
      description: note.description,
      category: note.category,
      priority: note.priority,
      tags: List.from(note.tags),
      colorValue: note.colorValue,
    );
  }

  // Trash & Archive lists (loaded fresh)
  Future<List<NoteModel>> getTrashNotes() => _db.getDeletedNotes();
  Future<List<NoteModel>> getArchivedNotes() => _db.getArchivedNotes();
  Future<List<NoteModel>> getFavoriteNotes() => _db.getFavoriteNotes();
  Future<List<NoteModel>> getNotesByDate(DateTime date) =>
      _db.getNotesByDate(date);
}
