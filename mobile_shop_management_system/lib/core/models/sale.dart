import 'dart:convert';

class SaleItem {
  final String id;
  final String productId;
  final String productName;
  final String productType; // 'phone', 'accessory', 'part'
  final String imei;
  final int quantity;
  final double unitPrice;
  final double costPrice;
  final double discount;
  final double total;
  final int warrantyMonths;

  SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productType = 'accessory',
    this.imei = '',
    this.quantity = 1,
    required this.unitPrice,
    this.costPrice = 0.0,
    this.discount = 0.0,
    required this.total,
    this.warrantyMonths = 0,
  });

  double get profit => total - (costPrice * quantity);

  SaleItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productType,
    String? imei,
    int? quantity,
    double? unitPrice,
    double? costPrice,
    double? discount,
    double? total,
    int? warrantyMonths,
  }) {
    return SaleItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      imei: imei ?? this.imei,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_type': productType,
      'imei': imei,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount': discount,
      'total': total,
      'warranty_months': warrantyMonths,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      productId: (map['product_id'] as String?) ?? '',
      productName: (map['product_name'] as String?) ?? '',
      productType: (map['product_type'] as String?) ?? 'accessory',
      imei: (map['imei'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      warrantyMonths: (map['warranty_months'] as num?)?.toInt() ?? 0,
    );
  }
}

class Sale {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DateTime saleDate;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentMethod; // 'Cash', 'JazzCash', 'Easypaisa', 'Bank Transfer', 'Card', 'Due', 'Split'
  final Map<String, double> paymentBreakdown;
  final String cashierId;
  final String cashierName;
  final String status; // 'Completed', 'Returned', 'Cancelled'
  final String notes;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    DateTime? saleDate,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    required this.paidAmount,
    required this.dueAmount,
    this.paymentMethod = 'Cash',
    Map<String, double>? paymentBreakdown,
    this.cashierId = '',
    this.cashierName = '',
    this.status = 'Completed',
    this.notes = '',
    required this.items,
  })  : saleDate = saleDate ?? DateTime.now(),
        paymentBreakdown = paymentBreakdown ?? {};

  double get totalCost => items.fold(0.0, (sum, i) => sum + (i.costPrice * i.quantity));
  double get totalProfit => grandTotal - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'sale_date': saleDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'payment_breakdown': jsonEncode(paymentBreakdown),
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'status': status,
      'notes': notes,
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    List<SaleItem> itemsList = [];
    if (map['items_json'] != null) {
      try {
        final decoded = jsonDecode(map['items_json'] as String) as List;
        itemsList = decoded.map((e) => SaleItem.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    Map<String, double> breakdown = {};
    if (map['payment_breakdown'] != null) {
      try {
        final decoded = jsonDecode(map['payment_breakdown'] as String) as Map;
        breakdown = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
      } catch (_) {}
    }

    return Sale(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      customerId: (map['customer_id'] as String?) ?? '',
      customerName: (map['customer_name'] as String?) ?? '',
      customerPhone: (map['customer_phone'] as String?) ?? '',
      saleDate: DateTime.tryParse(map['sale_date']?.toString() ?? '') ?? DateTime.now(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      paymentBreakdown: breakdown,
      cashierId: (map['cashier_id'] as String?) ?? '',
      cashierName: (map['cashier_name'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'Completed',
      notes: (map['notes'] as String?) ?? '',
      items: itemsList,
    );
  }
}
