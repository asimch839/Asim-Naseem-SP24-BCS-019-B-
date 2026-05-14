class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userAddress;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get userAddress => _userAddress;

  void login(String email, String password) {
    // Dummy login logic
    _isLoggedIn = true;
    _userName = 'Asim Naseem';
    _userEmail = email;
    _userPhone = '0300-1234567';
    _userAddress = 'House #123, Street 5, Islamabad';
  }

  void signup({required String name, required String email, required String phone, required String password}) {
    // Dummy signup logic
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    _userAddress = 'Not set yet';
  }

  void logout() {
    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _userAddress = null;
  }

  void updateProfile({required String name, required String phone, required String address}) {
    _userName = name;
    _userPhone = phone;
    _userAddress = address;
  }
}
