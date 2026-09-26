import 'package:get/get.dart';
import '../../modules/dashboard/dashboard_controller.dart';
import '../../modules/students/student_controller.dart';
import '../../modules/rooms/room_controller.dart';
import '../../modules/rent/rent_controller.dart';
import '../../modules/receipts/receipt_controller.dart';
import '../../modules/history/history_controller.dart';
import '../../modules/reports/report_controller.dart';

/// Centralized service to synchronize all screens and active controllers in real-time.
class AppRefreshService {
  /// Reloads all active controllers across the application.
  static Future<void> refreshAll() async {
    final futures = <Future>[];

    if (Get.isRegistered<DashboardController>()) {
      futures.add(Get.find<DashboardController>().refreshData());
    }
    if (Get.isRegistered<StudentController>()) {
      futures.add(Get.find<StudentController>().fetchStudents());
    }
    if (Get.isRegistered<RoomController>()) {
      futures.add(Get.find<RoomController>().fetchRooms());
    }
    if (Get.isRegistered<RentController>()) {
      futures.add(Get.find<RentController>().fetchRentRecords());
    }
    if (Get.isRegistered<ReceiptController>()) {
      futures.add(Get.find<ReceiptController>().fetchReceipts());
    }
    if (Get.isRegistered<HistoryController>()) {
      futures.add(Get.find<HistoryController>().fetchStudentsHistory());
      futures.add(Get.find<HistoryController>().fetchHistoryLogs());
    }
    if (Get.isRegistered<ReportController>()) {
      futures.add(Get.find<ReportController>().refreshReports());
    }

    try {
      await Future.wait(futures.map((f) => f.catchError((_) {})));
    } catch (_) {}
  }
}
