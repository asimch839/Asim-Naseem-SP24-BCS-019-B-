class ReceiptModel {
  final int? id;
  final String receiptNumber;
  final int paymentId;
  final int studentId;
  final String rentMonth; // YYYY-MM
  final double amountPaid;
  final double remainingAmount;
  final String paymentDate; // YYYY-MM-DD
  final String paymentMethod; // 'Cash', 'Bank Transfer', 'Other'
  final String? pdfPath;
  final String createdAt;

  // Joined fields
  final String? studentName;
  final String? studentIdCode;
  final String? studentPhone;
  final String? roomNumber;
  final String? bedNumber;
  final double? rentAmount;
  final double? securityDeposit;

  ReceiptModel({
    this.id,
    required this.receiptNumber,
    required this.paymentId,
    required this.studentId,
    required this.rentMonth,
    required this.amountPaid,
    required this.remainingAmount,
    required this.paymentDate,
    required this.paymentMethod,
    this.pdfPath,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.studentPhone,
    this.roomNumber,
    this.bedNumber,
    this.rentAmount,
    this.securityDeposit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'payment_id': paymentId,
      'student_id': studentId,
      'rent_month': rentMonth,
      'amount_paid': amountPaid,
      'remaining_amount': remainingAmount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'pdf_path': pdfPath,
      'created_at': createdAt,
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] as int?,
      receiptNumber: map['receipt_number'] as String,
      paymentId: map['payment_id'] as int,
      studentId: map['student_id'] as int,
      rentMonth: map['rent_month'] as String,
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['payment_date'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      pdfPath: map['pdf_path'] as String?,
      createdAt: map['created_at'] as String,
      studentName: map['student_name'] as String?,
      studentIdCode: map['student_id_code'] as String?,
      studentPhone: map['student_phone'] as String?,
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
      rentAmount: (map['rent_amount'] as num?)?.toDouble(),
      securityDeposit: (map['student_security_deposit'] as num?)?.toDouble() ?? (map['security_deposit'] as num?)?.toDouble(),
    );
  }

  ReceiptModel copyWith({
    int? id,
    String? receiptNumber,
    int? paymentId,
    int? studentId,
    String? rentMonth,
    double? amountPaid,
    double? remainingAmount,
    String? paymentDate,
    String? paymentMethod,
    String? pdfPath,
    String? createdAt,
    String? studentName,
    String? studentIdCode,
    String? studentPhone,
    String? roomNumber,
    String? bedNumber,
    double? rentAmount,
    double? securityDeposit,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      paymentId: paymentId ?? this.paymentId,
      studentId: studentId ?? this.studentId,
      rentMonth: rentMonth ?? this.rentMonth,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      studentName: studentName ?? this.studentName,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      studentPhone: studentPhone ?? this.studentPhone,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      rentAmount: rentAmount ?? this.rentAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
    );
  }
}
