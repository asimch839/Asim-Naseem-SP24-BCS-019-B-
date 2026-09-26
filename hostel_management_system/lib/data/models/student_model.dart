class StudentModel {
  final int? id;
  final String studentIdCode; // e.g. STU-001
  final String fullName;
  final String fatherName;
  final String cnic;
  final String phone;
  final String emergencyContact;
  final String address;
  final String university;
  final String department;
  final String semester;
  final String admissionDate; // YYYY-MM-DD
  final int? currentRoomId;
  final int? currentBedId;
  final double monthlyRent;
  final double securityDeposit;
  final String status; // 'Active', 'Left'
  final String? leavingDate; // YYYY-MM-DD
  final String? profilePhoto;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  // Joined fields
  final String? roomNumber;
  final String? bedNumber;
  final String? currentRentStatus; // 'Paid', 'Pending', 'Overdue', 'Partial', 'No Bill'
  final double? currentRentRemaining;

  StudentModel({
    this.id,
    required this.studentIdCode,
    required this.fullName,
    required this.fatherName,
    required this.cnic,
    required this.phone,
    required this.emergencyContact,
    required this.address,
    required this.university,
    required this.department,
    required this.semester,
    required this.admissionDate,
    this.currentRoomId,
    this.currentBedId,
    required this.monthlyRent,
    this.securityDeposit = 0.0,
    this.status = 'Active',
    this.leavingDate,
    this.profilePhoto,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.roomNumber,
    this.bedNumber,
    this.currentRentStatus,
    this.currentRentRemaining,
  });

  bool get isActive => status == 'Active';
  bool get isLeft => status == 'Left';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id_code': studentIdCode,
      'full_name': fullName,
      'father_name': fatherName,
      'cnic': cnic,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'address': address,
      'university': university,
      'department': department,
      'semester': semester,
      'admission_date': admissionDate,
      'current_room_id': currentRoomId,
      'current_bed_id': currentBedId,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'status': status,
      'leaving_date': leavingDate,
      'profile_photo': profilePhoto,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as int?,
      studentIdCode: map['student_id_code'] as String,
      fullName: map['full_name'] as String,
      fatherName: (map['father_name'] as String?) ?? '',
      cnic: (map['cnic'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      emergencyContact: (map['emergency_contact'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      university: (map['university'] as String?) ?? '',
      department: (map['department'] as String?) ?? '',
      semester: (map['semester'] as String?) ?? '',
      admissionDate: map['admission_date'] as String,
      currentRoomId: map['current_room_id'] as int?,
      currentBedId: map['current_bed_id'] as int?,
      monthlyRent: (map['monthly_rent'] as num?)?.toDouble() ?? 0.0,
      securityDeposit: (map['security_deposit'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] as String?) ?? 'Active',
      leavingDate: map['leaving_date'] as String?,
      profilePhoto: map['profile_photo'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
      currentRentStatus: map['current_rent_status'] as String?,
      currentRentRemaining: (map['current_rent_remaining'] as num?)?.toDouble(),
    );
  }

  StudentModel copyWith({
    int? id,
    String? studentIdCode,
    String? fullName,
    String? fatherName,
    String? cnic,
    String? phone,
    String? emergencyContact,
    String? address,
    String? university,
    String? department,
    String? semester,
    String? admissionDate,
    int? currentRoomId,
    int? currentBedId,
    double? monthlyRent,
    double? securityDeposit,
    String? status,
    String? leavingDate,
    String? profilePhoto,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? roomNumber,
    String? bedNumber,
    String? currentRentStatus,
    double? currentRentRemaining,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      university: university ?? this.university,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      admissionDate: admissionDate ?? this.admissionDate,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      currentBedId: currentBedId ?? this.currentBedId,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      status: status ?? this.status,
      leavingDate: leavingDate ?? this.leavingDate,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      currentRentStatus: currentRentStatus ?? this.currentRentStatus,
      currentRentRemaining: currentRentRemaining ?? this.currentRentRemaining,
    );
  }
}
