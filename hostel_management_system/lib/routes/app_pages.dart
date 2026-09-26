import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/auth/login_controller.dart';
import '../modules/auth/login_view.dart';
import '../modules/layout/main_layout_controller.dart';
import '../modules/layout/main_layout_view.dart';

class AppPages {
  static const initial = AppRoutes.login;

  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LoginController>(() => LoginController());
      }),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainLayoutView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MainLayoutController>(() => MainLayoutController());
      }),
    ),
  ];
}
