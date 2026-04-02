import 'subtask_model.dart';

class Task {
  int? id;
  String title;
  String description;
  DateTime? dueDate;
  bool isCompleted;
  String repeatType; // 'None', 'Daily', 'Weekly'
  List<String> repeatDays;
  List<Subtask> subtasks;
  double progress;
  String notificationId;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
    this.repeatType = 'None',
    this.repeatDays = const [],
    this.subtasks = const [],
    this.progress = 0.0,
    this.notificationId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'repeatType': repeatType,
      'repeatDays': repeatDays.join(','),
      'subtasks': subtasks.map((s) => s.toMap()).toList().toString(),
      'progress': progress,
      'notificationId': notificationId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    List<Subtask> subtaskList = [];
    try {
      final List<dynamic> decoded = (map['subtasks'] ?? []) is List
          ? (map['subtasks'] as List)
          : [];
      subtaskList = decoded.map((e) => Subtask.fromMap(e)).toList();
    } catch (_) {}

    return Task(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      isCompleted: map['isCompleted'] == 1,
      repeatType: map['repeatType'] ?? 'None',
      repeatDays: map['repeatDays'] != null
          ? (map['repeatDays'] as String).split(',')
          : [],
      subtasks: subtaskList,
      progress: (map['progress'] ?? 0.0).toDouble(),
      notificationId: map['notificationId'] ?? '',
    );
  }

  Task copy() => Task(
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
  );
}
