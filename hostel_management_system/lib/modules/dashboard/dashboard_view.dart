import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/date_range_picker_widget.dart';
import '../../widgets/custom_button.dart';
import '../layout/main_layout_controller.dart';
import 'dashboard_controller.dart';
import 'widgets/rent_collection_chart.dart';
import 'widgets/income_expense_chart.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.metrics.value == null) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final m = controller.metrics.value;
      final layout = Get.find<MainLayoutController>();

      return Padding(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Responsive Title & Date Filter
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
            SizedBox(height: Responsive.isMobile(context) ? 12 : 20),

            // Quick Actions Bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 10 : 16,
                vertical: Responsive.isMobile(context) ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Quick Actions:', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                  CustomButton(
                    text: 'New Admission',
                    icon: Icons.how_to_reg_rounded,
                    height: 34,
                    onPressed: () => layout.setNavIndex(3),
                  ),
                  CustomButton(
                    text: 'Add Student',
                    icon: Icons.person_add_alt_1_rounded,
                    type: ButtonType.secondary,
                    height: 34,
                    onPressed: () => layout.setNavIndex(1),
                  ),
                  CustomButton(
                    text: 'Add Room',
                    icon: Icons.meeting_room_rounded,
                    type: ButtonType.secondary,
                    height: 34,
                    onPressed: () => layout.setNavIndex(2),
                  ),
                  CustomButton(
                    text: 'Record Rent',
                    icon: Icons.payments_rounded,
                    type: ButtonType.secondary,
                    height: 34,
                    onPressed: () => layout.setNavIndex(4),
                  ),
                  CustomButton(
                    text: 'View Receipts',
                    icon: Icons.receipt_long_rounded,
                    type: ButtonType.secondary,
                    height: 34,
                    onPressed: () => layout.setNavIndex(5),
                  ),
                  CustomButton(
                    text: 'Add Expense',
                    icon: Icons.receipt_rounded,
                    type: ButtonType.secondary,
                    height: 34,
                    onPressed: () => layout.setNavIndex(6),
                  ),
                  CustomButton(
                    text: 'View History',
                    icon: Icons.history_rounded,
                    type: ButtonType.outline,
                    height: 34,
                    onPressed: () => layout.setNavIndex(7),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.isMobile(context) ? 16 : 24),

            // 12 Summary KPI Cards Grid with Dynamic Responsive Column Calculation
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 650;
              final double cardWidth = Responsive.calculateCardWidth(
                availableWidth: constraints.maxWidth,
                minCardWidth: isMobile ? 140 : 220,
                spacing: isMobile ? 10 : 16,
                maxColumns: 4,
              );

              return Wrap(
                spacing: isMobile ? 10 : 16,
                runSpacing: isMobile ? 10 : 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Total Students',
                      value: '${m?.totalStudents ?? 0}',
                      subtitle: '${m?.activeStudents ?? 0} currently active',
                      icon: Icons.people_alt_rounded,
                      iconColor: AppColors.primary,
                      onTap: () => layout.setNavIndex(1),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Total Rooms',
                      value: '${m?.totalRooms ?? 0}',
                      subtitle: '${m?.totalBeds ?? 0} total bed capacity',
                      icon: Icons.meeting_room_rounded,
                      iconColor: AppColors.sidebarActive,
                      onTap: () => layout.setNavIndex(2),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Occupied Beds',
                      value: '${m?.occupiedBeds ?? 0}',
                      subtitle: '${m?.occupancyRate.toStringAsFixed(1) ?? "0"}% occupancy rate',
                      icon: Icons.single_bed_rounded,
                      iconColor: AppColors.accent,
                      onTap: () => layout.setNavIndex(2),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Available Beds',
                      value: '${m?.availableBeds ?? 0}',
                      subtitle: 'Ready for immediate booking',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: (m?.availableBeds ?? 0) > 0 ? AppColors.success : AppColors.danger,
                      onTap: () => layout.setNavIndex(2),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Expected Rent',
                      value: CurrencyFormatter.format(m?.expectedRent),
                      subtitle: 'Current billing period',
                      icon: Icons.calculate_outlined,
                      iconColor: AppColors.primary,
                      onTap: () => layout.setNavIndex(4),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Rent Collected',
                      value: CurrencyFormatter.format(m?.rentCollected),
                      subtitle: '${m?.collectionRate.toStringAsFixed(1) ?? "0"}% collection rate',
                      icon: Icons.payments_rounded,
                      iconColor: AppColors.success,
                      onTap: () => layout.setNavIndex(5),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Pending Rent Dues',
                      value: CurrencyFormatter.format(m?.pendingRent),
                      subtitle: 'Unpaid remaining balance',
                      icon: Icons.pending_actions_rounded,
                      iconColor: (m?.pendingRent ?? 0) > 0 ? AppColors.danger : AppColors.success,
                      onTap: () => layout.setNavIndex(4),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Total Expenses',
                      value: CurrencyFormatter.format(m?.totalExpenses),
                      subtitle: 'Bills, staff & operations',
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.warning,
                      onTap: () => layout.setNavIndex(6),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Net Income',
                      value: CurrencyFormatter.format(m?.netIncome),
                      subtitle: 'Rent Collected - Expenses',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: (m?.netIncome ?? 0) >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Collection Rate',
                      value: '${m?.collectionRate.toStringAsFixed(1) ?? "0"}%',
                      subtitle: 'Rent recovery ratio',
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.primaryLight,
                      onTap: () => layout.setNavIndex(4),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SummaryCard(
                      title: 'Audit & History',
                      value: 'Complete Logs',
                      subtitle: 'Full audit trail preserved',
                      icon: Icons.manage_history_rounded,
                      iconColor: AppColors.sidebarActive,
                      onTap: () => layout.setNavIndex(7),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Visual Progress / Gauges with Responsive Stacking
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;

                final occupancyWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Hostel Occupancy Capacity', style: AppStyles.h4, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(m?.occupancyRate ?? 0).toStringAsFixed(1)}% (${m?.occupiedBeds ?? 0}/${m?.totalBeds ?? 0} Beds)',
                          style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (m?.totalBeds ?? 0) > 0 ? (m!.occupiedBeds / m.totalBeds) : 0,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ],
                );

                final rentEfficiencyWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Monthly Rent Collection Efficiency', style: AppStyles.h4, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(m?.collectionRate ?? 0).toStringAsFixed(1)}%',
                          style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (m?.expectedRent ?? 0) > 0 ? (m!.rentCollected / m.expectedRent).clamp(0.0, 1.0) : 0,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      ),
                    ),
                  ],
                );

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppStyles.cardDecoration,
                  child: isNarrow
                      ? Column(
                          children: [
                            occupancyWidget,
                            const SizedBox(height: 20),
                            rentEfficiencyWidget,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: occupancyWidget),
                            const SizedBox(width: 32),
                            Expanded(child: rentEfficiencyWidget),
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Analytics Charts Row with Responsive Stacking
            LayoutBuilder(
              builder: (context, constraints) {
                final isSingleColumn = constraints.maxWidth < 980;

                final chart1 = Container(
                  height: 380,
                  padding: const EdgeInsets.all(20),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rent Collection Analytics', style: AppStyles.h3, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${controller.filterLabel.value} • Collected vs Expected', style: AppStyles.caption, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              controller.isLineChart.value ? Icons.bar_chart_rounded : Icons.show_chart_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Switch Chart Type (Line/Bar)',
                            onPressed: controller.toggleChartType,
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Expanded(
                        child: RentCollectionChart(
                          data: controller.rentChartData,
                          isLine: controller.isLineChart.value,
                        ),
                      ),
                    ],
                  ),
                );

                final chart2 = Container(
                  height: 380,
                  padding: const EdgeInsets.all(20),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Income vs Expenses Trend', style: AppStyles.h3),
                      const SizedBox(height: 2),
                      Text('${controller.filterLabel.value} • Financial Breakdown', style: AppStyles.caption),
                      const Divider(height: 20),
                      Expanded(
                        child: IncomeExpenseChart(
                          data: controller.incomeExpenseChartData,
                        ),
                      ),
                    ],
                  ),
                );

                if (isSingleColumn) {
                  return Column(
                    children: [
                      chart1,
                      const SizedBox(height: 20),
                      chart2,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: chart1),
                    const SizedBox(width: 20),
                    Expanded(child: chart2),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
