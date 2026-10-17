class InventoryBatchModel {
  final String id;
  final String businessId;
  final String itemId;
  final String batchNumber;
  final String? purchaseId;
  final double initialQuantity;
  final double remainingQuantity;
  final double unitPurchasePrice;
  final double unitRetailPrice;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String? supplierId;
  final String? supplierName;

  InventoryBatchModel({
    required this.id,
    required this.businessId,
    required this.itemId,
    required this.batchNumber,
    this.purchaseId,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.unitPurchasePrice,
    required this.unitRetailPrice,
    DateTime? purchaseDate,
    this.expiryDate,
    this.supplierId,
    this.supplierName,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  bool get isDepleted => remainingQuantity <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'itemId': itemId,
      'batchNumber': batchNumber,
      'purchaseId': purchaseId,
      'initialQuantity': initialQuantity,
      'remainingQuantity': remainingQuantity,
      'unitPurchasePrice': unitPurchasePrice,
      'unitRetailPrice': unitRetailPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
    };
  }

  factory InventoryBatchModel.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryBatchModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      itemId: map['itemId'] ?? '',
      batchNumber: map['batchNumber'] ?? '',
      purchaseId: map['purchaseId'],
      initialQuantity: (map['initialQuantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (map['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      unitPurchasePrice: (map['unitPurchasePrice'] as num?)?.toDouble() ?? 0.0,
      unitRetailPrice: (map['unitRetailPrice'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.tryParse(map['purchaseDate']) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'])
          : null,
      supplierId: map['supplierId'],
      supplierName: map['supplierName'],
    );
  }

  InventoryBatchModel copyWith({
    double? remainingQuantity,
  }) {
    return InventoryBatchModel(
      id: id,
      businessId: businessId,
      itemId: itemId,
      batchNumber: batchNumber,
      purchaseId: purchaseId,
      initialQuantity: initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      unitPurchasePrice: unitPurchasePrice,
      unitRetailPrice: unitRetailPrice,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      supplierId: supplierId,
      supplierName: supplierName,
    );
  }
}
