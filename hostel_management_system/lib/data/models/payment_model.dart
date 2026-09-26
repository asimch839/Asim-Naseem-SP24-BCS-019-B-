class PaymentModel {
  final int? id;
  final int rentRecordId;
  final int studentId;
  final String receiptNumber;
  final double amount;
  final String paymentDate; // YYYY-MM-DD
  final String paymentMethod; // 'Cash', 'Bank Transfer', 'Other'
  final String? notes;
  final String createdAt;

  // Joined fields
  final String? studentName;
  final String? studentIdCode;
  final String? roomNumber;
  final String? bedNumber;
  final String? rentMonth;

  PaymentModel({
    this.id,
    required this.rentRecordId,
    required this.studentId,
    required this.receiptNumber,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.roomNumber,
    this.bedNumber,
    this.rentMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rent_record_id': rentRecordId,
      'student_id': studentId,
      'receipt_number': receiptNumber,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int?,
      rentRecordId: map['rent_record_id'] as int,
      studentId: map['student_id'] as int,
      receiptNumber: map['receipt_number'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['payment_date'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
      rentMonth: map['rent_month'] as String?,
    );
  }
}
