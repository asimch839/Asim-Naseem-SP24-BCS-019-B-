import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';
import 'audit_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  bool get isLoggedIn => currentUser.value != null;
  bool get isAdmin => currentUser.value?.isAdmin ?? false;
  bool get isStaff => currentUser.value?.isStaff ?? false;
  String get currentUsername => currentUser.value?.username ?? 'Admin';
  int? get currentUserId => currentUser.value?.id;

  void setUser(UserModel user) {
    currentUser.value = user;
  }

  Future<void> logout() async {
    if (currentUser.value != null) {
      await AuditService.log(
        activityType: 'User Logout',
        description: 'User "${currentUser.value!.username}" logged out.',
        userId: currentUser.value!.id,
        username: currentUser.value!.username,
      );
    }
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
