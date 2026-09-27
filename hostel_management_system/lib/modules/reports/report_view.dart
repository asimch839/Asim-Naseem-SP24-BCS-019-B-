import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/date_range_picker_widget.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/data_table_widget.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/repositories/settings_repository.dart';
import 'report_controller.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            ResponsiveHeader(
              title: 'Executive Reports',
              subtitle: 'Generate comprehensive operational, financial, room occupancy, and student reports',
              actions: [
                DateRangePickerWidget(
                  initialFrom: controller.fromDate,
                  initialTo: controller.toDate,
                  onRangeChanged: controller.updateDateRange,
                ),
                CustomButton(
                  text: 'Export Report to Excel',
                  icon: Icons.table_view_rounded,
                  onPressed: controller.exportActiveReportToExcel,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Navigation with Horizontal Scroll Safety
            Obx(() => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(0, 'Student Reports', Icons.people_outline),
                    const SizedBox(width: 4),
                    _buildTabButton(1, 'Room & Bed Inventory', Icons.meeting_room_outlined),
                    const SizedBox(width: 4),
                    _buildTabButton(2, 'Rent & Billing Summary', Icons.payments_outlined),
                    const SizedBox(width: 4),
                    _buildTabButton(3, 'Expense Breakdown', Icons.shopping_bag_outlined),
                    const SizedBox(width: 4),
                    _buildTabButton(4, 'Financial P&L Statement', Icons.account_balance_wallet_outlined),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 20),

            // Tab Body
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              switch (controller.selectedTab.value) {
                case 0:
                  return _buildStudentsReport();
                case 1:
                  return _buildRoomsReport();
                case 2:
                  return _buildRentReport();
                case 3:
                  return _buildExpenseReport();
                case 4:
                  return _buildFinancialReport();
                default:
                  return const SizedBox.shrink();
              }
            }),
          ],
        ),
      );
    }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = controller.selectedTab.value == index;
    return InkWell(
      onTap: () => controller.selectedTab.value = index,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsReport() {
    final list = controller.students;
    final rows = list.map((s) {
      return [
        Text(s.studentIdCode, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        Text(s.fullName, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        Text(s.phone, style: AppStyles.bodySmall),
        Text(s.roomNumber != null ? 'Room ${s.roomNumber}' : '-', style: AppStyles.bodySmall),
        Text(s.bedNumber ?? '-', style: AppStyles.bodySmall),
        Text(CurrencyFormatter.format(s.monthlyRent), style: AppStyles.bodySmall),
        StatusBadge(status: s.status),
        Text(DateFormatter.formatDate(DateTime.tryParse(s.admissionDate)), style: AppStyles.caption),
      ];
    }).toList();

    return DataTableWidget(
      columns: const [
        TableColumnDef(title: 'Student ID'),
        TableColumnDef(title: 'Full Name'),
        TableColumnDef(title: 'Phone'),
        TableColumnDef(title: 'Room'),
        TableColumnDef(title: 'Bed'),
        TableColumnDef(title: 'Rent'),
        TableColumnDef(title: 'Status'),
        TableColumnDef(title: 'Admission Date'),
      ],
      rows: rows,
    );
  }

  Widget _buildRoomsReport() {
    final list = controller.rooms;
    final rows = list.map((r) {
      return [
        Text('Room ${r.roomNumber}', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        Text('${r.block} - ${r.floor}', style: AppStyles.bodySmall),
        Text(r.roomType, style: AppStyles.bodySmall),
        Text('${r.totalBeds}', style: AppStyles.bodySmall),
        Text('${r.occupiedBedsCount}', style: AppStyles.bodySmall.copyWith(color: AppColors.danger)),
        Text('${r.availableBedsCount}', style: AppStyles.bodySmall.copyWith(color: AppColors.success)),
        Text(CurrencyFormatter.format(r.monthlyRent), style: AppStyles.bodySmall),
        StatusBadge(status: r.roomStatus),
      ];
    }).toList();

    return DataTableWidget(
      columns: const [
        TableColumnDef(title: 'Room #'),
        TableColumnDef(title: 'Block/Floor'),
        TableColumnDef(title: 'Type'),
        TableColumnDef(title: 'Total Beds'),
        TableColumnDef(title: 'Occupied'),
        TableColumnDef(title: 'Available'),
        TableColumnDef(title: 'Monthly Rent'),
        TableColumnDef(title: 'Status'),
      ],
      rows: rows,
    );
  }

  Widget _buildRentReport() {
    final list = controller.rentRecords;
    final rows = list.map((r) {
      return [
        Text(r.studentIdCode ?? '-', style: AppStyles.bodySmall),
        Text(r.studentName ?? '-', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        Text(DateFormatter.formatMonthYearString(r.rentMonth), style: AppStyles.bodySmall),
        Text(CurrencyFormatter.format(r.rentAmount), style: AppStyles.bodySmall),
        Text(CurrencyFormatter.format(r.paidAmount), style: AppStyles.bodySmall.copyWith(color: AppColors.success)),
        Text(CurrencyFormatter.format(r.remainingAmount), style: AppStyles.bodySmall.copyWith(color: AppColors.danger)),
        StatusBadge(status: r.status),
        if (r.remainingAmount > 0)
          Tooltip(
            message: 'Send WhatsApp Rent Reminder',
            child: InkWell(
              onTap: () async {
                final settings = await SettingsRepository().getSettings();
                if (Get.context != null) {
                  WhatsAppService.showRentReminderDialog(
                    context: Get.context!,
                    rent: r,
                    settings: settings,
                  );
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.whatsappDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.whatsappDark.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_rounded, color: AppColors.whatsappDark, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Remind',
                      style: TextStyle(
                        color: AppColors.whatsappDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
      ];
    }).toList();

    return DataTableWidget(
      columns: const [
        TableColumnDef(title: 'Student ID'),
        TableColumnDef(title: 'Student Name'),
        TableColumnDef(title: 'Month'),
        TableColumnDef(title: 'Rent Amount'),
        TableColumnDef(title: 'Paid Amount'),
        TableColumnDef(title: 'Remaining'),
        TableColumnDef(title: 'Status'),
        TableColumnDef(title: 'Action', alignment: Alignment.center),
      ],
      rows: rows,
    );
  }

  Widget _buildExpenseReport() {
    final list = controller.expenses;
    final rows = list.map((e) {
      return [
        Text(DateFormatter.formatDate(DateTime.tryParse(e.expenseDate)), style: AppStyles.bodySmall),
        Text(e.title, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        Text(e.category, style: AppStyles.bodySmall),
        Text(e.paymentMethod, style: AppStyles.bodySmall),
        Text(CurrencyFormatter.format(e.amount), style: AppStyles.bodySmall.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
      ];
    }).toList();

    return DataTableWidget(
      columns: const [
        TableColumnDef(title: 'Date'),
        TableColumnDef(title: 'Expense Title'),
        TableColumnDef(title: 'Category'),
        TableColumnDef(title: 'Method'),
        TableColumnDef(title: 'Amount'),
      ],
      rows: rows,
    );
  }

  Widget _buildFinancialReport() {
    final m = controller.financialMetrics.value;

    return Center(
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(28),
        decoration: AppStyles.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Statement of Profit & Loss', style: AppStyles.h2),
                Text(controller.dateLabel.value, style: AppStyles.caption),
              ],
            ),
            const Divider(height: 28),
            _financialRow('Gross Rent Collected (Revenue)', CurrencyFormatter.format(m?.rentCollected), color: AppColors.success),
            const SizedBox(height: 12),
            _financialRow('Expected Rent Dues', CurrencyFormatter.format(m?.expectedRent)),
            const SizedBox(height: 12),
            _financialRow('Pending / Overdue Rent', CurrencyFormatter.format(m?.pendingRent), color: AppColors.warning),
            const SizedBox(height: 12),
            _financialRow('Total Operating Expenses (Outflow)', CurrencyFormatter.format(m?.totalExpenses), color: AppColors.danger),
            const Divider(height: 28),
            _financialRow(
              'NET OPERATING INCOME',
              CurrencyFormatter.format(m?.netIncome),
              isGrandTotal: true,
              color: (m?.netIncome ?? 0) >= 0 ? AppColors.success : AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _financialRow(String label, String value, {bool isGrandTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isGrandTotal ? AppStyles.h3 : AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: isGrandTotal
              ? AppStyles.h2.copyWith(color: color, fontWeight: FontWeight.w800)
              : AppStyles.bodyLarge.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
