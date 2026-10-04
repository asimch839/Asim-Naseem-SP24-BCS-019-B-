enum UserRole {
  owner,
  admin,
  manager,
  salesStaff,
  technician,
  cashier;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Shop Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Store Manager';
      case UserRole.salesStaff:
        return 'Sales Staff';
      case UserRole.technician:
        return 'Mobile Technician';
      case UserRole.cashier:
        return 'Cashier';
    }
  }

  bool get canViewFinancialReports =>
      this == UserRole.owner || this == UserRole.admin || this == UserRole.manager;

  bool get canViewProfit =>
      this == UserRole.owner || this == UserRole.admin;

  bool get canManageSettings =>
      this == UserRole.owner || this == UserRole.admin;

  bool get canManageEmployees =>
      this == UserRole.owner || this == UserRole.admin;

  bool get canManageRepairs =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.technician;

  bool get canMakeSales =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.salesStaff ||
      this == UserRole.cashier;

  bool get canReceivePayments =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.cashier;

  bool get canPerformBackup =>
      this == UserRole.owner || this == UserRole.admin;
}

class AppUser {
  final String id;
  final String name;
  final String username;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.role,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'role': role.name,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String,
      phone: (map['phone'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.salesStaff,
      ),
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
