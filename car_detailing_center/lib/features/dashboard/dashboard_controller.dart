import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/dashboard_report_repository.dart';

enum DateFilter { today, thisWeek, thisMonth, lastMonth, custom }

class DashboardController extends GetxController {
  final DashboardReportRepository _reportRepo = DashboardReportRepository();

  final Rx<DateFilter> selectedFilter = DateFilter.thisMonth.obs;
  final Rx<DateTimeRange?> customDateRange = Rx<DateTimeRange?>(null);
  final RxBool isLoading = true.obs;

  // Real SQLite KPI Metrics
  final Rx<DashboardMetrics?> metrics = Rx<DashboardMetrics?>(null);

  // 8 Real Graphs Data
  final RxList<Map<String, dynamic>> dailyIncomeVsExpense = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> monthlyIncomeVsExpense = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> netIncomeTrend = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paymentCollection = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobsByStatus = <Map<String, dynamic>>[].obs;
  final RxMap<String, int> attendanceOverview = <String, int>{}.obs;
  final RxList<Map<String, dynamic>> inventoryDistribution = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topDebtors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  void setFilter(DateFilter filter, [DateTimeRange? range]) {
    selectedFilter.value = filter;
    if (range != null) {
      customDateRange.value = range;
    }
    loadDashboardData();
  }

  DateTimeRange get _currentDateRange {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (selectedFilter.value) {
      case DateFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: endOfDay);
      case DateFilter.thisWeek:
        final startWeekday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startWeekday.year, startWeekday.month, startWeekday.day);
        return DateTimeRange(start: start, end: endOfDay);
      case DateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: endOfDay);
      case DateFilter.lastMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayPrevMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: prevMonth, end: lastDayPrevMonth);
      case DateFilter.custom:
        if (customDateRange.value != null) {
          final c = customDateRange.value!;
          return DateTimeRange(
            start: DateTime(c.start.year, c.start.month, c.start.day),
            end: DateTime(c.end.year, c.end.month, c.end.day, 23, 59, 59),
          );
        }
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: endOfDay);
    }
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final range = _currentDateRange;
      final filterMode = selectedFilter.value.name;

      // 1. Fetch KPIs for the selected period
      final kpis = await _reportRepo.getDashboardKPIs(range.start, range.end);
      metrics.value = kpis;

      // 2. Fetch Period-Filtered Income vs Expenses (Bar Chart 1)
      final gPeriod = await _reportRepo.getFilteredIncomeVsExpense(range.start, range.end, filterMode);
      dailyIncomeVsExpense.assignAll(gPeriod);

      // 3. Line Chart: Net Income & Revenue Trend Curve for selected period
      final List<Map<String, dynamic>> gNet = gPeriod.map((m) {
        final inc = (m['income'] as num?)?.toDouble() ?? 0.0;
        final exp = (m['expense'] as num?)?.toDouble() ?? 0.0;
        return {
          'label': m['label'],
          'net_income': inc - exp,
          'income': inc,
          'expense': exp,
        };
      }).toList();
      netIncomeTrend.assignAll(gNet);

      // Monthly comparative baseline
      final gMonthly = await _reportRepo.getMonthlyIncomeVsExpense();
      monthlyIncomeVsExpense.assignAll(gMonthly);

      // 4. Circle / Donut Chart: Payment Collection for the selected period
      final gPay = await _reportRepo.getPaymentCollectionByMethod(range.start, range.end);
      paymentCollection.assignAll(gPay);

      // 5. Bar Chart 2: Jobs Trend / Distribution for the selected period
      final gJobs = await _reportRepo.getJobsByStatus(range.start, range.end);
      jobsByStatus.assignAll(gJobs);

      final gAtt = await _reportRepo.getAttendanceOverview30Days();
      attendanceOverview.assignAll(gAtt);

      final gInv = await _reportRepo.getInventoryStockDistribution();
      inventoryDistribution.assignAll(gInv);

      final gDebtors = await _reportRepo.getTopOutstandingCustomers();
      topDebtors.assignAll(gDebtors);
    } catch (e) {
      debugPrint('Error loading SQLite dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
