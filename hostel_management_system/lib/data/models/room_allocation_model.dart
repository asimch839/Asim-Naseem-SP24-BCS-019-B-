class RoomAllocationModel {
  final int? id;
  final int studentId;
  final int roomId;
  final int bedId;
  final String startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD or null if current
  final String reason; // 'Admission', 'Room Change', 'Left'
  final String? notes;
  final String createdAt;

  // Joined fields
  final String? studentName;
  final String? studentIdCode;
  final String? roomNumber;
  final String? bedNumber;

  RoomAllocationModel({
    this.id,
    required this.studentId,
    required this.roomId,
    required this.bedId,
    required this.startDate,
    this.endDate,
    required this.reason,
    this.notes,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.roomNumber,
    this.bedNumber,
  });

  bool get isCurrent => endDate == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'room_id': roomId,
      'bed_id': bedId,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory RoomAllocationModel.fromMap(Map<String, dynamic> map) {
    return RoomAllocationModel(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      roomId: map['room_id'] as int,
      bedId: map['bed_id'] as int,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String?,
      reason: (map['reason'] as String?) ?? 'Admission',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
    );
  }
}
