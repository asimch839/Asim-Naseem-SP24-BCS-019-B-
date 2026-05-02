class UserModel {
  final String name;
  final String email;
  final String? avatarPath;

  const UserModel({
    required this.name,
    required this.email,
    this.avatarPath,
  });

  UserModel copyWith({String? name, String? email, String? avatarPath}) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatar_path': avatarPath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      avatarPath: map['avatar_path'] as String?,
    );
  }

  static UserModel get defaultUser => const UserModel(
        name: 'John Doe',
        email: 'john@notevault.app',
      );
}
