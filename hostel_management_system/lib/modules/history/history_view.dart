import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/date_range_picker_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/responsive.dart';
import 'history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900 || constraints.maxHeight < 720;
          final isNarrow = constraints.maxWidth < 650;
          final isCardsNarrow = constraints.maxWidth < 800;

          // Header
          final header = Obx(() {
            if (controller.selectedTab.value == 0) {
              return ResponsiveHeader(
                title: 'Students Complete History & Ledgers',
                subtitle: 'Historical student profiles, room allocations, departures, and full rent payment ledgers',
                actions: [
                  CustomButton(
                    text: 'Refresh',
                    icon: Icons.refresh_rounded,
                    type: ButtonType.secondary,
                    isLoading: controller.isLoadingStudents.value,
                    onPressed: controller.fetchStudentsHistory,
                  ),
                ],
              );
            } else {
              return ResponsiveHeader(
                title: 'Complete History & Audit Trail',
                subtitle: 'Comprehensive historical operations, payments, admissions, room changes, and expenses',
                actions: [
                  DateRangePickerWidget(
                    initialFrom: controller.fromDate,
                    initialTo: controller.toDate,
                    onRangeChanged: controller.updateDateRange,
                  ),
                  CustomButton(
                    text: 'Export to Excel',
                    icon: Icons.table_view_rounded,
                    type: ButtonType.secondary,
                    onPressed: controller.exportToExcel,
                  ),
                ],
              );
            }
          });

          // Modern Tab Switcher
          final tabSwitcher = Obx(() => Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    index: 0,
                    label: 'Students History & Ledgers',
                    icon: Icons.school_rounded,
                    isSelected: controller.selectedTab.value == 0,
                  ),
                  const SizedBox(width: 4),
                  _buildTabButton(
                    index: 1,
                    label: 'System Activity Audit Trail',
                    icon: Icons.history_rounded,
                    isSelected: controller.selectedTab.value == 1,
                  ),
                ],
              ),
            ),
          ));

          return Padding(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 16),
                tabSwitcher,
                const SizedBox(height: 20),

                // Main Tab View
                Obx(() {
                  if (controller.selectedTab.value == 0) {
                    return _buildStudentsHistoryTab(context, constraints, isCardsNarrow, isNarrow, isCompact);
                  } else {
                    return _buildAuditLogsTab(context, constraints, isCardsNarrow, isNarrow, isCompact);
                  }
                }),
              ],
            ),
          );
        },
      );
    }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => controller.selectedTab.value = index,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: STUDENTS COMPLETE HISTORY
  // ==========================================
  Widget _buildStudentsHistoryTab(
    BuildContext context,
    BoxConstraints constraints,
    bool isCardsNarrow,
    bool isNarrow,
    bool isCompact,
  ) {
    // Summary Cards for Students History
    final summaryCards = Obx(() {
      final list = controller.students;
      final total = list.length;
      final active = list.where((s) => s.isActive).length;
      final left = list.where((s) => !s.isActive).length;
      final totalSecurity = list.fold<double>(0.0, (sum, s) => sum + s.securityDeposit);

      final cards = [
        SummaryCard(
          title: 'Total Students Recorded',
          value: '$total Students',
          subtitle: 'Active & Former students',
          icon: Icons.people_alt_rounded,
          iconColor: AppColors.primary,
        ),
        SummaryCard(
          title: 'Currently Active',
          value: '$active Students',
          subtitle: 'Residing in hostel',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
        ),
        SummaryCard(
          title: 'Former / Left Students',
          value: '$left Students',
          subtitle: 'Past hostel residents',
          icon: Icons.exit_to_app_rounded,
          iconColor: AppColors.warning,
        ),
        SummaryCard(
          title: 'Total Security Balance',
          value: CurrencyFormatter.format(totalSecurity),
          subtitle: 'Across all student records',
          icon: Icons.shield_rounded,
          iconColor: AppColors.accent,
        ),
      ];

      final double cardWidth = Responsive.calculateCardWidth(
        availableWidth: constraints.maxWidth,
        minCardWidth: Responsive.isMobile(context) ? 140 : 220,
        spacing: Responsive.isMobile(context) ? 10 : 16,
        maxColumns: 4,
      );

      return Wrap(
        spacing: Responsive.isMobile(context) ? 10 : 16,
        runSpacing: Responsive.isMobile(context) ? 10 : 16,
        children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
      );
    });

    // Search and Status Filters Bar
    final searchFilterBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: isNarrow
          ? Column(
              children: [
                TextField(
                  onChanged: (val) {
                    controller.studentSearchQuery.value = val;
                    controller.fetchStudentsHistory();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by student name, roll #, phone, room, CNIC...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Obx(() => DropdownButton<String>(
                    value: controller.studentStatusFilter.value,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Students (Active & Left)')),
                      DropdownMenuItem(value: 'Active', child: Text('Active Residents Only')),
                      DropdownMenuItem(value: 'Left', child: Text('Former / Left Students Only')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        controller.studentStatusFilter.value = v;
                        controller.fetchStudentsHistory();
                      }
                    },
                  )),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      controller.studentSearchQuery.value = val;
                      controller.fetchStudentsHistory();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by student name, roll #, phone, room, CNIC...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => DropdownButton<String>(
                  value: controller.studentStatusFilter.value,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Students (Active & Left)')),
                    DropdownMenuItem(value: 'Active', child: Text('Active Residents Only')),
                    DropdownMenuItem(value: 'Left', child: Text('Former / Left Students Only')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.studentStatusFilter.value = v;
                      controller.fetchStudentsHistory();
                    }
                  },
                )),
              ],
            ),
    );

    // Students Table
    final tableWidget = Obx(() {
      final list = controller.students;

      final List<List<Widget>> tableRows = list.map((s) {
        return [
          // Student Profile Cell
          InkWell(
            onTap: () => controller.openStudentHistoryModal(s),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: s.isActive
                      ? AppColors.primaryLight.withValues(alpha: 0.15)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: s.isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.fullName,
                      style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    Text(s.studentIdCode, style: AppStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          // Room / Bed
          Text(
            s.roomNumber != null ? 'Room ${s.roomNumber} (Bed ${s.bedNumber ?? "-"})' : '-',
            style: AppStyles.bodySmall,
          ),
          // Phone
          Text(s.phone, style: AppStyles.bodySmall),
          // Father Name
          Text(s.fatherName, style: AppStyles.bodySmall),
          // Admission Date
          Text(DateFormatter.formatDate(DateTime.tryParse(s.admissionDate)), style: AppStyles.caption),
          // Status Badge
          StatusBadge(status: s.status),
          // Security Deposit
          Text(
            CurrencyFormatter.format(s.securityDeposit),
            style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent),
          ),
          // Action Button
          CustomButton(
            text: 'View History',
            icon: Icons.history_edu_rounded,
            type: ButtonType.secondary,
            height: 32,
            onPressed: () => controller.openStudentHistoryModal(s),
          ),
        ];
      }).toList();

      return DataTableWidget(
        isLoading: controller.isLoadingStudents.value,
        columns: const [
          TableColumnDef(title: 'Student Profile'),
          TableColumnDef(title: 'Room & Bed'),
          TableColumnDef(title: 'Phone'),
          TableColumnDef(title: 'Father Name'),
          TableColumnDef(title: 'Admission Date'),
          TableColumnDef(title: 'Status'),
          TableColumnDef(title: 'Security Deposit'),
          TableColumnDef(title: 'Action', alignment: Alignment.center),
        ],
        rows: tableRows,
        emptyTitle: 'No Students Found',
        emptySubtitle: 'No student historical records match your search or filter criteria.',
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summaryCards,
        const SizedBox(height: 16),
        searchFilterBar,
        const SizedBox(height: 16),
        tableWidget,
      ],
    );
  }

  // ==========================================
  // TAB 1: SYSTEM ACTIVITY AUDIT LOGS
  // ==========================================
  Widget _buildAuditLogsTab(
    BuildContext context,
    BoxConstraints constraints,
    bool isCardsNarrow,
    bool isNarrow,
    bool isCompact,
  ) {
    // Summary Cards
    final cardsWidget = Obx(() {
      final s = controller.summary.value;
      final cards = [
        SummaryCard(
          title: 'Total Rent Collected',
          value: CurrencyFormatter.format(s?.totalRentCollected),
          subtitle: '${s?.totalPaymentsCount ?? 0} transactions',
          icon: Icons.payments_rounded,
          iconColor: AppColors.success,
        ),
        SummaryCard(
          title: 'Total Pending Rent',
          value: CurrencyFormatter.format(s?.totalPendingRent),
          subtitle: '${s?.partialPaymentsCount ?? 0} partial payments',
          icon: Icons.pending_actions_rounded,
          iconColor: AppColors.danger,
        ),
        SummaryCard(
          title: 'Total Expenses',
          value: CurrencyFormatter.format(s?.totalExpenses),
          subtitle: 'In selected period',
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.warning,
        ),
        SummaryCard(
          title: 'Net Operational Income',
          value: CurrencyFormatter.format(s?.netIncome),
          subtitle: '${s?.totalAdmissionsCount ?? 0} admitted, ${s?.studentsLeftCount ?? 0} left',
          icon: Icons.account_balance_rounded,
          iconColor: (s?.netIncome ?? 0) >= 0 ? AppColors.success : AppColors.danger,
        ),
      ];

      final double cardWidth = Responsive.calculateCardWidth(
        availableWidth: constraints.maxWidth,
        minCardWidth: Responsive.isMobile(context) ? 140 : 220,
        spacing: Responsive.isMobile(context) ? 10 : 16,
        maxColumns: 4,
      );

      return Wrap(
        spacing: Responsive.isMobile(context) ? 10 : 16,
        runSpacing: Responsive.isMobile(context) ? 10 : 16,
        children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
      );
    });

    // Search & Filters Bar
    final searchInput = TextField(
      onChanged: (val) {
        controller.searchQuery.value = val;
        controller.fetchHistoryLogs();
      },
      decoration: InputDecoration(
        hintText: 'Search audit logs by keyword, student, operator, or description...',
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final activityDropdown = Obx(() => DropdownButton<String>(
      value: controller.activityTypeFilter.value,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Activity Types')),
        DropdownMenuItem(value: 'Payment', child: Text('Payments')),
        DropdownMenuItem(value: 'Admission', child: Text('Admissions')),
        DropdownMenuItem(value: 'Room Change', child: Text('Room Transfers')),
        DropdownMenuItem(value: 'Student Left', child: Text('Departures')),
        DropdownMenuItem(value: 'Expense Added', child: Text('Expenses')),
        DropdownMenuItem(value: 'Room Added', child: Text('Rooms')),
        DropdownMenuItem(value: 'User Login', child: Text('Logins')),
      ],
      onChanged: (v) {
        if (v != null) {
          controller.activityTypeFilter.value = v;
          controller.fetchHistoryLogs();
        }
      },
    ));

    final searchFilterBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: isNarrow
          ? Column(
              children: [
                searchInput,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: activityDropdown),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchInput),
                const SizedBox(width: 16),
                activityDropdown,
              ],
            ),
    );

    // History Table
    final tableWidget = Obx(() {
      final list = controller.logs;

      final List<List<Widget>> tableRows = list.map((log) {
        return [
          Text(DateFormatter.formatDate(DateTime.tryParse(log.createdAt)), style: AppStyles.bodySmall),
          Text(DateFormatter.formatTime(DateTime.tryParse(log.createdAt)), style: AppStyles.caption),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(log.activityType, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(log.studentName ?? '-', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              if (log.studentIdCode != null) Text(log.studentIdCode!, style: AppStyles.caption),
            ],
          ),
          Text(log.roomNumber != null ? 'Room ${log.roomNumber}' : '-', style: AppStyles.bodySmall),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text(
              log.description,
              style: AppStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(log.username, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
            tooltip: 'View Details',
            onPressed: () => controller.inspectLogDetails(log),
          ),
        ];
      }).toList();

      return DataTableWidget(
        isLoading: controller.isLoading.value,
        columns: const [
          TableColumnDef(title: 'Date'),
          TableColumnDef(title: 'Time'),
          TableColumnDef(title: 'Activity Type'),
          TableColumnDef(title: 'Student'),
          TableColumnDef(title: 'Room'),
          TableColumnDef(title: 'Description'),
          TableColumnDef(title: 'Operator'),
          TableColumnDef(title: 'Details', alignment: Alignment.center),
        ],
        rows: tableRows,
        emptyTitle: 'No Historical Records Found',
        emptySubtitle: 'No activity logs or financial records match the selected date range and filter criteria.',
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cardsWidget,
        const SizedBox(height: 16),
        searchFilterBar,
        const SizedBox(height: 16),
        tableWidget,
      ],
    );
  }
}
