class SupplierReturnModel {
  final String id;
  final String businessId;
  final String supplierId;
  final String supplierName;
  final String itemId;
  final String itemName;
  final double quantity;
  final double unitRefundPrice;
  final double totalRefund;
  final String reason;
  final String? purchaseId;
  final DateTime timestamp;

  SupplierReturnModel({
    required this.id,
    required this.businessId,
    required this.supplierId,
    required this.supplierName,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitRefundPrice,
    required this.totalRefund,
    required this.reason,
    this.purchaseId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unitRefundPrice': unitRefundPrice,
      'totalRefund': totalRefund,
      'reason': reason,
      'purchaseId': purchaseId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SupplierReturnModel.fromMap(Map<String, dynamic> map, String docId) {
    return SupplierReturnModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitRefundPrice: (map['unitRefundPrice'] as num?)?.toDouble() ?? 0.0,
      totalRefund: (map['totalRefund'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      purchaseId: map['purchaseId'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
