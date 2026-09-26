class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String salt;
  final String fullName;
  final String role; // 'Admin' or 'Office Staff'
  final int isActive; // 1 = active, 0 = inactive
  final String createdAt;
  final String? updatedAt;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.fullName,
    required this.role,
    this.isActive = 1,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'Admin';
  bool get isStaff => role == 'Office Staff';
  bool get enabled => isActive == 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      isActive: (map['is_active'] as int?) ?? 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? salt,
    String? fullName,
    String? role,
    int? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
