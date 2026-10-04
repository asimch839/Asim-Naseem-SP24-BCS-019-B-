class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String imei;
  final String movementType; // 'purchase', 'sale', 'sale_return', 'purchase_return', 'repair_use', 'adjustment_add', 'adjustment_remove', 'damaged'
  final int quantity;
  final int previousStock;
  final int newStock;
  final String referenceId;
  final DateTime date;
  final String reason;
  final String performedBy;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.imei = '',
    required this.movementType,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.referenceId = '',
    DateTime? date,
    this.reason = '',
    this.performedBy = '',
  }) : date = date ?? DateTime.now();

  String get typeDisplayName {
    switch (movementType) {
      case 'purchase':
        return 'Stock Purchase (+)';
      case 'sale':
        return 'Sale Deduction (-)';
      case 'sale_return':
        return 'Customer Return (+)';
      case 'purchase_return':
        return 'Supplier Return (-)';
      case 'repair_use':
        return 'Repair Lab Part Consumed (-)';
      case 'adjustment_add':
        return 'Manual Addition (+)';
      case 'adjustment_remove':
        return 'Manual Deduction (-)';
      case 'damaged':
        return 'Damaged Stock (-)';
      default:
        return 'Stock Movement';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'imei': imei,
      'movement_type': movementType,
      'quantity': quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'reference_id': referenceId,
      'date': date.toIso8601String(),
      'reason': reason,
      'performed_by': performedBy,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      productId: (map['product_id'] as String?) ?? '',
      productName: (map['product_name'] as String?) ?? '',
      imei: (map['imei'] as String?) ?? '',
      movementType: (map['movement_type'] as String?) ?? 'sale',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (map['previous_stock'] as num?)?.toInt() ?? 0,
      newStock: (map['new_stock'] as num?)?.toInt() ?? 0,
      referenceId: (map['reference_id'] as String?) ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      reason: (map['reason'] as String?) ?? '',
      performedBy: (map['performed_by'] as String?) ?? '',
    );
  }
}
