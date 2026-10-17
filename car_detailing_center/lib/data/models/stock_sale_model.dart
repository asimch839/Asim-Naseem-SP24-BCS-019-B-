class StockSaleModel {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String itemId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final double discount;
  final double netAmount;
  final String paymentMethod;
  final String? invoiceId;
  final DateTime timestamp;

  StockSaleModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.discount = 0.0,
    required this.netAmount,
    this.paymentMethod = 'Cash',
    this.invoiceId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'discount': discount,
      'netAmount': netAmount,
      'paymentMethod': paymentMethod,
      'invoiceId': invoiceId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StockSaleModel.fromMap(Map<String, dynamic> map, String docId) {
    return StockSaleModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      invoiceId: map['invoiceId'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
