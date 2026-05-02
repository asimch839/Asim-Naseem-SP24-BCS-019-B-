import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';
import '../models/note_model.dart';
import '../models/category_model.dart';
import '../models/reminder_model.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  Database? _dbInstance;
  Future<Database>? _dbInitFuture;

  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Future<Database> get database async {
    if (_dbInstance != null) return _dbInstance!;
    if (_dbInitFuture != null) return _dbInitFuture!;

    _dbInitFuture = _initDatabase().then((db) {
      _dbInstance = db;
      return db;
    });

    return _dbInitFuture!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Notes table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotes} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT DEFAULT '',
        description TEXT DEFAULT '',
        category TEXT DEFAULT 'Personal',
        priority TEXT DEFAULT 'Low',
        tags TEXT DEFAULT '',
        color_value INTEGER DEFAULT 4294967295,
        image_path TEXT,
        is_pinned INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        reminder_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCategories} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT '📁',
        color_value INTEGER DEFAULT 4284731135,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableReminders} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id TEXT NOT NULL,
        date_time TEXT NOT NULL,
        is_triggered INTEGER DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES ${AppConstants.tableNotes}(id) ON DELETE CASCADE
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE ${AppConstants.tablePreferences} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final cat in AppConstants.defaultCategories) {
      await db.insert(AppConstants.tableCategories, {
        'name': cat['name'],
        'icon': cat['icon'],
        'color_value': cat['color'],
        'is_default': 1,
        'created_at': now,
      });
    }
  }

  // ─────────────────── NOTES ───────────────────

  Future<String> insertNote(NoteModel note) async {
    final db = await database;
    await db.insert(
      AppConstants.tableNotes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return note.id;
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await database;
    return await db.update(
      AppConstants.tableNotes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNotePermanently(String id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<NoteModel?> getNoteById(String id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return NoteModel.fromMap(maps.first);
  }

  Future<List<NoteModel>> getAllActiveNotes() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'is_deleted = 0 AND is_archived = 0',
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> getFavoriteNotes() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'is_favorite = 1 AND is_deleted = 0 AND is_archived = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> getArchivedNotes() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'is_archived = 1 AND is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> getDeletedNotes() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'is_deleted = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> getNotesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'category = ? AND is_deleted = 0 AND is_archived = 0',
      whereArgs: [category],
      orderBy: 'updated_at DESC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> getNotesByDate(DateTime date) async {
    final db = await database;
    final dayStart =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      AppConstants.tableNotes,
      where: 'created_at >= ? AND created_at <= ? AND is_deleted = 0',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'created_at ASC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    final db = await database;
    final q = '%$query%';
    final maps = await db.query(
      AppConstants.tableNotes,
      where:
          '(title LIKE ? OR subtitle LIKE ? OR description LIKE ? OR tags LIKE ? OR category LIKE ? OR priority LIKE ?) AND is_deleted = 0',
      whereArgs: [q, q, q, q, q, q],
      orderBy: 'updated_at DESC',
    );
    return maps.map(NoteModel.fromMap).toList();
  }

  Future<int> getNoteCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableNotes} WHERE is_deleted = 0 AND is_archived = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFavoriteCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableNotes} WHERE is_favorite = 1 AND is_deleted = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPinnedCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableNotes} WHERE is_pinned = 1 AND is_deleted = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─────────────────── CATEGORIES ───────────────────

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCategories,
      orderBy: 'is_default DESC, name ASC',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      AppConstants.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableCategories,
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }

  // ─────────────────── REMINDERS ───────────────────

  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableReminders,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReminderModel>> getUpcomingReminders() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      AppConstants.tableReminders,
      where: 'date_time > ? AND is_triggered = 0',
      whereArgs: [now],
      orderBy: 'date_time ASC',
    );
    return maps.map(ReminderModel.fromMap).toList();
  }

  Future<int> deleteReminderByNoteId(String noteId) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableReminders,
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  // ─────────────────── CLOSE ───────────────────

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
