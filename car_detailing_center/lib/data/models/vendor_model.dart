class VendorModel {
  final String id;
  final String businessId;
  final String name;
  final String? company;
  final String phone;
  final String? whatsApp;
  final String? email;
  final String? address;
  final String category;
  final String? taxNumber;
  final String? notes;
  final double currentBalance;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  VendorModel({
    required this.id,
    this.businessId = 'local',
    required this.name,
    this.company,
    required this.phone,
    this.whatsApp,
    this.email,
    this.address,
    this.category = 'Detailing Chemicals',
    this.taxNumber,
    this.notes,
    this.currentBalance = 0.0,
    this.status = 'Active',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company ?? '',
      'phone': phone,
      'whatsapp': whatsApp ?? '',
      'email': email ?? '',
      'address': address ?? '',
      'category': category,
      'tax_number': taxNumber ?? '',
      'notes': notes ?? '',
      'current_balance': currentBalance,
      'status': status,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VendorModel.fromMap(Map<String, dynamic> map) {
    return VendorModel(
      id: map['id'] as String? ?? '',
      businessId: 'local',
      name: map['name'] as String? ?? '',
      company: (map['company'] as String?)?.isNotEmpty == true ? map['company'] as String : null,
      phone: map['phone'] as String? ?? '',
      whatsApp: (map['whatsapp'] ?? map['whatsApp']) as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      category: map['category'] as String? ?? 'Detailing Chemicals',
      taxNumber: (map['tax_number'] ?? map['taxNumber']) as String?,
      notes: map['notes'] as String?,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ??
          (map['currentBalance'] as num?)?.toDouble() ??
          0.0,
      status: map['status'] as String? ?? 'Active',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1 || (map['isDeleted'] == true),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  VendorModel copyWith({
    String? name,
    String? company,
    String? phone,
    String? whatsApp,
    String? email,
    String? address,
    String? category,
    String? taxNumber,
    String? notes,
    double? currentBalance,
    String? status,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return VendorModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      address: address ?? this.address,
      category: category ?? this.category,
      taxNumber: taxNumber ?? this.taxNumber,
      notes: notes ?? this.notes,
      currentBalance: currentBalance ?? this.currentBalance,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
