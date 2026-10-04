class Customer {
  final String id;
  final String name;
  final String phone;
  final String alternatePhone;
  final String address;
  final String email;
  final String notes;
  final double totalPurchases;
  final int totalRepairs;
  final double totalPaid;
  final double totalDue;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.alternatePhone = '',
    this.address = '',
    this.email = '',
    this.notes = '',
    this.totalPurchases = 0.0,
    this.totalRepairs = 0,
    this.totalPaid = 0.0,
    this.totalDue = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? alternatePhone,
    String? address,
    String? email,
    String? notes,
    double? totalPurchases,
    int? totalRepairs,
    double? totalPaid,
    double? totalDue,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalRepairs: totalRepairs ?? this.totalRepairs,
      totalPaid: totalPaid ?? this.totalPaid,
      totalDue: totalDue ?? this.totalDue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'address': address,
      'email': email,
      'notes': notes,
      'total_purchases': totalPurchases,
      'total_repairs': totalRepairs,
      'total_paid': totalPaid,
      'total_due': totalDue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      alternatePhone: (map['alternate_phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0.0,
      totalRepairs: (map['total_repairs'] as num?)?.toInt() ?? 0,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalDue: (map['total_due'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
