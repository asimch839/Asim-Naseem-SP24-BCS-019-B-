class Supplier {
  final String id;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final double totalPurchases;
  final double paidAmount;
  final double dueAmount;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    this.email = '',
    this.address = '',
    this.notes = '',
    this.totalPurchases = 0.0,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Supplier copyWith({
    String? id,
    String? name,
    String? company,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? totalPurchases,
    double? paidAmount,
    double? dueAmount,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'total_purchases': totalPurchases,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      company: map['company'] as String,
      phone: map['phone'] as String,
      email: (map['email'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
