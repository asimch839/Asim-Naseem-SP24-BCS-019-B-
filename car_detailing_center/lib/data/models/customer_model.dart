class CustomerModel {
  final String id;
  final String businessId;
  final String fullName;
  final String phone;
  final String? whatsApp;
  final String? email;
  final String? address;
  final String? notes;
  final String status; // Active, Inactive
  final int totalVisits;
  final double outstandingBalance;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  CustomerModel({
    required this.id,
    required this.businessId,
    required this.fullName,
    required this.phone,
    this.whatsApp,
    this.email,
    this.address,
    this.notes,
    this.status = 'Active',
    this.totalVisits = 0,
    this.outstandingBalance = 0.0,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'fullName': fullName,
      'phone': phone,
      'whatsApp': whatsApp,
      'email': email,
      'address': address,
      'notes': notes,
      'status': status,
      'totalVisits': totalVisits,
      'outstandingBalance': outstandingBalance,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      whatsApp: map['whatsApp'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      status: map['status'] ?? 'Active',
      totalVisits: (map['totalVisits'] as num?)?.toInt() ?? 0,
      outstandingBalance: (map['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  CustomerModel copyWith({
    String? fullName,
    String? phone,
    String? whatsApp,
    String? email,
    String? address,
    String? notes,
    String? status,
    int? totalVisits,
    double? outstandingBalance,
    String? photoUrl,
    bool? isDeleted,
  }) {
    return CustomerModel(
      id: id,
      businessId: businessId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalVisits: totalVisits ?? this.totalVisits,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
