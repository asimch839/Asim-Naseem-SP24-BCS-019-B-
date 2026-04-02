import 'dart:convert';

class HistoryModel {
  final String id;
  final String taskTitle;
  final String action; // 'added', 'edited', 'deleted', 'completed', 'incomplete'
  final DateTime timestamp;

  HistoryModel({
    required this.id,
    required this.taskTitle,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskTitle': taskTitle,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryModel.fromMap(Map<String, dynamic> map) => HistoryModel(
    id: map['id'],
    taskTitle: map['taskTitle'],
    action: map['action'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
