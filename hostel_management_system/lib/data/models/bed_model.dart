class BedModel {
  final int? id;
  final int roomId;
  final String bedNumber;
  final String bedStatus; // 'Available', 'Occupied', 'Maintenance'
  final int? currentStudentId;
  final String createdAt;
  final String? updatedAt;

  // Joined fields
  final String? roomNumber;
  final String? studentName;
  final String? studentIdCode;

  BedModel({
    this.id,
    required this.roomId,
    required this.bedNumber,
    this.bedStatus = 'Available',
    this.currentStudentId,
    required this.createdAt,
    this.updatedAt,
    this.roomNumber,
    this.studentName,
    this.studentIdCode,
  });

  bool get isAvailable => bedStatus == 'Available' && currentStudentId == null;
  bool get isOccupied => bedStatus == 'Occupied' || currentStudentId != null;
  bool get isMaintenance => bedStatus == 'Maintenance';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'bed_number': bedNumber,
      'bed_status': bedStatus,
      'current_student_id': currentStudentId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BedModel.fromMap(Map<String, dynamic> map) {
    return BedModel(
      id: map['id'] as int?,
      roomId: map['room_id'] as int,
      bedNumber: map['bed_number'] as String,
      bedStatus: (map['bed_status'] as String?) ?? 'Available',
      currentStudentId: map['current_student_id'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      roomNumber: map['room_number'] as String?,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
    );
  }

  BedModel copyWith({
    int? id,
    int? roomId,
    String? bedNumber,
    String? bedStatus,
    int? currentStudentId,
    String? createdAt,
    String? updatedAt,
    String? roomNumber,
    String? studentName,
    String? studentIdCode,
  }) {
    return BedModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      bedNumber: bedNumber ?? this.bedNumber,
      bedStatus: bedStatus ?? this.bedStatus,
      currentStudentId: currentStudentId ?? this.currentStudentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roomNumber: roomNumber ?? this.roomNumber,
      studentName: studentName ?? this.studentName,
      studentIdCode: studentIdCode ?? this.studentIdCode,
    );
  }
}
