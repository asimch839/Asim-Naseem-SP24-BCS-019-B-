class ExpenseModel {
  final String id;
  final String businessId;
  final String expenseType; // 'staff' or 'center'
  final String? staffId;
  final String? staffName;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String? vendorName;
  final String? vendorCompany;
  final String? vendorPhone;
  final String? vendorAddress;
  final String? referenceNumber;
  final String? receiptUrl;
  final String? notes;
  final bool isSalaryPayment;
  final DateTime createdAt;
  final bool isDeleted;

  ExpenseModel({
    required this.id,
    this.businessId = 'local',
    this.expenseType = 'center',
    this.staffId,
    this.staffName,
    required this.category,
    String? description,
    required this.amount,
    DateTime? date,
    this.paymentMethod = 'Cash',
    this.vendorName,
    this.vendorCompany,
    this.vendorPhone,
    this.vendorAddress,
    this.referenceNumber,
    String? reference,
    String? payeeOrSupplier,
    this.receiptUrl,
    this.notes,
    this.isSalaryPayment = false,
    DateTime? createdAt,
    this.isDeleted = false,
  })  : description = description ?? '',
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  String? get reference => referenceNumber;
  String? get payeeOrSupplier => vendorName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'expenseType': expenseType,
      'staffId': staffId,
      'staffName': staffName,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'vendorName': vendorName,
      'vendorCompany': vendorCompany,
      'vendorPhone': vendorPhone,
      'vendorAddress': vendorAddress,
      'referenceNumber': referenceNumber,
      'receiptUrl': receiptUrl,
      'notes': notes,
      'isSalaryPayment': isSalaryPayment,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExpenseModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? 'local',
      expenseType: map['expenseType'] ?? 'center',
      staffId: map['staffId'],
      staffName: map['staffName'],
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      vendorName: map['vendorName'] ?? map['payeeOrSupplier'],
      vendorCompany: map['vendorCompany'],
      vendorPhone: map['vendorPhone'],
      vendorAddress: map['vendorAddress'],
      referenceNumber: map['referenceNumber'] ?? map['reference'],
      receiptUrl: map['receiptUrl'],
      notes: map['notes'],
      isSalaryPayment: map['isSalaryPayment'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
