import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/auth_service.dart';

class UserController extends GetxController {
  final UserRepository _userRepo = UserRepository();

  final users = <UserModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      users.value = await _userRepo.getAllUsers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      await _userRepo.createUser(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
      );
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Success', 'User $username created successfully!');
      await fetchUsers();
    } catch (e) {
      Get.snackbar('Operation Failed', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String role,
    required int isActive,
    String? newPassword,
  }) async {
    try {
      await _userRepo.updateUser(
        id: id,
        fullName: fullName,
        role: role,
        isActive: isActive,
        newPassword: newPassword,
      );
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Success', 'User updated successfully!');
      await fetchUsers();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> deleteUser(UserModel user) async {
    if (user.id == AuthService.to.currentUserId) {
      Get.snackbar('Forbidden', 'You cannot delete the currently logged in account.');
      return;
    }

    try {
      await _userRepo.deleteUser(user.id!);
      Get.snackbar('Success', 'User ${user.username} deleted.');
      await fetchUsers();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
