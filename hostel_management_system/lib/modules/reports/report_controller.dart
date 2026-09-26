import 'package:get/get.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/services/excel_service.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/rent_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/models/student_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/rent_record_model.dart';
import '../../data/models/expense_model.dart';

class ReportController extends GetxController {
  final StudentRepository _studentRepo = StudentRepository();
  final RoomRepository _roomRepo = RoomRepository();
  final RentRepository _rentRepo = RentRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final ReportRepository _reportRepo = ReportRepository();

  final selectedTab = 0.obs;
  final isLoading = true.obs;

  late DateTime fromDate;
  late DateTime toDate;
  final dateLabel = 'This Month'.obs;

  // Data sets for reports
  final students = <StudentModel>[].obs;
  final rooms = <RoomModel>[].obs;
  final rentRecords = <RentRecordModel>[].obs;
  final expenses = <ExpenseModel>[].obs;
  final financialMetrics = Rx<DashboardMetrics?>(null);

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    dateLabel.value = 'This Month (${DateFormatter.formatMonthYear(now)})';
    refreshReports();
  }

  void updateDateRange(DateTime from, DateTime to, String label) {
    fromDate = from;
    toDate = to;
    dateLabel.value = label;
    refreshReports();
  }

  Future<void> refreshReports() async {
    isLoading.value = true;
    try {
      final startIso = DateFormatter.toIsoDate(fromDate);
      final endIso = DateFormatter.toIsoDate(toDate);
      final monthIso = DateFormatter.toIsoMonth(fromDate);

      students.value = await _studentRepo.getAllStudents();
      rooms.value = await _roomRepo.getAllRooms();
      rentRecords.value = await _rentRepo.getRentRecords();
      expenses.value = await _expenseRepo.getExpenses(startDate: startIso, endDate: endIso);
      financialMetrics.value = await _reportRepo.getDashboardMetrics(startIso, endIso, monthIso);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load report data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportActiveReportToExcel() async {
    try {
      String prefix = 'Report';
      String title = 'Report';
      List<String> headers = [];
      List<List<dynamic>> rows = [];

      switch (selectedTab.value) {
        case 0: // Students
          prefix = 'Students_Report';
          title = 'Student Directory Report';
          headers = ['Student ID', 'Full Name', 'Father Name', 'Phone', 'CNIC', 'Room', 'Bed', 'Monthly Rent', 'Status', 'Admission Date'];
          rows = students.map((s) => [
            s.studentIdCode,
            s.fullName,
            s.fatherName,
            s.phone,
            s.cnic,
            s.roomNumber != null ? 'Room ${s.roomNumber}' : '-',
            s.bedNumber ?? '-',
            s.monthlyRent,
            s.status,
            s.admissionDate,
          ]).toList();
          break;

        case 1: // Rooms
          prefix = 'Rooms_Inventory_Report';
          title = 'Hostel Room & Bed Inventory Report';
          headers = ['Room #', 'Block', 'Floor', 'Type', 'Total Beds', 'Occupied Beds', 'Available Beds', 'Monthly Rent', 'Status'];
          rows = rooms.map((r) => [
            r.roomNumber,
            r.block,
            r.floor,
            r.roomType,
            r.totalBeds,
            r.occupiedBedsCount,
            r.availableBedsCount,
            r.monthlyRent,
            r.roomStatus,
          ]).toList();
          break;

        case 2: // Rent
          prefix = 'Rent_Collection_Report';
          title = 'Monthly Rent Billing & Dues Report';
          headers = ['Student ID', 'Student Name', 'Room', 'Billing Month', 'Rent Amount', 'Paid Amount', 'Remaining Due', 'Status', 'Due Date'];
          rows = rentRecords.map((r) => [
            r.studentIdCode ?? '-',
            r.studentName ?? '-',
            'Room ${r.roomNumber ?? '-'}',
            r.rentMonth,
            r.rentAmount,
            r.paidAmount,
            r.remainingAmount,
            r.status,
            r.dueDate,
          ]).toList();
          break;

        case 3: // Expenses
          prefix = 'Expenses_Report';
          title = 'Hostel Expenditures Report';
          headers = ['Date', 'Title', 'Category', 'Payment Method', 'Amount', 'Description'];
          rows = expenses.map((e) => [
            e.expenseDate,
            e.title,
            e.category,
            e.paymentMethod,
            e.amount,
            e.description ?? '-',
          ]).toList();
          break;

        case 4: // Financial P&L
          final m = financialMetrics.value;
          prefix = 'Financial_PL_Report';
          title = 'Profit & Loss Statement';
          headers = ['Financial Item', 'Amount (PKR)'];
          rows = [
            ['Total Rent Collected', m?.rentCollected ?? 0.0],
            ['Expected Rent Dues', m?.expectedRent ?? 0.0],
            ['Total Pending Rent', m?.pendingRent ?? 0.0],
            ['Total Operating Expenses', m?.totalExpenses ?? 0.0],
            ['Net Operational Income', m?.netIncome ?? 0.0],
          ];
          break;
      }

      final path = await ExcelService.exportToExcel(
        fileNamePrefix: prefix,
        sheetTitle: title,
        dateRangeText: dateLabel.value,
        headers: headers,
        rows: rows,
      );

      if (path != null) {
        Get.snackbar('Export Success', 'Report exported to $path');
      }
    } catch (e) {
      Get.snackbar('Export Failed', e.toString());
    }
  }
}
