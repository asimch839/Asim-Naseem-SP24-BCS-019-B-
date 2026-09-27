import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/database/db_helper.dart';
import 'core/services/auth_service.dart';
import 'routes/app_pages.dart';

class AppCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Intercept Flutter framework errors and prevent native aborts
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('HostelApp Caught FlutterError: ${details.exceptionAsString()}');
  };

  // 2. Intercept unhandled asynchronous isolate errors to prevent the Windows app from terminating
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('HostelApp Prevented Crash (PlatformDispatcher caught): $error\n$stack');
    return true; // Mark as handled to prevent OS window crash
  };

  // 3. Initialize SQLite FFI for Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 4. Pre-initialize database & seed tables safely
  try {
    await DbHelper.instance.database;
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  // 5. Initialize global services
  Get.put(AuthService(), permanent: true);

  // 6. Run app directly in root zone (fixes Zone mismatch with WidgetsFlutterBinding)
  runApp(const HostelManagementApp());
}

class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      scrollBehavior: AppCustomScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
              return AppColors.primary;
            }
            return AppColors.primary.withValues(alpha: 0.6);
          }),
          trackColor: const WidgetStatePropertyAll(AppColors.surfaceSecondary),
          radius: const Radius.circular(8),
          thickness: const WidgetStatePropertyAll(10),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          surfaceContainerLowest: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
      ),
    );
  }
}
