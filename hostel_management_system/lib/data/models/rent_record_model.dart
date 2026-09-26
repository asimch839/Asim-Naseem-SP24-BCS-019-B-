class RentRecordModel {
  final int? id;
  final int studentId;
  final int roomId;
  final int bedId;
  final String rentMonth; // YYYY-MM
  final double rentAmount;
  final double paidAmount;
  final double remainingAmount;
  final String dueDate; // YYYY-MM-DD
  final String status; // 'Paid', 'Partial', 'Pending', 'Overdue'
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  // Joined fields
  final String? studentName;
  final String? studentIdCode;
  final String? studentPhone;
  final double? studentSecurityDeposit;
  final String? roomNumber;
  final String? bedNumber;

  RentRecordModel({
    this.id,
    required this.studentId,
    required this.roomId,
    required this.bedId,
    required this.rentMonth,
    required this.rentAmount,
    this.paidAmount = 0.0,
    required this.remainingAmount,
    required this.dueDate,
    this.status = 'Pending',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.studentName,
    this.studentIdCode,
    this.studentPhone,
    this.studentSecurityDeposit,
    this.roomNumber,
    this.bedNumber,
  });

  bool get isPaid => status == 'Paid';
  bool get isPartial => status == 'Partial';
  bool get isPending => status == 'Pending';
  bool get isOverdue => status == 'Overdue';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'room_id': roomId,
      'bed_id': bedId,
      'rent_month': rentMonth,
      'rent_amount': rentAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RentRecordModel.fromMap(Map<String, dynamic> map) {
    final rent = (map['rent_amount'] as num?)?.toDouble() ?? 0.0;
    final dbPaid = (map['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPayments = (map['total_payments_sum'] as num?)?.toDouble() ?? dbPaid;
    final paid = totalPayments > dbPaid ? totalPayments : dbPaid;
    final remaining = (map['remaining_amount'] as num?)?.toDouble() ?? (rent - dbPaid);
    return RentRecordModel(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      roomId: map['room_id'] as int,
      bedId: map['bed_id'] as int,
      rentMonth: map['rent_month'] as String,
      rentAmount: rent,
      paidAmount: paid,
      remainingAmount: remaining.clamp(0.0, double.infinity),
      dueDate: map['due_date'] as String,
      status: (map['status'] as String?) ?? 'Pending',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
      studentPhone: map['student_phone'] as String?,
      studentSecurityDeposit: (map['student_security_deposit'] as num?)?.toDouble() ?? (map['security_deposit'] as num?)?.toDouble(),
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
    );
  }

  RentRecordModel copyWith({
    int? id,
    int? studentId,
    int? roomId,
    int? bedId,
    String? rentMonth,
    double? rentAmount,
    double? paidAmount,
    double? remainingAmount,
    String? dueDate,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? studentName,
    String? studentIdCode,
    String? studentPhone,
    double? studentSecurityDeposit,
    String? roomNumber,
    String? bedNumber,
  }) {
    return RentRecordModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      roomId: roomId ?? this.roomId,
      bedId: bedId ?? this.bedId,
      rentMonth: rentMonth ?? this.rentMonth,
      rentAmount: rentAmount ?? this.rentAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      studentPhone: studentPhone ?? this.studentPhone,
      studentSecurityDeposit: studentSecurityDeposit ?? this.studentSecurityDeposit,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
    );
  }
}
