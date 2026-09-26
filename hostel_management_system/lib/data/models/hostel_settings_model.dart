class HostelSettingsModel {
  final int id;
  final String hostelName;
  final String address;
  final String phone;
  final String email;
  final String? logoPath;
  final String receiptPrefix;
  final String receiptFooter;
  final String authorizedPerson;
  final double defaultMonthlyRent;
  final int rentDueDay; // 1-31
  final String currency;
  final String? backupPath;
  final String updatedAt;

  HostelSettingsModel({
    this.id = 1,
    required this.hostelName,
    required this.address,
    required this.phone,
    required this.email,
    this.logoPath,
    required this.receiptPrefix,
    required this.receiptFooter,
    required this.authorizedPerson,
    required this.defaultMonthlyRent,
    required this.rentDueDay,
    this.currency = 'PKR',
    this.backupPath,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostel_name': hostelName,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_path': logoPath,
      'receipt_prefix': receiptPrefix,
      'receipt_footer': receiptFooter,
      'authorized_person': authorizedPerson,
      'default_monthly_rent': defaultMonthlyRent,
      'rent_due_day': rentDueDay,
      'currency': currency,
      'backup_path': backupPath,
      'updated_at': updatedAt,
    };
  }

  factory HostelSettingsModel.fromMap(Map<String, dynamic> map) {
    return HostelSettingsModel(
      id: (map['id'] as int?) ?? 1,
      hostelName: map['hostel_name'] as String? ?? 'Sardar 4 Boys Hostel',
      address: map['address'] as String? ?? 'Hostel Address Line 1',
      phone: map['phone'] as String? ?? '+92 300 1234567',
      email: map['email'] as String? ?? 'admin@hostel.local',
      logoPath: map['logo_path'] as String?,
      receiptPrefix: map['receipt_prefix'] as String? ?? 'REC-',
      receiptFooter: map['receipt_footer'] as String? ?? 'Thank you for choosing our hostel! Please keep this receipt safe.',
      authorizedPerson: map['authorized_person'] as String? ?? 'Warden / Manager',
      defaultMonthlyRent: (map['default_monthly_rent'] as num?)?.toDouble() ?? 15000.0,
      rentDueDay: (map['rent_due_day'] as int?) ?? 5,
      currency: map['currency'] as String? ?? 'PKR',
      backupPath: map['backup_path'] as String?,
      updatedAt: map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  HostelSettingsModel copyWith({
    int? id,
    String? hostelName,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    String? receiptPrefix,
    String? receiptFooter,
    String? authorizedPerson,
    double? defaultMonthlyRent,
    int? rentDueDay,
    String? currency,
    String? backupPath,
    String? updatedAt,
  }) {
    return HostelSettingsModel(
      id: id ?? this.id,
      hostelName: hostelName ?? this.hostelName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      authorizedPerson: authorizedPerson ?? this.authorizedPerson,
      defaultMonthlyRent: defaultMonthlyRent ?? this.defaultMonthlyRent,
      rentDueDay: rentDueDay ?? this.rentDueDay,
      currency: currency ?? this.currency,
      backupPath: backupPath ?? this.backupPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
