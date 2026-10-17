import '../../core/constants/app_constants.dart';

class AttendanceModel {
  final String id; // Typically ${staffId}_${date}
  final String businessId;
  final String staffId;
  final String staffName;
  final String date; // yyyy-MM-dd
  final String status; // Present, Absent, Half Day, Leave
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.businessId,
    required this.staffId,
    required this.staffName,
    required this.date,
    this.status = AppConstants.attendancePresent,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  static String generateDocId(String staffId, String date) => '${staffId}_$date';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'staffId': staffId,
      'staffName': staffName,
      'date': date,
      'status': status,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? AppConstants.attendancePresent,
      checkInTime: map['checkInTime'] != null
          ? DateTime.tryParse(map['checkInTime'])
          : null,
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.tryParse(map['checkOutTime'])
          : null,
      notes: map['notes'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
