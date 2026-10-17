import '../../core/constants/app_constants.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // admin, manager
  final String businessId;
  final String? phone;
  final String? photoUrl;
  final bool isActive;
  final bool canManageStaffPermission;
  final bool canAccessSalariesPermission;
  final bool canAccessFinancialsPermission;
  final bool canManageInventoryPermission;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.businessId,
    this.phone,
    this.photoUrl,
    this.isActive = true,
    this.canManageStaffPermission = true,
    this.canAccessSalariesPermission = false,
    this.canAccessFinancialsPermission = true,
    this.canManageInventoryPermission = true,
    DateTime? createdAt,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isManager => role == AppConstants.roleManager;

  bool canAccessFinancials() => isAdmin || (isManager && canAccessFinancialsPermission);
  bool canAccessSalaries() => isAdmin || (isManager && canAccessSalariesPermission);
  bool canManageSettings() => isAdmin;
  bool canManageStaff() => isAdmin || (isManager && canManageStaffPermission);
  bool canManageInventory() => isAdmin || (isManager && canManageInventoryPermission);

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    String? businessId,
    String? phone,
    String? photoUrl,
    bool? isActive,
    bool? canManageStaffPermission,
    bool? canAccessSalariesPermission,
    bool? canAccessFinancialsPermission,
    bool? canManageInventoryPermission,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      canManageStaffPermission: canManageStaffPermission ?? this.canManageStaffPermission,
      canAccessSalariesPermission: canAccessSalariesPermission ?? this.canAccessSalariesPermission,
      canAccessFinancialsPermission: canAccessFinancialsPermission ?? this.canAccessFinancialsPermission,
      canManageInventoryPermission: canManageInventoryPermission ?? this.canManageInventoryPermission,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'businessId': businessId,
      'phone': phone,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'canManageStaffPermission': canManageStaffPermission,
      'canAccessSalariesPermission': canAccessSalariesPermission,
      'canAccessFinancialsPermission': canAccessFinancialsPermission,
      'canManageInventoryPermission': canManageInventoryPermission,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId.isNotEmpty ? docId : (map['uid'] ?? ''),
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] == AppConstants.roleAdmin ? AppConstants.roleAdmin : AppConstants.roleManager,
      businessId: map['businessId'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      isActive: map['isActive'] ?? true,
      canManageStaffPermission: map['canManageStaffPermission'] ?? true,
      canAccessSalariesPermission: map['canAccessSalariesPermission'] ?? false,
      canAccessFinancialsPermission: map['canAccessFinancialsPermission'] ?? true,
      canManageInventoryPermission: map['canManageInventoryPermission'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.tryParse(map['lastLoginAt'])
          : null,
    );
  }
}
