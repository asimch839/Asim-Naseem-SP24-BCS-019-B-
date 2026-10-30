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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeTab = 0; // 0: Overview & Graph Hub, 1: Workshop Floor, 2: Financial Center, 3: Complete Matrix
  String _selectedGraph = 'income_vs_expense';

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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Top Header with Quick Action Buttons & Date Filters
              _buildExecutiveHeader(context, controller),
              const SizedBox(height: 16),

              // 2. High-Impact Core Metric Ribbon (At-A-Glance Overview)
              _buildCoreSummaryRibbon(context, m, currency),
              const SizedBox(height: 18),

              // 3. Clean Segmented Category Switcher
              _buildTabSwitcher(),
              const SizedBox(height: 16),

              // 4. Tabbed Content
              if (_activeTab == 0) ...[
                // Overview & Unified Analytics Studio (Dropdown Selectable Graphs)
                _buildUnifiedAnalyticsStudio(context, controller, currency),
                const SizedBox(height: 22),

                // Workshop Floor & Customer Highlights
                _buildKPISectionTitle('Workshop Floor & Customer Activity'),
                const SizedBox(height: 10),
                _buildOperationalKPIs(context, m),
                const SizedBox(height: 20),

                // Team Attendance & Inventory Alerts
                _buildKPISectionTitle('Team Attendance & Inventory Alerts'),
                const SizedBox(height: 10),
                _buildStaffAndInventoryKPIs(context, m, currency),
                const SizedBox(height: 20),

                // Financial Highlights
                _buildKPISectionTitle('Financial Performance Highlights'),
                const SizedBox(height: 10),
                _buildFinancialKPIs(context, m, currency),
              ] else if (_activeTab == 1) ...[
                // Workshop Floor View
                _buildKPISectionTitle('Workshop Floor & Active Customer Activity'),
                const SizedBox(height: 10),
                _buildOperationalKPIs(context, m),
                const SizedBox(height: 20),
                _buildUnifiedAnalyticsStudio(context, controller, currency),
                const SizedBox(height: 20),
                _buildKPISectionTitle('Team Attendance & Inventory Alerts'),
                const SizedBox(height: 10),
                _buildStaffAndInventoryKPIs(context, m, currency),
              ] else if (_activeTab == 2) ...[
                // Financial Center View
                _buildKPISectionTitle('Financial Performance & Revenue Summary'),
                const SizedBox(height: 10),
                _buildFinancialKPIs(context, m, currency),
                const SizedBox(height: 20),
                _buildUnifiedAnalyticsStudio(context, controller, currency),
                const SizedBox(height: 20),
                _buildOutstandingDebtorsGraph(context, controller, currency),
              ] else ...[
                // Complete Matrix View (Full Expanded Overview)
                _buildKPISectionTitle('1. Financial Performance'),
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
                _buildUnifiedAnalyticsStudio(context, controller, currency),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // --- CORE SUMMARY RIBBON (4 AT-A-GLANCE METRICS) ---
  Widget _buildCoreSummaryRibbon(BuildContext context, DashboardMetrics m, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 950 ? 4 : constraints.maxWidth > 520 ? 2 : 1;
        final ratio = count == 1 ? 3.6 : (constraints.maxWidth < 620 ? 1.8 : 2.2);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            _heroMetricCard(
              title: 'Period Revenue',
              value: Formatters.currency(m.totalIncome, symbol: currency),
              subtitle: 'Net: ${Formatters.currency(m.netIncome, symbol: currency)}',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () => setState(() => _activeTab = 1),
            ),
            _heroMetricCard(
              title: 'Active Workshop Jobs',
              value: '${m.inProgressJobs} In Bay',
              subtitle: '${m.readyForDeliveryJobs} Ready • ${m.todaysJobs} Today',
              icon: Icons.directions_car_filled_rounded,
              color: const Color(0xFF14B8A6),
              onTap: () => Get.toNamed(AppRoutes.jobs),
            ),
            _heroMetricCard(
              title: 'Unpaid Receivables',
              value: Formatters.currency(m.outstandingPayments, symbol: currency),
              subtitle: 'Outstanding on invoices',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => Get.toNamed(AppRoutes.invoices),
            ),
            _heroMetricCard(
              title: 'Inventory Alerts',
              value: '${m.lowStockItems + m.outOfStockItems} Items',
              subtitle: '${m.lowStockItems} Low • ${m.outOfStockItems} Out of Stock',
              icon: Icons.warning_amber_rounded,
              color: (m.lowStockItems + m.outOfStockItems > 0) ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              onTap: () => Get.toNamed(AppRoutes.inventory),
            ),
          ],
        );
      },
    );
  }

  Widget _heroMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.12 : 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                  maxLines: 1,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SEGMENTED CATEGORY SWITCHER ---
  Widget _buildTabSwitcher() {
    final tabs = [
      {'title': 'Overview & Graph Hub', 'icon': Icons.insights_rounded},
      {'title': 'Workshop Floor', 'icon': Icons.engineering_rounded},
      {'title': 'Financial Center', 'icon': Icons.account_balance_rounded},
      {'title': 'Complete Matrix', 'icon': Icons.dashboard_customize_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _activeTab == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                tabs[idx]['icon'] as IconData,
                size: 15,
                color: isSelected ? Colors.white : AppColors.primaryLight,
              ),
              label: Text(
                tabs[idx]['title'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              onSelected: (_) => setState(() => _activeTab = idx),
            ),
          );
        }),
      ),
    );
  }

  String _getFilterLabel(DashboardController controller) {
    switch (controller.selectedFilter.value) {
      case DateFilter.today:
        return 'Daily (Today)';
      case DateFilter.thisWeek:
        return 'Weekly (This Week)';
      case DateFilter.thisMonth:
        return 'Monthly (This Month)';
      case DateFilter.lastMonth:
        return 'Last Month';
      case DateFilter.custom:
        final range = controller.customDateRange.value;
        if (range != null) {
          return 'Custom (${Formatters.date(range.start)} - ${Formatters.date(range.end)})';
        }
        return 'Custom Range';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in progress':
      case 'in bay':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'ready for delivery':
        return const Color(0xFF14B8A6);
      case 'delivered':
        return const Color(0xFF6366F1);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primaryLight;
    }
  }

  Widget _chartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary)),
      ],
    );
  }

  // -------------------------------------------------------------
  // UNIFIED ANALYTICS STUDIO (DROPDOWN-SELECTABLE GRAPHS)
  // -------------------------------------------------------------
  Widget _buildUnifiedAnalyticsStudio(BuildContext context, DashboardController controller, String currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periodLabel = _getFilterLabel(controller);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Studio Header with Title, Live Status & Dropdown Selector
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 780;
              final headerInfo = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.accent.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.insights_rounded, size: 20, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visual Analytics & Intelligence Hub',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Filtered: $periodLabel • Real-Time SQLite Sync',
                                style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final dropdownControls = Row(
                mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Expanded(
                    flex: isNarrow ? 1 : 0,
                    child: _buildGraphDropdownSelector(isDark),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => controller.loadDashboardData(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Refresh SQLite Data',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      foregroundColor: AppColors.primaryLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 14),
                    dropdownControls,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 14),
                  dropdownControls,
                ],
              );
            },
          ),

          const Divider(height: 26),

          // Active Selected Graph
          _buildActiveGraphView(context, controller, currency),
        ],
      ),
    );
  }

  Widget _buildGraphDropdownSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGraph,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.primaryLight),
          ),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: isDark ? const Color(0xFF1A2436) : Colors.white,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedGraph = val);
            }
          },
          items: [
            _buildDropdownItem('income_vs_expense', 'Income vs Expenses', Icons.bar_chart_rounded, AppColors.success, '2-Bar'),
            _buildDropdownItem('net_income_trend', 'Net Profit & Margin Trend', Icons.show_chart_rounded, AppColors.accent, 'Line'),
            _buildDropdownItem('payment_methods', 'Payment Methods Breakdown', Icons.pie_chart_rounded, const Color(0xFF8B5CF6), 'Circle'),
            _buildDropdownItem('jobs_workload', 'Detailing Jobs Workload', Icons.build_circle_rounded, const Color(0xFF3B82F6), 'Bar'),
            _buildDropdownItem('monthly_history', '6-Month Income vs Expenses', Icons.calendar_view_month_rounded, AppColors.primary, 'History'),
            _buildDropdownItem('staff_attendance', 'Staff Attendance Register', Icons.people_outline_rounded, AppColors.info, 'Circle'),
            _buildDropdownItem('inventory_stock', 'Inventory Stock Quantities', Icons.inventory_2_rounded, AppColors.warning, 'Bar'),
            _buildDropdownItem('top_debtors', 'Top Outstanding Debtors', Icons.pending_actions_rounded, AppColors.error, 'Bar'),
            _buildDropdownItem('all_four_grid', 'Executive 4-in-1 Comparison Grid', Icons.grid_view_rounded, AppColors.primaryLight, 'Grid'),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label, IconData icon, Color color, String badge) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGraphView(BuildContext context, DashboardController controller, String currency) {
    switch (_selectedGraph) {
      case 'income_vs_expense':
        return _buildRedesignedIncomeExpenseGraph(context, controller, currency);
      case 'net_income_trend':
        return _buildRedesignedNetIncomeTrendGraph(context, controller, currency);
      case 'payment_methods':
        return _buildRedesignedPaymentMethodsGraph(context, controller, currency);
      case 'jobs_workload':
        return _buildRedesignedJobsTrendGraph(context, controller);
      case 'monthly_history':
        return _buildMonthlyIncomeExpenseGraph(context, controller, currency);
      case 'staff_attendance':
        return _buildAttendanceDonutGraph(context, controller);
      case 'inventory_stock':
        return _buildInventoryDistributionGraph(context, controller);
      case 'top_debtors':
        return _buildOutstandingDebtorsGraph(context, controller, currency);
      case 'all_four_grid':
        return Column(
          children: [
            _buildGraphRow(
              context: context,
              leftWidget: _buildDailyIncomeExpenseGraph(context, controller, currency),
              rightWidget: _buildNetIncomeTrendGraph(context, controller, currency),
            ),
            const SizedBox(height: 16),
            _buildGraphRow(
              context: context,
              leftWidget: _buildPaymentCollectionGraph(context, controller, currency),
              rightWidget: _buildJobsTrendGraph(context, controller),
            ),
          ],
        );
      default:
        return _buildRedesignedIncomeExpenseGraph(context, controller, currency);
    }
  }

  // --- REDESIGNED GRAPHS FOR THE UNIFIED STUDIO ---

  Widget _buildRedesignedIncomeExpenseGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.dailyIncomeVsExpense;
      if (list.isEmpty) {
        return const SizedBox(
          height: 300,
          child: AppEmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No Transaction Data',
            description: 'Log invoices and expenses for this period to view dual bar trends.',
          ),
        );
      }

      double maxVal = 0.0;
      double totalInc = 0.0;
      double totalExp = 0.0;
      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final inc = (list[i]['income'] as num?)?.toDouble() ?? 0.0;
        final exp = (list[i]['expense'] as num?)?.toDouble() ?? 0.0;
        totalInc += inc;
        totalExp += exp;
        if (inc > maxVal) maxVal = inc;
        if (exp > maxVal) maxVal = exp;

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: inc,
                color: AppColors.success,
                width: list.length > 7 ? 8 : 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              BarChartRodData(
                toY: exp,
                color: AppColors.error,
                width: list.length > 7 ? 8 : 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ],
          ),
        );
      }

      final net = totalInc - totalExp;
      final isProfit = net >= 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _metricBadge(
                label: 'Total Income',
                value: Formatters.currency(totalInc, symbol: currency),
                color: AppColors.success,
                icon: Icons.arrow_downward_rounded,
              ),
              _metricBadge(
                label: 'Total Expenses',
                value: Formatters.currency(totalExp, symbol: currency),
                color: AppColors.error,
                icon: Icons.arrow_upward_rounded,
              ),
              _metricBadge(
                label: isProfit ? 'Net Operating Profit' : 'Net Loss',
                value: '${isProfit ? "+" : ""}${Formatters.currency(net, symbol: currency)}',
                color: isProfit ? AppColors.accent : AppColors.error,
                icon: isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 270,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.18 : 100.0,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < list.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              list[idx]['label'] as String,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.45), strokeWidth: 1),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRedesignedNetIncomeTrendGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.netIncomeTrend;
      if (list.isEmpty) {
        return const SizedBox(
          height: 300,
          child: AppEmptyState(
            icon: Icons.trending_up_rounded,
            title: 'No Net Margin Trend',
            description: 'Net Margin is calculated from Income minus Expenses in SQLite.',
          ),
        );
      }

      double minNet = 0.0;
      double maxNet = 0.0;
      double totalNet = 0.0;
      final spots = <FlSpot>[];
      for (var i = 0; i < list.length; i++) {
        final net = (list[i]['net_income'] as num?)?.toDouble() ?? 0.0;
        totalNet += net;
        if (net < minNet) minNet = net;
        if (net > maxNet) maxNet = net;
        spots.add(FlSpot(i.toDouble(), net));
      }

      final isProfit = totalNet >= 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _metricBadge(
                label: 'Cumulative Net',
                value: '${isProfit ? "+" : ""}${Formatters.currency(totalNet, symbol: currency)}',
                color: isProfit ? AppColors.accent : AppColors.error,
                icon: isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              ),
              _metricBadge(
                label: 'Peak Period Net',
                value: Formatters.currency(maxNet, symbol: currency),
                color: AppColors.success,
                icon: Icons.vertical_align_top_rounded,
              ),
              _metricBadge(
                label: 'Lowest Period Net',
                value: Formatters.currency(minNet, symbol: currency),
                color: minNet < 0 ? AppColors.error : AppColors.warning,
                icon: Icons.vertical_align_bottom_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 270,
            child: LineChart(
              LineChartData(
                minY: minNet < 0 ? minNet * 1.25 : 0,
                maxY: maxNet > 0 ? maxNet * 1.22 : 100.0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.accent,
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.accent,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.35),
                          AppColors.accent.withValues(alpha: 0.01),
                        ],
                      ),
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
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < list.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              list[idx]['label'] as String,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.45), strokeWidth: 1),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRedesignedPaymentMethodsGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.paymentCollection;
      double total = 0.0;
      for (var item in list) {
        total += (item['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      if (list.isEmpty || total <= 0) {
        return const SizedBox(
          height: 300,
          child: AppEmptyState(
            icon: Icons.pie_chart_rounded,
            title: 'No Collections in Period',
            description: 'No payment transactions recorded for this date filter. Change date filter or log payments.',
          ),
        );
      }

      final palette = [
        const Color(0xFF10B981), // Cash - Emerald
        const Color(0xFF3B82F6), // Card - Blue
        const Color(0xFF8B5CF6), // Online / UPI - Purple
        const Color(0xFFF59E0B), // Bank Transfer - Amber
        const Color(0xFF06B6D4), // Cheque / Other - Cyan
      ];

      final sections = <PieChartSectionData>[];
      for (var i = 0; i < list.length; i++) {
        final amount = (list[i]['total_amount'] as num?)?.toDouble() ?? 0.0;
        final pct = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';
        final color = palette[i % palette.length];

        sections.add(
          PieChartSectionData(
            value: amount,
            title: '$pct%',
            color: color,
            radius: 54,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 640;
          final donutWidget = SizedBox(
            height: 270,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 44,
                    sectionsSpace: 3,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 22, color: AppColors.primaryLight),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.compactCurrency(total, symbol: currency),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Total Received',
                      style: TextStyle(fontSize: 9, color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );

          final methodsListWidget = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(list.length, (idx) {
              final method = list[idx]['payment_method'] as String? ?? 'Cash';
              final amount = (list[idx]['total_amount'] as num?)?.toDouble() ?? 0.0;
              final pctDouble = total > 0 ? (amount / total) : 0.0;
              final color = palette[idx % palette.length];

              IconData methodIcon;
              switch (method.toLowerCase()) {
                case 'cash':
                  methodIcon = Icons.payments_rounded;
                  break;
                case 'card':
                  methodIcon = Icons.credit_card_rounded;
                  break;
                case 'bank transfer':
                  methodIcon = Icons.account_balance_rounded;
                  break;
                default:
                  methodIcon = Icons.qr_code_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardElevated : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(methodIcon, size: 16, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(method, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                Formatters.currency(amount, symbol: currency),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pctDouble,
                              backgroundColor: color.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: donutWidget),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: methodsListWidget),
              ],
            );
          }

          return Column(
            children: [
              donutWidget,
              const SizedBox(height: 14),
              methodsListWidget,
            ],
          );
        },
      );
    });
  }

  Widget _buildRedesignedJobsTrendGraph(BuildContext context, DashboardController controller) {
    return Obx(() {
      final list = controller.jobsByStatus;
      if (list.isEmpty) {
        return const SizedBox(
          height: 300,
          child: AppEmptyState(
            icon: Icons.build_circle_rounded,
            title: 'No Jobs Logged',
            description: 'Create job cards to see status breakdown across bays.',
          ),
        );
      }

      int totalJobs = 0;
      double maxCount = 0.0;
      for (var item in list) {
        final cnt = (item['count'] as num?)?.toDouble() ?? 0.0;
        totalJobs += cnt.toInt();
        if (cnt > maxCount) maxCount = cnt;
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final cnt = (list[i]['count'] as num?)?.toDouble() ?? 0.0;
        final st = list[i]['status'] as String? ?? '';
        final color = _getStatusColor(st);

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cnt,
                color: color,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricBadge(
                label: 'Total Workload',
                value: '$totalJobs Vehicles',
                color: AppColors.primary,
                icon: Icons.directions_car_filled_rounded,
              ),
              ...List.generate(list.length, (idx) {
                final st = list[idx]['status'] as String? ?? '';
                final cnt = list[idx]['count'] ?? 0;
                final col = _getStatusColor(st);
                return _miniStatusPill(st, '$cnt', col);
              }),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 270,
            child: BarChart(
              BarChartData(
                maxY: maxCount > 0 ? maxCount * 1.25 : 10.0,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < list.length) {
                          final st = list[idx]['status'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              st.length > 9 ? '${st.substring(0, 8)}..' : st,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.45), strokeWidth: 1),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _metricBadge({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatusPill(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('$label: $count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
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
    final businessName = AuthService.to.currentBusiness.value?.name ?? 'AutoDetail Pro Center';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek top gradient accent bar
          Container(
            height: 3.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent, Color(0xFF8B5CF6)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, headerConstraints) {
                final isNarrow = headerConstraints.maxWidth < 800;

                final brandingWidget = Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.speed_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'SQLite Database Active • Real-Time Engine',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDarkSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final quickActionsWidget = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => showDialog(context: context, builder: (_) => const CustomerFormDialog()),
                      icon: const Icon(Icons.person_add_rounded, size: 15),
                      label: const Text('Customer'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => showDialog(context: context, builder: (_) => const GarageExpenseFormDialog()),
                      icon: const Icon(Icons.receipt_long_rounded, size: 15),
                      label: const Text('Expense'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const JobCreateDialog()),
                      icon: const Icon(Icons.build_rounded, size: 15),
                      label: const Text('Job Card'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const InvoiceCreateDialog()),
                      icon: const Icon(Icons.receipt_rounded, size: 15),
                      label: const Text('New Invoice'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNarrow) ...[
                      brandingWidget,
                      const SizedBox(height: 14),
                      quickActionsWidget,
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: brandingWidget),
                          const SizedBox(width: 14),
                          quickActionsWidget,
                        ],
                      ),
                    ],
                    const Divider(height: 26),

                    // Date Filters Row
                    LayoutBuilder(
                      builder: (context, dateConstraints) {
                        final isDateNarrow = dateConstraints.maxWidth < 560;
                        return isDateNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primaryLight),
                                      const SizedBox(width: 6),
                                      const Text('Date Reporting Scope:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.refresh_rounded, size: 18),
                                        tooltip: 'Refresh Metrics',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                          foregroundColor: AppColors.primaryLight,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => controller.loadDashboardData(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildTimeChip(controller, 'Daily (Today)', DateFilter.today),
                                        const SizedBox(width: 6),
                                        _buildTimeChip(controller, 'Weekly (This Week)', DateFilter.thisWeek),
                                        const SizedBox(width: 6),
                                        _buildTimeChip(controller, 'Monthly (This Month)', DateFilter.thisMonth),
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
                                  const Text('Date Scope:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildTimeChip(controller, 'Daily (Today)', DateFilter.today),
                                          const SizedBox(width: 8),
                                          _buildTimeChip(controller, 'Weekly (This Week)', DateFilter.thisWeek),
                                          const SizedBox(width: 8),
                                          _buildTimeChip(controller, 'Monthly (This Month)', DateFilter.thisMonth),
                                          const SizedBox(width: 8),
                                          _buildTimeChip(controller, 'Last Month', DateFilter.lastMonth),
                                          const SizedBox(width: 8),
                                          _buildCustomDateButton(context, controller),
                                          const SizedBox(width: 10),
                                          IconButton.filledTonal(
                                            icon: const Icon(Icons.refresh_rounded, size: 18),
                                            tooltip: 'Refresh Metrics & Charts',
                                            style: IconButton.styleFrom(
                                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                              foregroundColor: AppColors.primaryLight,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateButton(BuildContext context, DashboardController controller) {
    return Obx(() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final isCustom = controller.selectedFilter.value == DateFilter.custom;
      final range = controller.customDateRange.value;
      String label = 'Custom Range';
      if (isCustom && range != null) {
        label = 'Custom (${Formatters.date(range.start)} - ${Formatters.date(range.end)})';
      }

      return OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDateRange: controller.customDateRange.value,
          );
          if (picked != null) {
            final endInclusive = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
            controller.setFilter(DateFilter.custom, DateTimeRange(start: picked.start, end: endInclusive));
          }
        },
        icon: Icon(
          Icons.date_range_rounded,
          size: 14,
          color: isCustom ? Colors.white : AppColors.primaryLight,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCustom ? FontWeight.bold : FontWeight.w500,
            color: isCustom ? Colors.white : (isDark ? Colors.grey.shade300 : AppColors.textLightPrimary),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isCustom ? AppColors.primary : (isDark ? AppColors.darkCardElevated : Colors.grey.shade100),
          side: BorderSide(
            color: isCustom ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    });
  }

  Widget _buildTimeChip(DashboardController controller, String label, DateFilter filter) {
    return Obx(() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final isSelected = controller.selectedFilter.value == filter;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : AppColors.textLightPrimary),
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        backgroundColor: isDark ? AppColors.darkCardElevated : Colors.grey.shade100,
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
    String? badgeText,
    Widget? trailingHeader,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      height: 350,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailingHeader,
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Graph 1: Income vs Expenses (Bar Chart 1 - Period Filtered)
  Widget _buildDailyIncomeExpenseGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.dailyIncomeVsExpense;
      final periodLabel = _getFilterLabel(controller);
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Income vs Expenses ($periodLabel)',
          subtitle: 'Dual Bar Chart • SQLite transactions',
          badgeText: 'Bar Chart 1',
          child: const AppEmptyState(icon: Icons.bar_chart_rounded, title: 'No Transaction Data', description: 'Log invoices and expenses for this period.'),
        );
      }

      double maxVal = 0.0;
      double totalInc = 0.0;
      double totalExp = 0.0;
      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final inc = (list[i]['income'] as num?)?.toDouble() ?? 0.0;
        final exp = (list[i]['expense'] as num?)?.toDouble() ?? 0.0;
        totalInc += inc;
        totalExp += exp;
        if (inc > maxVal) maxVal = inc;
        if (exp > maxVal) maxVal = exp;

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: inc,
                color: AppColors.success,
                width: list.length > 7 ? 6 : 9,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: exp,
                color: AppColors.error,
                width: list.length > 7 ? 6 : 9,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Income vs Expenses ($periodLabel)',
        subtitle: 'Dual Bar Chart • Green: Income | Red: Expenses',
        badgeText: 'Bar Chart 1',
        trailingHeader: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chartLegendItem('Inc: ${Formatters.compactCurrency(totalInc, symbol: currency)}', AppColors.success),
            const SizedBox(width: 8),
            _chartLegendItem('Exp: ${Formatters.compactCurrency(totalExp, symbol: currency)}', AppColors.error),
          ],
        ),
        child: BarChart(
          BarChartData(
            maxY: maxVal > 0 ? maxVal * 1.15 : 100.0,
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          list[idx]['label'] as String,
                          style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.5), strokeWidth: 1),
            ),
          ),
        ),
      );
    });
  }

  // Graph 2: Monthly Income vs Expenses (Historical Baseline)
  Widget _buildMonthlyIncomeExpenseGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.monthlyIncomeVsExpense;
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Monthly Income vs Expenses',
          subtitle: 'Last 6 Months historical overview',
          badgeText: 'History Bar',
          child: const AppEmptyState(icon: Icons.calendar_month_rounded, title: 'No Monthly History', description: 'Monthly SQLite records will show here.'),
        );
      }

      double maxVal = 0.0;
      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final inc = (list[i]['income'] as num?)?.toDouble() ?? 0.0;
        final exp = (list[i]['expense'] as num?)?.toDouble() ?? 0.0;
        if (inc > maxVal) maxVal = inc;
        if (exp > maxVal) maxVal = exp;

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: inc, color: AppColors.primary, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
              BarChartRodData(toY: exp, color: AppColors.error, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Monthly Income vs Expenses',
        subtitle: 'Last 6 Months • Blue: Revenue | Red: Expenses',
        badgeText: 'History Bar',
        child: BarChart(
          BarChartData(
            maxY: maxVal > 0 ? maxVal * 1.15 : 100.0,
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
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
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.5), strokeWidth: 1)),
          ),
        ),
      );
    });
  }

  // Graph 3: Net Income Trend (Line Chart - Period Filtered)
  Widget _buildNetIncomeTrendGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.netIncomeTrend;
      final periodLabel = _getFilterLabel(controller);
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Net Profit & Margin Trend ($periodLabel)',
          subtitle: 'Line Chart • Net = Income minus Expenses',
          badgeText: 'Line Chart',
          child: const AppEmptyState(icon: Icons.trending_up_rounded, title: 'No Trend Data', description: 'Calculated from Net = Income - Expenses.'),
        );
      }

      double minNet = 0.0;
      double maxNet = 0.0;
      double totalNet = 0.0;
      final spots = <FlSpot>[];
      for (var i = 0; i < list.length; i++) {
        final net = (list[i]['net_income'] as num?)?.toDouble() ?? 0.0;
        totalNet += net;
        if (net < minNet) minNet = net;
        if (net > maxNet) maxNet = net;
        spots.add(FlSpot(i.toDouble(), net));
      }

      final isPositiveNet = totalNet >= 0;

      return _chartContainer(
        title: 'Net Profit & Margin Trend ($periodLabel)',
        subtitle: 'Line Chart • Profit / Loss trajectory',
        badgeText: 'Line Chart',
        trailingHeader: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (isPositiveNet ? AppColors.accent : AppColors.error).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Net: ${Formatters.compactCurrency(totalNet, symbol: currency)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isPositiveNet ? AppColors.accent : AppColors.error,
            ),
          ),
        ),
        child: LineChart(
          LineChartData(
            minY: minNet < 0 ? minNet * 1.2 : 0,
            maxY: maxNet > 0 ? maxNet * 1.2 : 100.0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: AppColors.accent,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.02),
                    ],
                  ),
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
                  reservedSize: 26,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          list[idx]['label'] as String,
                          style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.5), strokeWidth: 1),
            ),
          ),
        ),
      );
    });
  }

  // Graph 4: Payment Collection Breakdown by Method (Circle Chart - Period Filtered)
  Widget _buildPaymentCollectionGraph(BuildContext context, DashboardController controller, String currency) {
    return Obx(() {
      final list = controller.paymentCollection;
      final periodLabel = _getFilterLabel(controller);
      double total = 0.0;
      for (var item in list) {
        total += (item['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      if (list.isEmpty || total <= 0) {
        return _chartContainer(
          title: 'Payment Methods Breakdown ($periodLabel)',
          subtitle: 'Circle Donut Chart • Collections by method',
          badgeText: 'Circle Chart',
          child: const AppEmptyState(
            icon: Icons.pie_chart_rounded,
            title: 'No Collections in Period',
            description: 'No payments recorded for this date filter.',
          ),
        );
      }

      final palette = [
        const Color(0xFF10B981), // Cash - Emerald
        const Color(0xFF3B82F6), // Card - Blue
        const Color(0xFF8B5CF6), // Online - Purple
        const Color(0xFFF59E0B), // Bank Transfer - Amber
        const Color(0xFF06B6D4), // Cheque / Other - Cyan
      ];

      final sections = <PieChartSectionData>[];
      for (var i = 0; i < list.length; i++) {
        final amount = (list[i]['total_amount'] as num?)?.toDouble() ?? 0.0;
        final pct = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';
        final color = palette[i % palette.length];

        sections.add(
          PieChartSectionData(
            value: amount,
            title: '$pct%',
            color: color,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }

      return _chartContainer(
        title: 'Payment Methods Breakdown ($periodLabel)',
        subtitle: 'Circle Donut Chart • Cash, Card, Online & Bank Transfers',
        badgeText: 'Circle Chart',
        trailingHeader: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Total: ${Formatters.compactCurrency(total, symbol: currency)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 38,
                      sectionsSpace: 3,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.primaryLight),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.compactCurrency(total, symbol: currency),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(list.length, (idx) {
                final method = list[idx]['payment_method'] as String? ?? 'Cash';
                final amount = (list[idx]['total_amount'] as num?)?.toDouble() ?? 0.0;
                final color = palette[idx % palette.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      '$method (${Formatters.compactCurrency(amount, symbol: currency)})',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.textDarkSecondary),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  // Graph 5: Jobs / Services Trend by Status (Bar Chart 2 - Period Filtered)
  Widget _buildJobsTrendGraph(BuildContext context, DashboardController controller) {
    return Obx(() {
      final list = controller.jobsByStatus;
      final periodLabel = _getFilterLabel(controller);
      if (list.isEmpty) {
        return _chartContainer(
          title: 'Detailing Jobs Workload ($periodLabel)',
          subtitle: 'Bar Chart • Volume across workshop stages',
          badgeText: 'Bar Chart 2',
          child: const AppEmptyState(icon: Icons.build_rounded, title: 'No Jobs Logged', description: 'Create job cards to see status breakdown.'),
        );
      }

      int totalJobs = 0;
      double maxCount = 0.0;
      for (var item in list) {
        final cnt = (item['count'] as num?)?.toDouble() ?? 0.0;
        totalJobs += cnt.toInt();
        if (cnt > maxCount) maxCount = cnt;
      }

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < list.length; i++) {
        final cnt = (list[i]['count'] as num?)?.toDouble() ?? 0.0;
        final st = list[i]['status'] as String? ?? '';
        final color = _getStatusColor(st);

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cnt,
                color: color,
                width: 15,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        );
      }

      return _chartContainer(
        title: 'Detailing Jobs Workload ($periodLabel)',
        subtitle: 'Bar Chart • Real-time vehicle volume per stage',
        badgeText: 'Bar Chart 2',
        trailingHeader: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Total: $totalJobs Jobs',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
          ),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxCount > 0 ? maxCount * 1.25 : 10.0,
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < list.length) {
                      final st = list[idx]['status'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          st.length > 8 ? '${st.substring(0, 7)}..' : st,
                          style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: AppColors.borderDark.withValues(alpha: 0.5), strokeWidth: 1),
            ),
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
