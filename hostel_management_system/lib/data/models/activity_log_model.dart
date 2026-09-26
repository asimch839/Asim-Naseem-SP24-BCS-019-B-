class ActivityLogModel {
  final int? id;
  final String activityType; // e.g., 'Admission', 'Payment', 'Room Allocation', 'Room Change', 'Student Left', 'Expense', etc.
  final String description;
  final int? userId;
  final String username;
  final int? studentId;
  final int? recordId;
  final String createdAt;

  // Joined fields
  final String? studentName;
  final String? studentIdCode;
  final String? roomNumber;

  ActivityLogModel({
    this.id,
    required this.activityType,
    required this.description,
    this.userId,
    required this.username,
    this.studentId,
    this.recordId,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.roomNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_type': activityType,
      'description': description,
      'user_id': userId,
      'username': username,
      'student_id': studentId,
      'record_id': recordId,
      'created_at': createdAt,
    };
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as int?,
      activityType: map['activity_type'] as String,
      description: map['description'] as String,
      userId: map['user_id'] as int?,
      username: (map['username'] as String?) ?? 'System',
      studentId: map['student_id'] as int?,
      recordId: map['record_id'] as int?,
      createdAt: map['created_at'] as String,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
      roomNumber: map['room_number'] as String?,
    );
  }
}
