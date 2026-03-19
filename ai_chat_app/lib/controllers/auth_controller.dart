import 'dart:typed_data';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  void login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    if (currentUser.value == null) {
      currentUser.value = UserModel(id: '1', name: 'User', email: email);
    }
    isLoading.value = false;

    Get.offAllNamed(AppRoutes.aiChat);
  }

  void signup(String name, String email, String password, Uint8List? profilePic) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    currentUser.value = UserModel(
      id: DateTime.now().toString(), 
      name: name, 
      email: email,
      profilePic: profilePic,
      username: name.toLowerCase().replaceAll(" ", "_"),
    );
    isLoading.value = false;

    Get.offAllNamed(AppRoutes.aiChat);
  }

  void updateProfile({
    required String name,
    required String email,
    required String? phoneNumber,
    required String? username,
    required Uint8List? profilePic,
  }) {
    if (currentUser.value != null) {
      currentUser.value!.name = name;
      currentUser.value!.email = email;
      currentUser.value!.phoneNumber = phoneNumber;
      currentUser.value!.username = username;
      currentUser.value!.profilePic = profilePic;
      currentUser.refresh(); // Notify listeners
      Get.snackbar("Success", "Profile updated successfully", snackPosition: SnackPosition.BOTTOM);
    }
  }

  void logout() {
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
