class ExpenseModel {
  final String id;
  final String businessId;
  final String expenseType; // 'staff' or 'center'
  final String? staffId; // assigned technician ID
  final String? staffName; // assigned technician name
  final String name; // expense name (e.g., Rent, Supplies)
  final String? category; // kept for legacy data
  final String description;
  final double amount; // price
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
  final bool isCompleted; // marks expense as finished

  ExpenseModel({
    required this.id,
    this.businessId = 'local',
    this.expenseType = 'center',
    this.staffId,
    this.staffName,
    required this.name,
    this.category,
    String? description,
    required this.amount,
    DateTime? date,
    this.paymentMethod = 'Cash',
    this.vendorName,
    this.vendorCompany,
    this.vendorPhone,
    this.vendorAddress,
    this.referenceNumber,
    this.receiptUrl,
    this.notes,
    this.isSalaryPayment = false,
    DateTime? createdAt,
    this.isDeleted = false,
    this.isCompleted = false,
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
      'name': name,
      'category': category ?? name,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'vendor_name': vendorName,
      'vendor_company': vendorCompany,
      'vendor_contact': vendorPhone,
      'vendor_address': vendorAddress,
      'referenceNumber': referenceNumber,
      'receipt_path': receiptUrl,
      'notes': notes,
      'isSalaryPayment': isSalaryPayment ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExpenseModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? 'local',
      expenseType: map['expenseType'] ?? 'center',
      staffId: map['staffId'],
      staffName: map['staffName'],
      name: map['name'] ?? map['category'] ?? '',
      category: map['category'],
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      paymentMethod: map['payment_method'] ?? 'Cash',
      vendorName: map['vendor_name'] ?? map['payeeOrSupplier'],
      vendorCompany: map['vendor_company'],
      vendorPhone: map['vendor_contact'],
      vendorAddress: map['vendor_address'],
      referenceNumber: map['referenceNumber'] ?? map['reference'],
      receiptUrl: map['receipt_path'],
      notes: map['notes'],
      isSalaryPayment: (map['isSalaryPayment'] ?? 0) == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      isCompleted: (map['isCompleted'] ?? 0) == 1,
    );
  }
}
