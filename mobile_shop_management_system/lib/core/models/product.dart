enum ProductType {
  phone,
  accessory,
  part;

  String get displayName {
    switch (this) {
      case ProductType.phone:
        return 'Mobile Phone';
      case ProductType.accessory:
        return 'Accessory';
      case ProductType.part:
        return 'Repair Part';
    }
  }
}

class Product {
  final String id;
  final String name;
  final ProductType type;
  final String category;
  final String brand;
  final String model;
  final String sku;
  final String barcode;
  final double purchasePrice;
  final double salePrice;
  final int stockQuantity;
  final int minStockAlert;
  final int warrantyMonths;
  final String description;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.brand,
    this.model = '',
    required this.sku,
    this.barcode = '',
    required this.purchasePrice,
    required this.salePrice,
    this.stockQuantity = 0,
    this.minStockAlert = 3,
    this.warrantyMonths = 0,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isLowStock => stockQuantity <= minStockAlert && stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;
  double get profitMargin => salePrice - purchasePrice;
  double get profitPercentage => purchasePrice > 0 ? ((salePrice - purchasePrice) / purchasePrice) * 100 : 0.0;

  Product copyWith({
    String? id,
    String? name,
    ProductType? type,
    String? category,
    String? brand,
    String? model,
    String? sku,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    int? stockQuantity,
    int? minStockAlert,
    int? warrantyMonths,
    String? description,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'category': category,
      'brand': brand,
      'model': model,
      'sku': sku,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'warranty_months': warrantyMonths,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ProductType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ProductType.accessory,
      ),
      category: (map['category'] as String?) ?? 'General',
      brand: (map['brand'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      sku: (map['sku'] as String?) ?? '',
      barcode: (map['barcode'] as String?) ?? '',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      minStockAlert: (map['min_stock_alert'] as num?)?.toInt() ?? 3,
      warrantyMonths: (map['warranty_months'] as num?)?.toInt() ?? 0,
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
