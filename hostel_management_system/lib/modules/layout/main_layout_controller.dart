import 'dart:async';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/hostel_settings_model.dart';
import '../dashboard/dashboard_controller.dart';
import '../students/student_controller.dart';
import '../rooms/room_controller.dart';
import '../admissions/admission_controller.dart';
import '../rent/rent_controller.dart';
import '../receipts/receipt_controller.dart';
import '../expenses/expense_controller.dart';
import '../history/history_controller.dart';
import '../reports/report_controller.dart';
import '../users/user_controller.dart';
import '../settings/settings_controller.dart';

class MainLayoutController extends GetxController {
  final SettingsRepository _settingsRepo = SettingsRepository();
  
  final selectedIndex = 0.obs;
  final currentTimeString = ''.obs;
  final hostelSettings = Rx<HostelSettingsModel?>(null);
  final isSidebarCollapsed = false.obs;

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    loadSettings();
    _initializeAllControllers();
  }

  void _updateTime() {
    final now = DateTime.now();
    currentTimeString.value = '${_formatWeekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')} ${_formatMonth(now.month)} ${now.year} | ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  String _formatWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _formatMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> loadSettings() async {
    hostelSettings.value = await _settingsRepo.getSettings();
  }

  void _initializeAllControllers() {
    Get.put(DashboardController(), permanent: true);
    Get.put(StudentController(), permanent: true);
    Get.put(RoomController(), permanent: true);
    Get.put(AdmissionController(), permanent: true);
    Get.put(RentController(), permanent: true);
    Get.put(ReceiptController(), permanent: true);
    Get.put(ExpenseController(), permanent: true);
    Get.put(HistoryController(), permanent: true);
    Get.put(ReportController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
  }

  void setNavIndex(int index) {
    // If user is office staff and clicks Users, block navigation
    if (index == 9 && !AuthService.to.isAdmin) {
      Get.snackbar('Access Restricted', 'User Management is only accessible by Administrators.');
      return;
    }
    selectedIndex.value = index;

    // Trigger auto-refresh for targeted module
    switch (index) {
      case 0:
        Get.find<DashboardController>().refreshData();
        break;
      case 1:
        Get.find<StudentController>().fetchStudents();
        break;
      case 2:
        Get.find<RoomController>().fetchRooms();
        break;
      case 3:
        Get.find<AdmissionController>().prepareNewAdmission();
        break;
      case 4:
        Get.find<RentController>().fetchRentRecords();
        break;
      case 5:
        Get.find<ReceiptController>().fetchReceipts();
        break;
      case 6:
        Get.find<ExpenseController>().fetchExpenses();
        break;
      case 7:
        Get.find<HistoryController>().fetchHistoryLogs();
        break;
      case 8:
        Get.find<ReportController>().refreshReports();
        break;
      case 9:
        Get.find<UserController>().fetchUsers();
        break;
      case 10:
        Get.find<SettingsController>().fetchSettings();
        break;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
