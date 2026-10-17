class ServiceInventoryItem {
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;

  ServiceInventoryItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory ServiceInventoryItem.fromMap(Map<String, dynamic> map) {
    return ServiceInventoryItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'unit',
    );
  }
}

class ServiceModel {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final List<ServiceInventoryItem> expectedInventoryUsage;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.price,
    this.durationMinutes = 60,
    this.expectedInventoryUsage = const [],
    this.isActive = true,
    this.isDeleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'expectedInventoryUsage':
          expectedInventoryUsage.map((item) => item.toMap()).toList(),
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      expectedInventoryUsage: (map['expectedInventoryUsage'] as List<dynamic>?)
              ?.map((item) =>
                  ServiceInventoryItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: map['isActive'] ?? true,
      isDeleted: map['isDeleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ServiceModel copyWith({
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    List<ServiceInventoryItem>? expectedInventoryUsage,
    bool? isActive,
    bool? isDeleted,
  }) {
    return ServiceModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      expectedInventoryUsage:
          expectedInventoryUsage ?? this.expectedInventoryUsage,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
    );
  }
}
