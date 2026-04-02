import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._private();
  static Database? _db;
  DBHelper._private();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('tasks.db');
    return _db!;
  }

  Future<Database> _initDB(String fname) async {
    Directory docDir = await getApplicationDocumentsDirectory();
    final path = join(docDir.path, fname);

    return await openDatabase(
      path,
      version: 2, // ✅ Increment version for schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create new DB
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER,
        repeatType TEXT,
        repeatDays TEXT,
        subtasks TEXT,
        progress REAL,
        notificationId TEXT,
        category TEXT
      )
    ''');
  }

  // Handle DB upgrades (adding new columns without deleting data)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN category TEXT');
    }
  }

  Future<int> insertTask(TaskModel t) async {
    final db = await database;
    return await db.insert('tasks', t.toMap());
  }

  Future<int> updateTask(TaskModel t) async {
    final db = await database;
    return await db.update('tasks', t.toMap(), where: 'id=?', whereArgs: [t.id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id=?', whereArgs: [id]);
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'dueDate ASC');
    return rows.map((r) => TaskModel.fromMap(r)).toList();
  }

  Future<TaskModel?> getTaskById(int id) async {
    final db = await database;
    final rows = await db.query('tasks', where: 'id=?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      return TaskModel.fromMap(rows.first);
    } else {
      return null;
    }
  }
}
