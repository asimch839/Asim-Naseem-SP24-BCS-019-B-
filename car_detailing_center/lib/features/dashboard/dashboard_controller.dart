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
    switch (selectedFilter.value) {
      case DateFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case DateFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: DateTime(start.year, start.month, start.day), end: now);
      case DateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case DateFilter.lastMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayPrevMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: prevMonth, end: lastDayPrevMonth);
      case DateFilter.custom:
        return customDateRange.value ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final range = _currentDateRange;

      // 1. Fetch 18 KPIs
      final kpis = await _reportRepo.getDashboardKPIs(range.start, range.end);
      metrics.value = kpis;

      // 2. Fetch all 8 real graphs from SQLite
      final gDaily = await _reportRepo.getDailyIncomeVsExpense();
      dailyIncomeVsExpense.assignAll(gDaily);

      final gMonthly = await _reportRepo.getMonthlyIncomeVsExpense();
      monthlyIncomeVsExpense.assignAll(gMonthly);

      final gNet = await _reportRepo.getNetIncomeTrend();
      netIncomeTrend.assignAll(gNet);

      final gPay = await _reportRepo.getPaymentCollectionByMethod();
      paymentCollection.assignAll(gPay);

      final gJobs = await _reportRepo.getJobsByStatus();
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
