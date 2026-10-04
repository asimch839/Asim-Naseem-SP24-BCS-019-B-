class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String module;
  final String recordId;
  final String details;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    this.recordId = '',
    required this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'module': module,
      'record_id': recordId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? '',
      userName: (map['user_name'] as String?) ?? '',
      action: (map['action'] as String?) ?? '',
      module: (map['module'] as String?) ?? '',
      recordId: (map['record_id'] as String?) ?? '',
      details: (map['details'] as String?) ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
