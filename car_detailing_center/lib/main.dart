import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/services/auth_service.dart';
import 'core/services/local_storage_service.dart';
import 'data/database/app_database.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/vehicle_repository.dart';
import 'data/repositories/inspection_repository.dart';
import 'data/repositories/job_repository.dart';
import 'data/repositories/staff_repository.dart';
import 'data/repositories/garage_expense_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/invoice_payment_repository.dart';
import 'data/repositories/dashboard_report_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'features/notifications/notification_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global crash protection handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Global Caught Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Caught Platform Async Error: $error');
    return true;
  };

  // 2. Initialize Persistent Local SQLite Database (Windows FFI + Android Native)
  try {
    await AppDatabase.instance.database;
    debugPrint('SQLite Database successfully initialized and verified.');
  } catch (e) {
    debugPrint('Database Initialization error: $e');
  }

  // 3. Register Core Services & Repositories using GetX Dependency Injection
  Get.put(LocalStorageService(), permanent: true);
  Get.put(AuthService(), permanent: true);

  // Repositories
  Get.put(SettingsRepository(), permanent: true);
  Get.put(CustomerRepository(), permanent: true);
  Get.put(VehicleRepository(), permanent: true);
  Get.put(InspectionRepository(), permanent: true);
  Get.put(JobRepository(), permanent: true);
  Get.put(StaffRepository(), permanent: true);
  Get.put(GarageExpenseRepository(), permanent: true);
  Get.put(InventoryRepository(), permanent: true);
  Get.put(InvoicePaymentRepository(), permanent: true);
  Get.put(DashboardReportRepository(), permanent: true);
  Get.put(NotificationRepository(), permanent: true);

  // Notification / Local Reminders Controller
  Get.put(NotificationController(), permanent: true);

  runApp(const AutoDetailProApp());
}

class AutoDetailProApp extends StatelessWidget {
  const AutoDetailProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AutoDetail Pro - Car Detailing Center Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}
