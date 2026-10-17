import '../../core/constants/app_constants.dart';

class InvoiceItem {
  final String name;
  final String type; // 'service' or 'product' or 'other'
  final double quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.name,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      name: map['name'] ?? '',
      type: map['type'] ?? 'service',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String? vehicleId;
  final String? vehicleRegNumber;
  final String? vehicleDisplayName;
  final String? jobId;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double paidAmount;
  final double remainingAmount;
  final String status; // 'Unpaid', 'Partial', 'Paid'
  final String paymentMethod;
  final String? notes;
  final String? terms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    this.vehicleId,
    this.vehicleRegNumber,
    this.vehicleDisplayName,
    this.jobId,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    this.paidAmount = 0.0,
    required this.remainingAmount,
    this.status = AppConstants.paymentStatusUnpaid,
    this.paymentMethod = AppConstants.paymentCash,
    this.notes,
    this.terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isFullyPaid => remainingAmount <= 0.001;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'vehicleId': vehicleId,
      'vehicleRegNumber': vehicleRegNumber,
      'vehicleDisplayName': vehicleDisplayName,
      'jobId': jobId,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'terms': terms,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return InvoiceModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      invoiceNumber: map['invoiceNumber'] ?? '',
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'],
      vehicleId: map['vehicleId'],
      vehicleRegNumber: map['vehicleRegNumber'],
      vehicleDisplayName: map['vehicleDisplayName'],
      jobId: map['jobId'],
      items: (map['items'] as List<dynamic>?)
              ?.map((i) => InvoiceItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? AppConstants.paymentStatusUnpaid,
      paymentMethod: map['paymentMethod'] ?? AppConstants.paymentCash,
      notes: map['notes'],
      terms: map['terms'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  factory InvoiceModel.fromSqlite(Map<String, dynamic> map, [List<InvoiceItem>? items]) {
    final dateStr = map['date'] as String? ?? map['created_at'] as String? ?? '';
    final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
    return InvoiceModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      businessId: 'local',
      customerId: map['customer_id'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? 'Customer',
      customerPhone: map['customer_phone'] as String? ?? '',
      customerAddress: map['customer_address'] as String?,
      vehicleId: map['vehicle_id'] as String?,
      vehicleRegNumber: map['registration_number'] as String?,
      vehicleDisplayName: map['vehicle_name'] as String?,
      jobId: map['job_id'] as String?,
      items: items ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? AppConstants.paymentStatusUnpaid,
      paymentMethod: map['payment_method'] as String? ?? AppConstants.paymentCash,
      notes: map['notes'] as String?,
      terms: 'Payment due upon receipt.',
      createdAt: dt,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? dt,
      isDeleted: false,
    );
  }


  InvoiceModel copyWith({
    double? paidAmount,
    double? remainingAmount,
    String? status,
    String? paymentMethod,
    bool? isDeleted,
  }) {
    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      vehicleId: vehicleId,
      vehicleRegNumber: vehicleRegNumber,
      vehicleDisplayName: vehicleDisplayName,
      jobId: jobId,
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes,
      terms: terms,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
