import 'package:get/get.dart';
import '../views/splash/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/ai_chat/ai_chat_screen.dart';
import '../views/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String aiChat = '/ai_chat';
  static const String profile = '/profile';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: signup, page: () => const SignupScreen()),
    GetPage(name: aiChat, page: () => const AIChatScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
  ];
}
