class SupplierModel {
  final String id;
  final String businessId;
  final String name;
  final String? company;
  final String phone;
  final String? whatsApp;
  final String? email;
  final String? address;
  final String? notes;
  final double currentBalance;
  final String status;
  final DateTime createdAt;
  final bool isDeleted;

  SupplierModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.company,
    required this.phone,
    this.whatsApp,
    this.email,
    this.address,
    this.notes,
    this.currentBalance = 0.0,
    this.status = 'Active',
    DateTime? createdAt,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'company': company,
      'phone': phone,
      'whatsApp': whatsApp,
      'email': email,
      'address': address,
      'notes': notes,
      'currentBalance': currentBalance,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map, String docId) {
    return SupplierModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      company: map['company'],
      phone: map['phone'] ?? '',
      whatsApp: map['whatsApp'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  SupplierModel copyWith({
    String? name,
    String? company,
    String? phone,
    String? whatsApp,
    String? email,
    String? address,
    String? notes,
    double? currentBalance,
    String? status,
    bool? isDeleted,
  }) {
    return SupplierModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      currentBalance: currentBalance ?? this.currentBalance,
      status: status ?? this.status,
      createdAt: createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
