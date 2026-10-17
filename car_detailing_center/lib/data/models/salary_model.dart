class SalaryPaymentEntry {
  final String id;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String? reference;

  SalaryPaymentEntry({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.reference,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'reference': reference,
    };
  }

  factory SalaryPaymentEntry.fromMap(Map<String, dynamic> map) {
    return SalaryPaymentEntry(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      reference: map['reference'],
    );
  }
}

class SalaryModel {
  final String id;
  final String businessId;
  final String staffId;
  final String staffName;
  final String month; // yyyy-MM
  final double basicSalary;
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final double overtimeAmount;
  final double bonusAmount;
  final double commissionAmount;
  final double advanceDeduction;
  final double otherDeduction;
  final double grossSalary;
  final double netSalary;
  final double paidAmount;
  final double remainingAmount;
  final String status; // Unpaid, Partial, Paid
  final List<SalaryPaymentEntry> paymentEntries;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalaryModel({
    required this.id,
    required this.businessId,
    required this.staffId,
    required this.staffName,
    required this.month,
    required this.basicSalary,
    this.presentDays = 0,
    this.absentDays = 0,
    this.halfDays = 0,
    this.overtimeAmount = 0.0,
    this.bonusAmount = 0.0,
    this.commissionAmount = 0.0,
    this.advanceDeduction = 0.0,
    this.otherDeduction = 0.0,
    double? grossSalary,
    required this.netSalary,
    this.paidAmount = 0.0,
    required this.remainingAmount,
    this.status = 'Unpaid',
    this.paymentEntries = const [],
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : grossSalary = grossSalary ?? (basicSalary + overtimeAmount + bonusAmount + commissionAmount),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SalaryModel copyWith({
    String? id,
    String? businessId,
    String? staffId,
    String? staffName,
    String? month,
    double? basicSalary,
    int? presentDays,
    int? absentDays,
    int? halfDays,
    double? overtimeAmount,
    double? bonusAmount,
    double? commissionAmount,
    double? advanceDeduction,
    double? otherDeduction,
    double? grossSalary,
    double? netSalary,
    double? paidAmount,
    double? remainingAmount,
    String? status,
    List<SalaryPaymentEntry>? paymentEntries,
    String? notes,
  }) {
    return SalaryModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      month: month ?? this.month,
      basicSalary: basicSalary ?? this.basicSalary,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      halfDays: halfDays ?? this.halfDays,
      overtimeAmount: overtimeAmount ?? this.overtimeAmount,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      advanceDeduction: advanceDeduction ?? this.advanceDeduction,
      otherDeduction: otherDeduction ?? this.otherDeduction,
      grossSalary: grossSalary ?? this.grossSalary,
      netSalary: netSalary ?? this.netSalary,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      paymentEntries: paymentEntries ?? this.paymentEntries,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'staffId': staffId,
      'staffName': staffName,
      'month': month,
      'basicSalary': basicSalary,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'halfDays': halfDays,
      'overtimeAmount': overtimeAmount,
      'bonusAmount': bonusAmount,
      'commissionAmount': commissionAmount,
      'advanceDeduction': advanceDeduction,
      'otherDeduction': otherDeduction,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'paymentEntries': paymentEntries.map((e) => e.toMap()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SalaryModel.fromMap(Map<String, dynamic> map, String docId) {
    return SalaryModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      month: map['month'] ?? '',
      basicSalary: (map['basicSalary'] as num?)?.toDouble() ?? 0.0,
      presentDays: (map['presentDays'] as num?)?.toInt() ?? 0,
      absentDays: (map['absentDays'] as num?)?.toInt() ?? 0,
      halfDays: (map['halfDays'] as num?)?.toInt() ?? 0,
      overtimeAmount: (map['overtimeAmount'] as num?)?.toDouble() ?? 0.0,
      bonusAmount: (map['bonusAmount'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (map['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      advanceDeduction: (map['advanceDeduction'] as num?)?.toDouble() ?? 0.0,
      otherDeduction: (map['otherDeduction'] as num?)?.toDouble() ?? 0.0,
      grossSalary: (map['grossSalary'] as num?)?.toDouble() ?? 0.0,
      netSalary: (map['netSalary'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Unpaid',
      paymentEntries: (map['paymentEntries'] as List<dynamic>?)
              ?.map((e) => SalaryPaymentEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
