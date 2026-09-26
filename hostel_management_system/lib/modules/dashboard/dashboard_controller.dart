import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/rent_repository.dart';

class DashboardController extends GetxController {
  final ReportRepository _reportRepo = ReportRepository();
  final RentRepository _rentRepo = RentRepository();

  final isLoading = true.obs;
  final metrics = Rx<DashboardMetrics?>(null);
  
  // Date filter state
  final filterLabel = 'This Month'.obs;
  late DateTime fromDate;
  late DateTime toDate;

  // Chart data
  final rentChartData = <ChartDataPoint>[].obs;
  final incomeExpenseChartData = <ChartDataPoint>[].obs;
  final isLineChart = true.obs; // Toggle between line & bar chart for rent collection

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    filterLabel.value = 'This Month (${DateFormatter.formatMonthYear(now)})';
    refreshData();
  }

  void updateDateRange(DateTime from, DateTime to, String label) {
    fromDate = from;
    toDate = to;
    filterLabel.value = label;
    refreshData();
  }

  void toggleChartType() {
    isLineChart.value = !isLineChart.value;
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      try {
        await _rentRepo.syncMonthlyBillsAndOverdue();
      } catch (_) {}

      final startIso = DateFormatter.toIsoDate(fromDate);
      final endIso = DateFormatter.toIsoDate(toDate);
      final currentMonthIso = DateFormatter.toIsoMonth(fromDate);

      metrics.value = await _reportRepo.getDashboardMetrics(startIso, endIso, currentMonthIso);
      rentChartData.value = await _reportRepo.getRentChartData(fromDate, toDate);
      incomeExpenseChartData.value = await _reportRepo.getIncomeVsExpenseChartData(fromDate, toDate);
    } catch (e) {
      debugPrint('Dashboard refresh error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
