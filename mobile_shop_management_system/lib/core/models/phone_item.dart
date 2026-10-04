class PhoneItem {
  final String id;
  final String productId;
  final String brand;
  final String model;
  final String variant;
  final String ram;
  final String storage;
  final String color;
  final String ptaStatus; // 'PTA Approved', 'Non-PTA', 'CPID Approved', 'VIP Box Pack'
  final String imei1;
  final String imei2;
  final String serialNumber;
  final double purchasePrice;
  final double salePrice;
  final String supplierId;
  final String supplierName;
  final String? customerId;
  final String? customerName;
  final DateTime purchaseDate;
  final DateTime? soldDate;
  final String? saleInvoiceNumber;
  final String warrantyPeriod;
  final String condition; // 'New', 'Used', 'Refurbished'
  final String status; // 'In Stock', 'Sold', 'Reserved', 'Returned', 'Warranty', 'Damaged'
  final String notes;

  PhoneItem({
    required this.id,
    this.productId = '',
    required this.brand,
    required this.model,
    this.variant = '',
    this.ram = '',
    this.storage = '',
    this.color = '',
    this.ptaStatus = 'PTA Approved',
    required this.imei1,
    this.imei2 = '',
    this.serialNumber = '',
    required this.purchasePrice,
    required this.salePrice,
    this.supplierId = '',
    this.supplierName = '',
    this.customerId,
    this.customerName,
    DateTime? purchaseDate,
    this.soldDate,
    this.saleInvoiceNumber,
    this.warrantyPeriod = '1 Year Official',
    this.condition = 'New',
    this.status = 'In Stock',
    this.notes = '',
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  String get displayName => '$brand $model ${variant.isNotEmpty ? variant : '$ram/$storage'} $color'.trim();

  PhoneItem copyWith({
    String? id,
    String? productId,
    String? brand,
    String? model,
    String? variant,
    String? ram,
    String? storage,
    String? color,
    String? ptaStatus,
    String? imei1,
    String? imei2,
    String? serialNumber,
    double? purchasePrice,
    double? salePrice,
    String? supplierId,
    String? supplierName,
    String? customerId,
    String? customerName,
    DateTime? purchaseDate,
    DateTime? soldDate,
    String? saleInvoiceNumber,
    String warrantyPeriod = '1 Year Official',
    String? condition,
    String? status,
    String? notes,
  }) {
    return PhoneItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      ram: ram ?? this.ram,
      storage: storage ?? this.storage,
      color: color ?? this.color,
      ptaStatus: ptaStatus ?? this.ptaStatus,
      imei1: imei1 ?? this.imei1,
      imei2: imei2 ?? this.imei2,
      serialNumber: serialNumber ?? this.serialNumber,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      soldDate: soldDate ?? this.soldDate,
      saleInvoiceNumber: saleInvoiceNumber ?? this.saleInvoiceNumber,
      warrantyPeriod: warrantyPeriod,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'brand': brand,
      'model': model,
      'variant': variant,
      'ram': ram,
      'storage': storage,
      'color': color,
      'pta_status': ptaStatus,
      'imei1': imei1,
      'imei2': imei2,
      'serial_number': serialNumber,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'customer_id': customerId,
      'customer_name': customerName,
      'purchase_date': purchaseDate.toIso8601String(),
      'sold_date': soldDate?.toIso8601String(),
      'sale_invoice_number': saleInvoiceNumber,
      'warranty_period': warrantyPeriod,
      'condition': condition,
      'status': status,
      'notes': notes,
    };
  }

  factory PhoneItem.fromMap(Map<String, dynamic> map) {
    return PhoneItem(
      id: map['id'] as String,
      productId: (map['product_id'] as String?) ?? '',
      brand: (map['brand'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      variant: (map['variant'] as String?) ?? '',
      ram: (map['ram'] as String?) ?? '',
      storage: (map['storage'] as String?) ?? '',
      color: (map['color'] as String?) ?? '',
      ptaStatus: (map['pta_status'] as String?) ?? 'PTA Approved',
      imei1: map['imei1'] as String,
      imei2: (map['imei2'] as String?) ?? '',
      serialNumber: (map['serial_number'] as String?) ?? '',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      supplierId: (map['supplier_id'] as String?) ?? '',
      supplierName: (map['supplier_name'] as String?) ?? '',
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      purchaseDate: DateTime.tryParse(map['purchase_date']?.toString() ?? '') ?? DateTime.now(),
      soldDate: map['sold_date'] != null ? DateTime.tryParse(map['sold_date'].toString()) : null,
      saleInvoiceNumber: map['sale_invoice_number'] as String?,
      warrantyPeriod: (map['warranty_period'] as String?) ?? '1 Year Official',
      condition: (map['condition'] as String?) ?? 'New',
      status: (map['status'] as String?) ?? 'In Stock',
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
