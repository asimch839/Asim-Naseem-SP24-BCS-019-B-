import 'dart:convert';

class PurchaseItem {
  final String id;
  final String productId;
  final String productName;
  final String productType; // 'phone', 'accessory', 'part'
  final int quantity;
  final double purchasePrice;
  final double total;
  final List<String> imeiList;

  PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productType = 'accessory',
    required this.quantity,
    required this.purchasePrice,
    required this.total,
    this.imeiList = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_type': productType,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'total': total,
      'imei_list': jsonEncode(imeiList),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    List<String> imeis = [];
    if (map['imei_list'] != null) {
      try {
        final decoded = jsonDecode(map['imei_list'].toString()) as List;
        imeis = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return PurchaseItem(
      id: map['id'] as String,
      productId: (map['product_id'] as String?) ?? '',
      productName: (map['product_name'] as String?) ?? '',
      productType: (map['product_type'] as String?) ?? 'accessory',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      imeiList: imeis,
    );
  }
}

class Purchase {
  final String id;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final DateTime purchaseDate;
  final double totalAmount;
  final double discount;
  final double paidAmount;
  final double dueAmount;
  final String paymentMethod;
  final String status; // 'Received', 'Returned'
  final String notes;
  final List<PurchaseItem> items;

  Purchase({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    DateTime? purchaseDate,
    required this.totalAmount,
    this.discount = 0.0,
    required this.paidAmount,
    required this.dueAmount,
    this.paymentMethod = 'Cash',
    this.status = 'Received',
    this.notes = '',
    required this.items,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'purchase_date': purchaseDate.toIso8601String(),
      'total_amount': totalAmount,
      'discount': discount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'status': status,
      'notes': notes,
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    List<PurchaseItem> itemsList = [];
    if (map['items_json'] != null) {
      try {
        final decoded = jsonDecode(map['items_json'] as String) as List;
        itemsList = decoded.map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return Purchase(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      supplierId: (map['supplier_id'] as String?) ?? '',
      supplierName: (map['supplier_name'] as String?) ?? '',
      purchaseDate: DateTime.tryParse(map['purchase_date']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      status: (map['status'] as String?) ?? 'Received',
      notes: (map['notes'] as String?) ?? '',
      items: itemsList,
    );
  }
}
