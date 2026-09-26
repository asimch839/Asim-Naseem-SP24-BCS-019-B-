class AdmissionModel {
  final int? id;
  final int studentId;
  final int roomId;
  final int bedId;
  final String admissionDate; // YYYY-MM-DD
  final double monthlyRent;
  final double securityDeposit;
  final String? notes;
  final String createdAt;

  // Joined fields
  final String? studentName;
  final String? studentIdCode;
  final String? roomNumber;
  final String? bedNumber;

  AdmissionModel({
    this.id,
    required this.studentId,
    required this.roomId,
    required this.bedId,
    required this.admissionDate,
    required this.monthlyRent,
    this.securityDeposit = 0.0,
    this.notes,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.roomNumber,
    this.bedNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'room_id': roomId,
      'bed_id': bedId,
      'admission_date': admissionDate,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory AdmissionModel.fromMap(Map<String, dynamic> map) {
    return AdmissionModel(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      roomId: map['room_id'] as int,
      bedId: map['bed_id'] as int,
      admissionDate: map['admission_date'] as String,
      monthlyRent: (map['monthly_rent'] as num?)?.toDouble() ?? 0.0,
      securityDeposit: (map['security_deposit'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
    );
  }
}
