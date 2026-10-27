import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/dashboard_report_repository.dart';
import '../customers/customer_form_dialog.dart';
import '../expenses/garage_expense_screen.dart';
import '../jobs/job_create_dialog.dart';
import '../invoices/invoice_create_dialog.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return AppScaffold(
      currentRoute: AppRoutes.dashboard,
      title: 'Operations & Business Dashboard',
      body: Obx(() {
        if (controller.isLoading.value && controller.metrics.value == null) {
          return const AppLoadingIndicator(message: 'Loading live business data from SQLite...');
        }

        final m = controller.metrics.value ??
            DashboardMetrics(
              totalIncome: 0,
              totalExpenses: 0,
              netIncome: 0,
              outstandingPayments: 0,
              totalCustomers: 0,
              totalVehicles: 0,
              todaysJobs: 0,
              inProgressJobs: 0,
              completedJobs: 0,
              readyForDeliveryJobs: 0,
              totalStaff: 0,
              presentToday: 0,
              absentToday: 0,
              pendingSalaries: 0,
              totalStockItems: 0,
              lowStockItems: 0,
              outOfStockItems: 0,
              stockPurchaseValue: 0,
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Top Header with Date Range Filters & Quick Action Buttons
              _buildExecutiveHeader(context, controller),
              const SizedBox(height: 20),

              // 2. Section: 18 KPI CARDS (Grouped into Financial, Operations, Team, Inventory)
              _buildKPISectionTitle('1. Financial Health (Period Recognized)'),
              const SizedBox(height: 10),
              _buildFinancialKPIs(context, m, currency),
              const SizedBox(height: 20),

              _buildKPISectionTitle('2. Customers, Vehicles & Workshop Floor'),
              const SizedBox(height: 10),
              _buildOperationalKPIs(context, m),
              const SizedBox(height: 20),

              _buildKPISectionTitle('3. Team Attendance & Inventory Health'),
              const SizedBox(height: 10),
              _buildStaffAndInventoryKPIs(context, m, currency),
              const SizedBox(height: 24),

              // 3. Section: 8 SQLite-Driven Professional Graphs
              const Text(
                'Business Analytics & Historical Trends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: 14),

              // Graph Pair 1: Daily & Monthly Income vs Expenses
              _buildGraphRow(
                context: context,
                leftWidget: _buildDailyIncomeExpenseGraph(context, controller, currency),
                rightWidget: _buildMonthlyIncomeExpenseGraph(context, controller, currency),
              ),
              const SizedBox(height: 20),

              // Graph Pair 2: Net Income Trend & Payment Collection Breakdown
              _buildGraphRow(
                context: context,
                leftWidget: _buildNetIncomeTrendGraph(context, controller, currency),
                rightWidget: _buildPaymentCollectionGraph(context, controller, currency),
              ),
              const SizedBox(height: 20),

              // Graph Pair 3: Jobs Trend & Staff Attendance 30 Days
              _buildGraphRow(
                context: context,
                leftWidget: _buildJobsTrendGraph(context, controller),
                rightWidget: _buildAttendanceDonutGraph(context, controller),
              ),
              const SizedBox(height: 20),

              // Graph Pair 4: Inventory Quantity Overview & Top Outstanding Receivables
              _buildGraphRow(
                context: context,
                leftWidget: _buildInventoryDistributionGraph(context, controller),
                rightWidget: _buildOutstandingDebtorsGraph(context, controller, currency),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildKPISectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
    );
  }

  // -------------------------------------------------------------
  // 1. EXECUTIVE HEADER & CONTROLS
  // -------------------------------------------------------------
  Widget _buildExecutiveHeader(BuildContext context, DashboardController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, headerConstraints) {
          final isNarrow = headerConstraints.maxWidth < 780;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AutoDetail Pro Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Offline-First SQLite Business Intelligence', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const CustomerFormDialog()),
                      icon: const Icon(Icons.person_add_rounded, size: 15),
                      label: const Text('Customer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const JobCreateDialog()),
                      icon: const Icon(Icons.build_rounded, size: 15),
                      label: const Text('Job Card'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const GarageExpenseFormDialog()),
                      icon: const Icon(Icons.receipt_long_rounded, size: 15),
                      label: const Text('Expense'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const InvoiceCreateDialog()),
                      icon: const Icon(Icons.receipt_rounded, size: 15),
                      label: const Text('New Invoice'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AutoDetail Pro Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Offline-First SQLite Business Intelligence', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => const CustomerFormDialog()),
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('Customer'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => const JobCreateDialog()),
                          icon: const Icon(Icons.build_rounded, size: 16),
                          label: const Text('Job Card'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => const GarageExpenseFormDialog()),
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text('Expense'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => const InvoiceCreateDialog()),
                          icon: const Icon(Icons.receipt_rounded, size: 16),
                          label: const Text('New Invoice'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),

              // Date Filters Row
              LayoutBuilder(
                builder: (context, dateConstraints) {
                  final isDateNarrow = dateConstraints.maxWidth < 540;
                  return isDateNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primaryLight),
                                const SizedBox(width: 6),
                                const Text('Reporting Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  tooltip: 'Refresh Metrics',
                                  onPressed: () => controller.loadDashboardData(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTimeChip(controller, 'Today', DateFilter.today),
                                  const SizedBox(width: 6),
                                  _buildTimeChip(controller, 'This Week', DateFilter.thisWeek),
                                  const SizedBox(width: 6),
                                  _buildTimeChip(controller, 'This Month', DateFilter.thisMonth),
                                  const SizedBox(width: 6),
                                  _buildTimeChip(controller, 'Last Month', DateFilter.lastMonth),
                                  const SizedBox(width: 6),
                                  _buildCustomDateButton(context, controller),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                            const SizedBox(width: 8),
                            const Text('Reporting Filter:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildTimeChip(controller, 'Today', DateFilter.today),
                                    const SizedBox(width: 8),
                                    _buildTimeChip(controller, 'This Week', DateFilter.thisWeek),
                                    const SizedBox(width: 8),
                                    _buildTimeChip(controller, 'This Month', DateFilter.thisMonth),
                                    const SizedBox(width: 8),
                                    _buildTimeChip(controller, 'Last Month', DateFilter.lastMonth),
                                    const SizedBox(width: 8),
                                    _buildCustomDateButton(context, controller),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded, size: 20),
                                      tooltip: 'Refresh Metrics',
                                      onPressed: () => controller.loadDashboardData(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomDateButton(BuildContext context, DashboardController controller) {
    return Obx(() {
      final isCustom = controller.selectedFilter.value == DateFilter.custom;
      return OutlinedButton.icon(
        onPressed: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (range != null) {
            controller.setFilter(DateFilter.custom, DateTimeRange(start: range.start, end: range.end));
          }
        },
        icon: const Icon(Icons.date_range_rounded, size: 14),
        label: Text(isCustom ? 'Custom Range ✓' : 'Custom Range'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isCustom ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
        ),
      );
    });
  }

  Widget _buildTimeChip(DashboardController controller, String label, DateFilter filter) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == filter;
      return ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        onSelected: (_) => controller.setFilter(filter),
      );
    });
  }

  // -------------------------------------------------------------
  // 2. 18 KPI CARDS
  // -------------------------------------------------------------
  Widget _buildFinancialKPIs(BuildContext context, DashboardMetrics m, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 580 ? 2 : 1;
        final ratio = count == 1 ? 3.2 : (constraints.maxWidth < 650 ? 1.9 : 2.3);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: ratio,
          children: [
            _kpiCard(
              title: 'Total Income',
              value: Formatters.currency(m.totalIncome, symbol: currency),
              subtitle: 'Valid collections in period',
              color: AppColors.success,
              icon: Icons.payments_rounded,
            ),
            _kpiCard(
              title: 'Total Expenses',
              value: Formatters.currency(m.totalExpenses, symbol: currency),
              subtitle: 'Garage, Staff & Salaries',
              color: AppColors.error,
              icon: Icons.receipt_long_rounded,
            ),
            _kpiCard(
              title: 'Net Income',
              value: Formatters.currency(m.netIncome, symbol: currency),
              subtitle: m.netIncome >= 0 ? 'Net Profit' : 'Net Loss',
              color: m.netIncome >= 0 ? AppColors.accent : AppColors.error,
              icon: Icons.trending_up_rounded,
            ),
            _kpiCard(
              title: 'Outstanding Payments',
              value: Formatters.currency(m.outstandingPayments, symbol: currency),
              subtitle: 'Receivables due on invoices',
              color: AppColors.warning,
              icon: Icons.pending_actions_rounded,
              onTap: () => Get.toNamed(AppRoutes.invoices),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOperationalKPIs(BuildContext context, DashboardMetrics m) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1100 ? 6 : constraints.maxWidth > 700 ? 3 : constraints.maxWidth > 400 ? 2 : 1;
        final ratio = count == 1 ? 3.4 : (constraints.maxWidth < 500 ? 1.7 : 2.1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            _kpiCard(title: 'Total Customers', value: '${m.totalCustomers}', subtitle: 'Active client directory', color: AppColors.primary, icon: Icons.people_rounded, onTap: () => Get.toNamed(AppRoutes.customers)),
            _kpiCard(title: 'Total Vehicles', value: '${m.totalVehicles}', subtitle: 'Registered garage fleet', color: AppColors.primaryLight, icon: Icons.directions_car_rounded, onTap: () => Get.toNamed(AppRoutes.vehicles)),
            _kpiCard(title: "Today's Jobs", value: '${m.todaysJobs}', subtitle: 'Booked / Received today', color: AppColors.info, icon: Icons.today_rounded),
            _kpiCard(title: 'In-Progress Jobs', value: '${m.inProgressJobs}', subtitle: 'Active in bays', color: AppColors.warning, icon: Icons.engineering_rounded),
            _kpiCard(title: 'Completed Jobs', value: '${m.completedJobs}', subtitle: 'Detailing finished', color: AppColors.success, icon: Icons.check_circle_outline_rounded),
            _kpiCard(title: 'Ready for Delivery', value: '${m.readyForDeliveryJobs}', subtitle: 'Awaiting customer pickup', color: AppColors.accent, icon: Icons.car_rental_rounded),
          ],
        );
      },
    );
  }

  Widget _buildStaffAndInventoryKPIs(BuildContext context, DashboardMetrics m, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1100 ? 8 : constraints.maxWidth > 700 ? 4 : constraints.maxWidth > 400 ? 2 : 1;
        final ratio = count == 1 ? 3.4 : (constraints.maxWidth < 500 ? 1.6 : 1.9);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            // Staff
            _kpiCard(title: 'Total Staff', value: '${m.totalStaff}', subtitle: 'Active team', color: AppColors.primary, icon: Icons.badge_rounded, onTap: () => Get.toNamed(AppRoutes.staff)),
            _kpiCard(title: 'Present Today', value: '${m.presentToday}', subtitle: 'On duty', color: AppColors.success, icon: Icons.person_pin_circle_rounded),
            _kpiCard(title: 'Absent Today', value: '${m.absentToday}', subtitle: 'Unexcused', color: AppColors.error, icon: Icons.person_off_rounded),
            _kpiCard(title: 'Pending Salaries', value: Formatters.currency(m.pendingSalaries, symbol: currency), subtitle: 'Payroll due', color: AppColors.warning, icon: Icons.payments_outlined),

            // Inventory
            _kpiCard(title: 'Total Stock Items', value: '${m.totalStockItems}', subtitle: 'Chemicals & tools', color: AppColors.primary, icon: Icons.inventory_2_rounded, onTap: () => Get.toNamed(AppRoutes.inventory)),
            _kpiCard(title: 'Low Stock Items', value: '${m.lowStockItems}', subtitle: 'Reorder needed', color: AppColors.warning, icon: Icons.warning_amber_rounded),
            _kpiCard(title: 'Out-of-Stock Items', value: '${m.outOfStockItems}', subtitle: '0 quantity', color: AppColors.error, icon: Icons.remove_circle_outline_rounded),
            _kpiCard(title: 'Stock Purchase Value', value: Formatters.currency(m.stockPurchaseValue, symbol: currency), subtitle: 'Valuation cost', color: AppColors.success, icon: Icons.account_balance_wallet_rounded),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, size: 16, color: color),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. 8 SQLITE CHARTS IMPLEMENTATION
  // -------------------------------------------------------------
  Widget _buildGraphRow({
    required BuildContext context,
    required Widget leftWidget,
    required Widget rightWidget,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 950) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftWidget),
              const SizedBox(width: 16),
              Expanded(child: rightWidget),
            ],
          );
        }
        return Column(
          children: [
            leftWidget,
            const SizedBox(height: 16),
            rightWidget,
          ],
        );
      },
    );
  }

  Widget _chartContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 330,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Graph 1: Daily Income vs Expenses (Last 7 Days)
  Widget _buildDailyIncomeExpenseGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.dailyIncomeVsExpense;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Daily Income vs Expenses (7 Days)',
          subtitle: 'Actual SQLite transaction entries',
          child: const AppEmptyState(icon: Icons.bar_chart_rounded, title: 'No Daily Data', description: 'Log invoices and expenses to populate.'),
        );
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final inc = (list[i]['income'] as num?)?.toDouble() ?? 0.0;
        final exp = (list[i]['expense'] as num?)?.toDouble() ?? 0.0;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: inc, color: AppColors.success, width: 9, borderRadius: BorderRadius.circular(3)),
              BarChartRodData(toY: exp, color: AppColors.error, width: 9, borderRadius: BorderRadius.circular(3)),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Daily Income vs Expenses (Last 7 Days)',
        subtitle: 'Green: Income Received | Red: Total Expenses',
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(list[idx]['label'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1)),
          ),
        ),
      );
    });
  }

  // Graph 2: Monthly Income vs Expenses (Last 6 Months)
  Widget _buildMonthlyIncomeExpenseGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.monthlyIncomeVsExpense;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Monthly Income vs Expenses',
          subtitle: 'Last 6 Months overview',
          child: const AppEmptyState(icon: Icons.calendar_month_rounded, title: 'No Monthly History', description: 'Monthly SQLite records will show here.'),
        );
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final inc = (list[i]['income'] as num?)?.toDouble() ?? 0.0;
        final exp = (list[i]['expense'] as num?)?.toDouble() ?? 0.0;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: inc, color: AppColors.primary, width: 10, borderRadius: BorderRadius.circular(3)),
              BarChartRodData(toY: exp, color: AppColors.error, width: 10, borderRadius: BorderRadius.circular(3)),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Monthly Income vs Expenses (6 Months)',
        subtitle: 'Blue: Revenue Collections | Red: Expenses',
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(list[idx]['label'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1)),
          ),
        ),
      );
    });
  }

  // Graph 3: Net Income Trend (Line Chart)
  Widget _buildNetIncomeTrendGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.netIncomeTrend;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Net Income Trend',
          subtitle: 'Profit / Margin performance curve',
          child: const AppEmptyState(icon: Icons.trending_up_rounded, title: 'No Trend Data', description: 'Calculated from Net = Income - Expenses.'),
        );
      }

      final spots = <FlSpot>[];
      for (var i = 0; i < list.length; i++) {
        final net = (list[i]['net_income'] as num?)?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), net));
      }

      return _chartContainer(
        title: 'Net Income Trend',
        subtitle: 'Monthly Net Margin curve from SQLite records',
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.accent,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(list[idx]['label'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1)),
          ),
        ),
      );
    });
  }

  // Graph 4: Payment Collection Breakdown by Method
  Widget _buildPaymentCollectionGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.paymentCollection;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Payment Collection Breakdown',
          subtitle: 'Collections categorized by method',
          child: const AppEmptyState(icon: Icons.pie_chart_rounded, title: 'No Collections', description: 'Recorded payments will display here.'),
        );
      }

      final colors = [AppColors.success, AppColors.primary, AppColors.info, AppColors.accent, AppColors.warning];
      final sections = <PieChartSectionData>[];
      for (var i = 0; i < list.length; i++) {
        final amount = (list[i]['total_amount'] as num?)?.toDouble() ?? 0.0;
        final method = list[i]['payment_method'] as String? ?? 'Cash';
        final color = colors[i % colors.length];

        sections.add(
          PieChartSectionData(
            value: amount,
            title: '$method\n${Formatters.currency(amount, symbol: currency)}',
            color: color,
            radius: 55,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }

      return _chartContainer(
        title: 'Payment Collection Trend / Breakdown',
        subtitle: 'Cash, Bank Transfer, Online & Cards',
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 36,
            sectionsSpace: 2,
          ),
        ),
      );
    });
  }

  // Graph 5: Jobs / Services Trend by Status
  Widget _buildJobsTrendGraph(BuildContext context, DashboardController controller) {
    return Obx(() {
      final list = controller.jobsByStatus;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Jobs / Services Trend',
          subtitle: 'Breakdown across garage bays',
          child: const AppEmptyState(icon: Icons.build_rounded, title: 'No Jobs Logged', description: 'Create job cards to see status breakdown.'),
        );
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final cnt = (list[i]['count'] as num?)?.toDouble() ?? 0.0;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: cnt, color: AppColors.primaryLight, width: 14, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Jobs & Services Status Distribution',
        subtitle: 'Real-time vehicle workload',
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      final st = list[idx]['status'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(st.length > 7 ? '${st.substring(0, 6)}..' : st, style: const TextStyle(fontSize: 9, color: AppColors.textDarkSecondary)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1)),
          ),
        ),
      );
    });
  }

  // Graph 6: Staff Attendance Overview (Last 30 Days)
  Widget _buildAttendanceDonutGraph(BuildContext context, DashboardController controller) {
    return Obx(() {
      final map = controller.attendanceOverview;
      final present = map['Present'] ?? 0;
      final absent = map['Absent'] ?? 0;
      final halfDay = map['Half Day'] ?? 0;
      final leave = map['Leave'] ?? 0;
      final total = present + absent + halfDay + leave;

      if (total == 0) {
        return _chartContainer(
          title: 'Staff Attendance Overview (30 Days)',
          subtitle: 'Attendance register log',
          child: const AppEmptyState(icon: Icons.event_available_rounded, title: 'No Attendance', description: 'Mark daily attendance in Staff module.'),
        );
      }

      final sections = [
        PieChartSectionData(value: present.toDouble(), title: 'Present ($present)', color: AppColors.success, radius: 48, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(value: absent.toDouble(), title: 'Absent ($absent)', color: AppColors.error, radius: 48, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(value: halfDay.toDouble(), title: 'Half ($halfDay)', color: AppColors.info, radius: 48, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(value: leave.toDouble(), title: 'Leave ($leave)', color: AppColors.warning, radius: 48, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ];

      return _chartContainer(
        title: 'Staff Attendance Overview (Last 30 Days)',
        subtitle: 'Present, Absent, Half Day & Leaves',
        child: PieChart(
          PieChartData(sections: sections, centerSpaceRadius: 36, sectionsSpace: 2),
        ),
      );
    });
  }

  // Graph 7: Inventory Quantity Overview (Top items by stock)
  Widget _buildInventoryDistributionGraph(BuildContext context, DashboardController controller) {
    return Obx(() {
      final list = controller.inventoryDistribution;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Inventory Quantity Overview',
          subtitle: 'Highest stocked chemicals & materials',
          child: const AppEmptyState(icon: Icons.inventory_2_rounded, title: 'No Inventory', description: 'Add products in Inventory module.'),
        );
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final qty = (list[i]['current_quantity'] as num?)?.toDouble() ?? 0.0;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: qty, color: AppColors.primary, width: 12, borderRadius: BorderRadius.circular(3)),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Inventory Quantity Overview',
        subtitle: 'Current physical quantity on shelf',
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      final name = list[idx]['item_name'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(name.length > 7 ? '${name.substring(0, 6)}..' : name, style: const TextStyle(fontSize: 9, color: AppColors.textDarkSecondary)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1)),
          ),
        ),
      );
    });
  }

  // Graph 8: Outstanding Payment Trend / Top Debtors
  Widget _buildOutstandingDebtorsGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.topDebtors;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Outstanding Payment Trend / Debtors',
          subtitle: 'Customers with outstanding invoice balance',
          child: const AppEmptyState(icon: Icons.check_circle_outline_rounded, title: 'No Outstanding Debtors', description: 'All invoices are fully settled!'),
        );
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final bal = (list[i]['outstanding'] as num?)?.toDouble() ?? 0.0;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: bal, color: AppColors.warning, width: 14, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Outstanding Payment Trend (Top Debtors)',
        subtitle: 'Receivables due per customer account',
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      final name = list[idx]['customer_name'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(name.length > 7 ? '${name.substring(0, 6)}..' : name, style: const TextStyle(fontSize: 9, color: AppColors.textDarkSecondary)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark, strokeWidth: 1)),
          ),
        ),
      );
    });
  }
}
