class InventoryTransactionModel {
  final String id;
  final String businessId;
  final String itemId;
  final String itemName;
  final String transactionType; // 'purchase', 'job_usage', 'sale', 'adjustment', 'return'
  final double quantity; // Positive for increase, negative for decrease
  final double previousQuantity;
  final double newQuantity;
  final double unitPrice;
  final double totalAmount;
  final String? relatedId; // jobId, purchaseId, saleId, returnId
  final String? reason; // For adjustments (Damaged, Expired, Missing, etc.)
  final String? userId;
  final String? userName;
  final DateTime timestamp;

  InventoryTransactionModel({
    required this.id,
    required this.businessId,
    required this.itemId,
    required this.itemName,
    required this.transactionType,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.unitPrice = 0.0,
    this.totalAmount = 0.0,
    this.relatedId,
    this.reason,
    this.userId,
    this.userName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'itemId': itemId,
      'itemName': itemName,
      'transactionType': transactionType,
      'quantity': quantity,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'relatedId': relatedId,
      'reason': reason,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryTransactionModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      transactionType: map['transactionType'] ?? 'adjustment',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      previousQuantity: (map['previousQuantity'] as num?)?.toDouble() ?? 0.0,
      newQuantity: (map['newQuantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      relatedId: map['relatedId'],
      reason: map['reason'],
      userId: map['userId'],
      userName: map['userName'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
