import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_routes.dart';

class LoginController extends GetxController {
  final UserRepository _userRepo = UserRepository();
  
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;



  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final enteredUsername = usernameController.text.trim();
      final enteredPassword = passwordController.text.trim();

      debugPrint('[LOGIN] Attempting login with username: "$enteredUsername"');

      if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
        errorMessage.value = 'Username and password are required.';
        debugPrint('[LOGIN] ❌ Empty username or password. Login blocked.');
        return;
      }

      final user = await _userRepo.authenticate(enteredUsername, enteredPassword);

      debugPrint('[LOGIN] authenticate() returned: ${user != null ? "UserModel(${user.username})" : "null"}');

      if (user != null) {
        debugPrint('[LOGIN] ✅ Login successful for "${user.username}". Navigating to main.');
        AuthService.to.setUser(user);
        passwordController.clear();
        errorMessage.value = '';
        Get.offAllNamed(AppRoutes.main);
      } else {
        debugPrint('[LOGIN] ❌ Login FAILED. Invalid credentials.');
        errorMessage.value = 'Invalid username or password. Please try again.';
      }
    } catch (e) {
      debugPrint('[LOGIN] ❌ Login ERROR: $e');
      errorMessage.value = 'Login error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
