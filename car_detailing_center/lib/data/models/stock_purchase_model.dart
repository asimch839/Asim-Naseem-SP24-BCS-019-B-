class StockPurchaseModel {
  final String id;
  final String businessId;
  final String supplierId;
  final String supplierName;
  final String itemId;
  final String itemName;
  final double quantity;
  final double purchasePricePerUnit;
  final double totalCost;
  final double retailPricePerUnit;
  final DateTime purchaseDate;
  final String? invoiceNumber;
  final String paymentStatus; // 'Paid', 'Partial', 'Unpaid'
  final double paidAmount;
  final double remainingAmount;
  final String? notes;
  final String? batchNumber;
  final DateTime createdAt;

  StockPurchaseModel({
    required this.id,
    required this.businessId,
    required this.supplierId,
    required this.supplierName,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.purchasePricePerUnit,
    required this.totalCost,
    required this.retailPricePerUnit,
    DateTime? purchaseDate,
    this.invoiceNumber,
    this.paymentStatus = 'Paid',
    this.paidAmount = 0.0,
    required this.remainingAmount,
    this.notes,
    this.batchNumber,
    DateTime? createdAt,
  })  : purchaseDate = purchaseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'purchasePricePerUnit': purchasePricePerUnit,
      'totalCost': totalCost,
      'retailPricePerUnit': retailPricePerUnit,
      'purchaseDate': purchaseDate.toIso8601String(),
      'invoiceNumber': invoiceNumber,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'notes': notes,
      'batchNumber': batchNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockPurchaseModel.fromMap(Map<String, dynamic> map, String docId) {
    return StockPurchaseModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      purchasePricePerUnit: (map['purchasePricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      retailPricePerUnit: (map['retailPricePerUnit'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.tryParse(map['purchaseDate']) ?? DateTime.now()
          : DateTime.now(),
      invoiceNumber: map['invoiceNumber'],
      paymentStatus: map['paymentStatus'] ?? 'Paid',
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      batchNumber: map['batchNumber'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
