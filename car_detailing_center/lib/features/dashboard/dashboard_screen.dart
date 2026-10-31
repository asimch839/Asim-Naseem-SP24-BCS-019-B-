import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/date_range_picker_widget.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/summary_card.dart';
import '../../data/repositories/dashboard_report_repository.dart';
import '../customers/customer_form_dialog.dart';
import '../expenses/garage_expense_screen.dart';
import '../invoices/invoice_create_dialog.dart';
import '../jobs/job_create_dialog.dart';
import '../vehicles/vehicle_form_dialog.dart';
import 'dashboard_controller.dart';
import 'widgets/dashboard_income_expense_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return AppScaffold(
      currentRoute: AppRoutes.dashboard,
      title: 'Executive Dashboard',
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

        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final isMobile = screenWidth < 768;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Section: Responsive Title & Date Filter
              ResponsiveHeader(
                title: 'Executive Dashboard',
                subtitle: 'Real-time overview and analytics for ${controller.filterLabel.value}',
                actions: [
                  DateRangePickerWidget(
                    initialFrom: controller.fromDate,
                    initialTo: controller.toDate,
                    onRangeChanged: controller.updateDateRange,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    tooltip: 'Refresh Analytics',
                    onPressed: controller.refreshData,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 20),

              // 2. Quick Actions Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Quick Actions:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                    ),
                    CustomButton(
                      text: 'New Job Card',
                      icon: Icons.build_circle_outlined,
                      height: 34,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const JobCreateDialog(),
                      ),
                    ),
                    CustomButton(
                      text: 'Add Customer',
                      icon: Icons.person_add_alt_1_rounded,
                      type: ButtonType.secondary,
                      height: 34,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const CustomerFormDialog(),
                      ),
                    ),
                    CustomButton(
                      text: 'Add Vehicle',
                      icon: Icons.directions_car_filled_outlined,
                      type: ButtonType.secondary,
                      height: 34,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const VehicleFormDialog(),
                      ),
                    ),
                    CustomButton(
                      text: 'Create Invoice',
                      icon: Icons.receipt_long_rounded,
                      type: ButtonType.secondary,
                      height: 34,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const InvoiceCreateDialog(),
                      ),
                    ),
                    CustomButton(
                      text: 'Add Expense',
                      icon: Icons.shopping_bag_outlined,
                      type: ButtonType.secondary,
                      height: 34,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const GarageExpenseFormDialog(),
                      ),
                    ),
                    CustomButton(
                      text: 'View Invoices',
                      icon: Icons.payments_rounded,
                      type: ButtonType.secondary,
                      height: 34,
                      onPressed: () => Get.toNamed(AppRoutes.invoices),
                    ),
                    CustomButton(
                      text: 'Inventory Stock',
                      icon: Icons.inventory_2_outlined,
                      type: ButtonType.secondary,
                      height: 34,
                      onPressed: () => Get.toNamed(AppRoutes.inventory),
                    ),
                    CustomButton(
                      text: 'Staff Attendance',
                      icon: Icons.badge_outlined,
                      type: ButtonType.outline,
                      height: 34,
                      onPressed: () => Get.toNamed(AppRoutes.staff),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // 3. 12 Summary KPI Cards Grid with Dynamic Responsive Column Calculation
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final double cardWidth = ResponsiveLayout.calculateCardWidth(
                    availableWidth: constraints.maxWidth,
                    minCardWidth: isNarrow ? 140 : 210,
                    spacing: isNarrow ? 10 : 16,
                    maxColumns: 4,
                  );

                  return Wrap(
                    spacing: isNarrow ? 10 : 16,
                    runSpacing: isNarrow ? 10 : 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Total Customers',
                          value: '${m.totalCustomers}',
                          subtitle: 'Active client accounts',
                          icon: Icons.people_alt_rounded,
                          iconColor: AppColors.primary,
                          onTap: () => Get.toNamed(AppRoutes.customers),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Total Vehicles',
                          value: '${m.totalVehicles}',
                          subtitle: 'Registered garage fleet',
                          icon: Icons.directions_car_rounded,
                          iconColor: AppColors.accent,
                          onTap: () => Get.toNamed(AppRoutes.vehicles),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Active Bay Jobs',
                          value: '${m.inProgressJobs}',
                          subtitle: '${m.todaysJobs} booked today',
                          icon: Icons.build_rounded,
                          iconColor: AppColors.warning,
                          onTap: () => Get.toNamed(AppRoutes.jobs),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Ready for Delivery',
                          value: '${m.readyForDeliveryJobs}',
                          subtitle: '${m.completedJobs} completed total',
                          icon: Icons.car_rental_rounded,
                          iconColor: m.readyForDeliveryJobs > 0 ? AppColors.success : AppColors.primary,
                          onTap: () => Get.toNamed(AppRoutes.jobs),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Period Revenue',
                          value: Formatters.compactCurrency(m.totalIncome, symbol: currency),
                          subtitle: 'Invoiced service revenue',
                          icon: Icons.payments_rounded,
                          iconColor: AppColors.primary,
                          onTap: () => Get.toNamed(AppRoutes.invoices),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Garage Expenses',
                          value: Formatters.compactCurrency(m.totalExpenses, symbol: currency),
                          subtitle: 'Supplies, rent & upkeep',
                          icon: Icons.shopping_bag_outlined,
                          iconColor: AppColors.error,
                          onTap: () => Get.toNamed(AppRoutes.expenses),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Net Income',
                          value: Formatters.compactCurrency(m.netIncome, symbol: currency),
                          subtitle: 'Revenue - Expenses',
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: m.netIncome >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Receivables Due',
                          value: Formatters.compactCurrency(m.outstandingPayments, symbol: currency),
                          subtitle: 'Pending invoice dues',
                          icon: Icons.pending_actions_rounded,
                          iconColor: m.outstandingPayments > 0 ? AppColors.error : AppColors.success,
                          onTap: () => Get.toNamed(AppRoutes.payments),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Low / Out of Stock',
                          value: '${m.lowStockItems + m.outOfStockItems}',
                          subtitle: '${m.totalStockItems} total inventory SKUs',
                          icon: Icons.warning_amber_rounded,
                          iconColor: (m.lowStockItems + m.outOfStockItems > 0) ? AppColors.warning : AppColors.success,
                          onTap: () => Get.toNamed(AppRoutes.inventory),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Staff on Duty',
                          value: '${m.presentToday} / ${m.totalStaff}',
                          subtitle: '${m.absentToday} absent today',
                          icon: Icons.badge_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          onTap: () => Get.toNamed(AppRoutes.staff),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Stock Inventory Value',
                          value: Formatters.compactCurrency(m.stockPurchaseValue, symbol: currency),
                          subtitle: 'Warehouse asset inventory',
                          icon: Icons.inventory_2_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          onTap: () => Get.toNamed(AppRoutes.inventory),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: SummaryCard(
                          title: 'Pending Payroll',
                          value: Formatters.compactCurrency(m.pendingSalaries, symbol: currency),
                          subtitle: 'Unpaid staff wage balances',
                          icon: Icons.account_balance_rounded,
                          iconColor: m.pendingSalaries > 0 ? AppColors.warning : AppColors.success,
                          onTap: () => Get.toNamed(AppRoutes.staff),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 4. Visual Progress / Gauges with Responsive Stacking
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 800;

                  // Bay capacity calculation: assume 8 active garage bays
                  const totalBayCapacity = 8;
                  final bayUtilPct = ((m.inProgressJobs / totalBayCapacity) * 100).clamp(0.0, 100.0);
                  final bayUtilRatio = (m.inProgressJobs / totalBayCapacity).clamp(0.0, 1.0);

                  final totalBilled = m.totalIncome + m.outstandingPayments;
                  final recoveryRatio = totalBilled > 0 ? (m.totalIncome / totalBilled).clamp(0.0, 1.0) : 1.0;
                  final recoveryPct = recoveryRatio * 100;

                  final bayWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Workshop Bay Capacity & Floor Utilization',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${bayUtilPct.toStringAsFixed(1)}% (${m.inProgressJobs}/$totalBayCapacity Bays)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: bayUtilRatio,
                          minHeight: 10,
                          backgroundColor: isDark ? AppColors.darkCardElevated : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                    ],
                  );

                  final efficiencyWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Invoice Collection & Recovery Efficiency',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${recoveryPct.toStringAsFixed(1)}% (${Formatters.compactCurrency(m.totalIncome, symbol: currency)})',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: recoveryRatio,
                          minHeight: 10,
                          backgroundColor: isDark ? AppColors.darkCardElevated : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                        ),
                      ),
                    ],
                  );

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: isNarrow
                        ? Column(
                            children: [
                              bayWidget,
                              const SizedBox(height: 20),
                              efficiencyWidget,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: bayWidget),
                              const SizedBox(width: 32),
                              Expanded(child: efficiencyWidget),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 5. Income vs Expenses Financial Breakdown Chart
              Container(
                height: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income vs Expenses Trend',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.filterLabel.value} • Financial Breakdown',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    Divider(
                      height: 20,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    Expanded(
                      child: DashboardIncomeExpenseChart(
                        data: controller.dailyIncomeVsExpense,
                        currency: currency,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Drilldown Operational Breakdown Cards
              _buildOperationalBreakdownRow(context, controller, currency, isDark),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOperationalBreakdownRow(
    BuildContext context,
    DashboardController controller,
    String currency,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 980;

        final jobsBreakdownCard = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Jobs Status Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.jobs),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('View All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              Divider(
                height: 16,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Obx(() {
                final jobs = controller.jobsByStatus;
                if (jobs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No active job cards found for this period', style: TextStyle(fontSize: 12)),
                    ),
                  );
                }

                int total = 0;
                for (final j in jobs) {
                  total += (j['count'] as num?)?.toInt() ?? 0;
                }
                if (total == 0) total = 1;

                return Column(
                  children: jobs.map((item) {
                    final status = (item['status'] as String?) ?? 'Unknown';
                    final count = (item['count'] as num?)?.toInt() ?? 0;
                    final pct = ((count / total) * 100).toStringAsFixed(1);
                    final color = AppColors.getJobStatusColor(status);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$count ($pct%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (count / total).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkCardElevated : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        );

        final debtorsCard = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Outstanding Receivables',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.invoices),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Invoices', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              Divider(
                height: 16,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Obx(() {
                final debtors = controller.topDebtors;
                if (debtors.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'All customer invoices are fully settled!',
                        style: TextStyle(fontSize: 12, color: AppColors.success),
                      ),
                    ),
                  );
                }

                return Column(
                  children: debtors.take(4).map((debtor) {
                    final name = (debtor['name'] as String?) ?? 'Customer';
                    final phone = (debtor['phone'] as String?) ?? '';
                    final balance = (debtor['balance'] as num?)?.toDouble() ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            Formatters.compactCurrency(balance, symbol: currency),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        );

        if (isSingleColumn) {
          return Column(
            children: [
              jobsBreakdownCard,
              const SizedBox(height: 20),
              debtorsCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: jobsBreakdownCard),
            const SizedBox(width: 20),
            Expanded(child: debtorsCard),
          ],
        );
      },
    );
  }
}
