class InventoryItemModel {
  final String id; // System-generated
  final String businessId;
  final String name; // Item Name
  final double currentQuantity; // Current Quantity
  final String? brand; // Brand
  final String unit; // Unit (e.g., Litre, Bottle, Pieces, Box, etc.)
  final double purchasePrice; // Purchase Price (Khareed Qeemat)
  final double sellingPrice; // Selling Price (Sale / Retail Qeemat)
  final DateTime purchaseDate; // Purchase Date
  final String? description; // Description
  final String? notes; // Notes
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  InventoryItemModel({
    required this.id,
    required this.businessId,
    required this.name,
    double? currentQuantity,
    double? quantity,
    this.brand,
    this.unit = 'unit',
    double? purchasePrice,
    double? sellingPrice,
    double? unitCost,
    double? unitPrice,
    DateTime? purchaseDate,
    this.description,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    this.isDeleted = false,
  })  : currentQuantity = currentQuantity ?? quantity ?? 0.0,
        purchasePrice = purchasePrice ?? unitCost ?? 0.0,
        sellingPrice = sellingPrice ?? unitPrice ?? purchasePrice ?? unitCost ?? 0.0,
        purchaseDate = purchaseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get quantity => currentQuantity;
  double get unitCost => purchasePrice;
  double get unitPrice => sellingPrice > 0 ? sellingPrice : purchasePrice;
  double get retailPrice => sellingPrice > 0 ? sellingPrice : purchasePrice;
  bool get isActive => !isDeleted;

  bool isLowStock(double globalThreshold) => currentQuantity > 0 && currentQuantity <= globalThreshold;
  bool get isOutOfStock => currentQuantity <= 0;
  double get totalPurchaseValuation => currentQuantity * purchasePrice;
  double get currentPurchaseValuation => totalPurchaseValuation;
  double get totalRetailValuation => currentQuantity * (sellingPrice > 0 ? sellingPrice : purchasePrice);
  double get currentRetailValuation => totalRetailValuation;
  double get potentialMargin => (sellingPrice > purchasePrice) ? (sellingPrice - purchasePrice) : 0.0;
  double get marginPercent => purchasePrice > 0 ? (((sellingPrice > 0 ? sellingPrice : purchasePrice) - purchasePrice) / purchasePrice) * 100 : 0.0;
  String get category => brand ?? 'General';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'currentQuantity': currentQuantity,
      'brand': brand,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'description': description,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String docId) {
    final pPrice = (map['purchasePrice'] ?? map['purchase_price'] as num?)?.toDouble() ?? 0.0;
    final sPrice = (map['sellingPrice'] ?? map['selling_price'] as num?)?.toDouble() ?? pPrice;

    return InventoryItemModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? map['item_name'] ?? '',
      currentQuantity: (map['currentQuantity'] ?? map['current_quantity'] as num?)?.toDouble() ?? 0.0,
      brand: map['brand'],
      unit: map['unit'] ?? 'unit',
      purchasePrice: pPrice,
      sellingPrice: sPrice > 0 ? sPrice : pPrice,
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.tryParse(map['purchaseDate']) ?? DateTime.now()
          : (map['purchase_date'] != null ? DateTime.tryParse(map['purchase_date']) ?? DateTime.now() : DateTime.now()),
      description: map['description'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : (map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : (map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) ?? DateTime.now() : DateTime.now()),
      isDeleted: map['isDeleted'] == true || map['is_deleted'] == 1,
    );
  }

  InventoryItemModel copyWith({
    String? name,
    double? currentQuantity,
    String? brand,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    DateTime? purchaseDate,
    String? description,
    String? notes,
    bool? isDeleted,
  }) {
    return InventoryItemModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
