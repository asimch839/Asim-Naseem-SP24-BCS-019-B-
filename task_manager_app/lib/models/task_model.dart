import 'dart:convert';
import 'subtask_model.dart';

class TaskModel {
  int? id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  String repeatType; // 'none', 'daily', 'weekly', 'custom'
  List<String> repeatDays; // ['Mon','Tue'...]
  List<Subtask> subtasks;
  double progress;
  String notificationId;
  String? category; // ✅ New field for task category

  TaskModel({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.repeatType = 'none',
    this.repeatDays = const [],
    this.subtasks = const [],
    this.progress = 0.0,
    this.notificationId = '',
    this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'isCompleted': isCompleted ? 1 : 0,
    'repeatType': repeatType,
    'repeatDays': repeatDays.join(','),
    'subtasks': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
    'progress': progress,
    'notificationId': notificationId,
    'category': category, // ✅ Save category
  };

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    List<Subtask> subtaskList = [];
    if (map['subtasks'] != null && map['subtasks'] != '') {
      try {
        final List<dynamic> decoded = jsonDecode(map['subtasks']);
        subtaskList =
            decoded.map((e) => Subtask.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {
        subtaskList = [];
      }
    }

    return TaskModel(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      repeatType: map['repeatType'] ?? 'none',
      repeatDays: map['repeatDays'] != null && map['repeatDays'] != ''
          ? (map['repeatDays'] as String).split(',')
          : [],
      subtasks: subtaskList,
      progress: (map['progress'] ?? 0.0).toDouble(),
      notificationId: map['notificationId'] ?? '',
      category: map['category'], // ✅ Load category
    );
  }

  TaskModel copy() => TaskModel(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate,
    isCompleted: isCompleted,
    repeatType: repeatType,
    repeatDays: List<String>.from(repeatDays),
    subtasks: subtasks.map((s) => s.copy()).toList(),
    progress: progress,
    notificationId: notificationId,
    category: category, // ✅ Copy category
  );
}
