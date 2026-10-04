class PaymentRecord {
  final String id;
  final String receiptNumber;
  final String type; // 'customer_due_payment', 'supplier_due_payment', 'repair_advance', 'repair_balance', 'sale_payment'
  final String referenceId;
  final String entityId;
  final String entityName;
  final double amount;
  final String paymentMethod; // 'Cash', 'JazzCash', 'Easypaisa', 'Bank Transfer', 'Card'
  final DateTime paymentDate;
  final String notes;
  final String collectedBy;

  PaymentRecord({
    required this.id,
    required this.receiptNumber,
    required this.type,
    required this.referenceId,
    required this.entityId,
    required this.entityName,
    required this.amount,
    this.paymentMethod = 'Cash',
    DateTime? paymentDate,
    this.notes = '',
    this.collectedBy = '',
  }) : paymentDate = paymentDate ?? DateTime.now();

  String get typeDisplayName {
    switch (type) {
      case 'customer_due_payment':
        return 'Customer Due Received';
      case 'supplier_due_payment':
        return 'Supplier Due Paid';
      case 'repair_advance':
        return 'Repair Advance';
      case 'repair_balance':
        return 'Repair Balance Due';
      case 'sale_payment':
        return 'Sale Payment';
      default:
        return 'Payment';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'type': type,
      'reference_id': referenceId,
      'entity_id': entityId,
      'entity_name': entityName,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'collected_by': collectedBy,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] as String,
      receiptNumber: map['receipt_number'] as String,
      type: (map['type'] as String?) ?? 'customer_due_payment',
      referenceId: (map['reference_id'] as String?) ?? '',
      entityId: (map['entity_id'] as String?) ?? '',
      entityName: (map['entity_name'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      paymentDate: DateTime.tryParse(map['payment_date']?.toString() ?? '') ?? DateTime.now(),
      notes: (map['notes'] as String?) ?? '',
      collectedBy: (map['collected_by'] as String?) ?? '',
    );
  }
}
