import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/customers/customer_list_screen.dart';
import '../../features/vehicles/vehicle_list_screen.dart';
import '../../features/inspections/inspection_list_screen.dart';
import '../../features/staff/staff_screen.dart';
import '../../features/expenses/garage_expense_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/invoices/invoice_list_screen.dart';
import '../../features/payments/payment_list_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/vendors/vendor_list_screen.dart';
import '../../features/jobs/job_list_screen.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),

    // Main Navigation Modules + Vendors + Jobs
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: AppRoutes.jobs, page: () => const JobListScreen()),
    GetPage(name: AppRoutes.staff, page: () => const StaffScreen()),
    GetPage(name: AppRoutes.staffAttendance, page: () => const StaffScreen(initialTabIndex: 1)),
    GetPage(name: AppRoutes.staffSalaries, page: () => const StaffScreen(initialTabIndex: 2)),
    GetPage(name: AppRoutes.staffExpenses, page: () => const StaffScreen(initialTabIndex: 3)),
    GetPage(name: AppRoutes.garageExpenses, page: () => const GarageExpenseScreen()),
    GetPage(name: AppRoutes.inventory, page: () => const InventoryScreen()),
    GetPage(name: AppRoutes.vendors, page: () => const VendorListScreen()),
    GetPage(name: AppRoutes.suppliers, page: () => const VendorListScreen()),
    GetPage(name: AppRoutes.invoices, page: () => const InvoiceListScreen()),
    GetPage(name: AppRoutes.payments, page: () => const PaymentListScreen()),
    GetPage(name: AppRoutes.reports, page: () => const ReportsScreen()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
    GetPage(name: AppRoutes.vehicles, page: () => const VehicleListScreen()),
    GetPage(name: AppRoutes.customers, page: () => const CustomerListScreen()),
    GetPage(name: AppRoutes.inspections, page: () => const InspectionListScreen()),

    // Notification Center
    GetPage(name: AppRoutes.notifications, page: () => const NotificationCenterScreen()),
  ];
}
