class UserData {
  String name;
  String email;
  String phone;
  String university;
  String batch;

  UserData({
    this.name = 'User Name',
    this.email = 'user@example.com',
    this.phone = '+92 300 1234567',
    this.university = 'Comsats University',
    this.batch = '2024-2028',
  });
}

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  UserData currentUser = UserData();

  void updateUser({
    String? name,
    String? email,
    String? phone,
    String? university,
    String? batch,
  }) {
    if (name != null) currentUser.name = name;
    if (email != null) currentUser.email = email;
    if (phone != null) currentUser.phone = phone;
    if (university != null) currentUser.university = university;
    if (batch != null) currentUser.batch = batch;
  }
}
