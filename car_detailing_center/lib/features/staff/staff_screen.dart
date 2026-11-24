import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/salary_model.dart';
import '../../data/repositories/staff_repository.dart';
import 'staff_form_dialog.dart';

class StaffScreen extends StatefulWidget {
  final int initialTabIndex;
  const StaffScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex.clamp(0, 4);
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentSubItem {
    switch (_currentTabIndex) {
      case 0:
        return 'Staff List';
      case 1:
        return 'Commission Staff';
      case 2:
        return 'Attendance';
      case 3:
        return 'Salaries';
      case 4:
        return 'Staff Expenses';
      default:
        return 'Staff List';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.staff,
      currentSubItem: _currentSubItem,
      onSubItemSelect: (sub) {
        if (sub.tabIndex >= 0 && sub.tabIndex < 5) {
          _tabController.animateTo(sub.tabIndex);
        }
      },
      title: 'Staff Management System',
      body: Column(
        children: [
          // Sub-navigation Tabs (Staff List, Commission Staff, Attendance, Salaries, Staff Expenses)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: AppColors.borderDark)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withValues(alpha: 0.25),
                border: Border.all(color: AppColors.primaryLight, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelColor: AppColors.textDarkSecondary,
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'Staff List'),
                Tab(icon: Icon(Icons.handshake_rounded, size: 20), text: 'Commission Staff'),
                Tab(icon: Icon(Icons.event_available_rounded, size: 20), text: 'Attendance'),
                Tab(icon: Icon(Icons.payments_rounded, size: 20), text: 'Salaries'),
                Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: 'Staff Expenses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                StaffListSubView(),
                CommissionStaffSubView(),
                StaffAttendanceSubView(),
                StaffSalariesSubView(),
                StaffExpensesSubView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. STAFF LIST SUB-VIEW
// -------------------------------------------------------------
class StaffListSubView extends StatefulWidget {
  const StaffListSubView({super.key});

  @override
  State<StaffListSubView> createState() => _StaffListSubViewState();
}

class _StaffListSubViewState extends State<StaffListSubView> {
  final TextEditingController _searchController = TextEditingController();
  final _staffRepo = StaffRepository();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    final isCompact = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final searchField = TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search staff by name, role, phone...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              );
              final addButton = ElevatedButton.icon(
                onPressed: () async {
                  final res = await showDialog<bool>(
                    context: context,
                    builder: (_) => const StaffFormDialog(isCommissionBased: false),
                  );
                  if (res == true && mounted) setState(() {});
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Salaried Staff'),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: addButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 14),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<StaffModel>>(
              future: _staffRepo.getStaffList(searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(message: 'Loading staff directory...');
                }

                final allStaff = snapshot.data ?? [];
                final filtered = allStaff.where((s) => s.salaryType != AppConstants.salaryTypeCommission).toList();

                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.badge_rounded,
                    title: 'No Salaried Staff Registered',
                    description: 'Add technicians, detailers, and shop managers with fixed monthly/daily salaries.',
                  );
                }

                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final staff = filtered[index];
return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: staff.photoUrl != null && File(staff.photoUrl!).existsSync()
                              ? FileImage(File(staff.photoUrl!))
                              : null,
                          child: (staff.photoUrl == null || !File(staff.photoUrl!).existsSync())
                              ? Text(staff.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight))
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: staff.status == 'Active' ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                staff.status,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: staff.status == 'Active' ? AppColors.success : AppColors.error),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${staff.designation} • Phone: ${staff.phone} ${staff.cnic != null && staff.cnic!.isNotEmpty ? "• CNIC: ${staff.cnic}" : ""} • ${staff.salaryType == AppConstants.salaryTypeDaily ? "Daily Rate: " : staff.salaryType == AppConstants.salaryTypeWeekly ? "Weekly Rate: " : "Salary: "}${Formatters.currency(staff.basicSalary, symbol: currency)} (${staff.salaryType})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Profile',
                              onPressed: () async {
                                final res = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => StaffFormDialog(staff: staff),
                                );
                                if (res == true && mounted) setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Delete Staff Record'),
                                    content: Text('Are you sure you want to remove ${staff.name}?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                        onPressed: () => Get.back(result: true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _staffRepo.deleteStaff(staff.id);
                                  Get.snackbar('Removed', 'Staff member deleted');
                                  if (mounted) setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1.5. COMMISSION STAFF SUB-VIEW (Pure % Commission, 0 Basic Salary)
// -------------------------------------------------------------
class CommissionStaffSubView extends StatefulWidget {
  const CommissionStaffSubView({super.key});

  @override
  State<CommissionStaffSubView> createState() => _CommissionStaffSubViewState();
}

class _CommissionStaffSubViewState extends State<CommissionStaffSubView> {
  final TextEditingController _searchController = TextEditingController();
  final _staffRepo = StaffRepository();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          // Search & Add Button Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final searchField = TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search commission workers (denter, painter, phone)...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              );
              final addButton = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final res = await showDialog<bool>(
                    context: context,
                    builder: (_) => const StaffFormDialog(isCommissionBased: true),
                  );
                  if (res == true && mounted) setState(() {});
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Commission Worker'),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: addButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 14),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // List of Commission Workers
          Expanded(
            child: FutureBuilder<List<StaffModel>>(
              future: _staffRepo.getStaffList(searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(message: 'Loading commission staff directory...');
                }

                final all = snapshot.data ?? [];
                final commissionWorkers = all.where((s) => s.salaryType == AppConstants.salaryTypeCommission).toList();

                if (commissionWorkers.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.handshake_rounded,
                    title: 'No Commission Workers Registered',
                    description: 'Click "+ Add Commission Worker" to add denters, painters, or contractors working on percentage commission split (e.g. 70% worker / 30% garage).',
                  );
                }

                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: commissionWorkers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final staff = commissionWorkers[index];
                      final commRate = staff.commissionRate;
                      final garageShare = (100 - commRate).clamp(0, 100).toDouble();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.success.withValues(alpha: 0.15),
                          backgroundImage: staff.photoUrl != null && File(staff.photoUrl!).existsSync()
                              ? FileImage(File(staff.photoUrl!))
                              : null,
                          child: (staff.photoUrl == null || !File(staff.photoUrl!).existsSync())
                              ? Text(staff.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                staff.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: staff.status == 'Active' ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                staff.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: staff.status == 'Active' ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${staff.designation} • ${staff.phone}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.percent_rounded, size: 13, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Worker: ${commRate.toStringAsFixed(0)}%  |  Garage: ${garageShare.toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'No Basic Salary',
                                    style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Commission Worker',
                              onPressed: () async {
                                final res = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => StaffFormDialog(staff: staff, isCommissionBased: true),
                                );
                                if (res == true && mounted) setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              tooltip: 'Delete Profile',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Worker Profile'),
                                    content: Text('Are you sure you want to remove ${staff.name} from commission workers?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _staffRepo.deleteStaff(staff.id);
                                  if (mounted) setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. STAFF ATTENDANCE SUB-VIEW
// -------------------------------------------------------------
class StaffAttendanceSubView extends StatefulWidget {
  const StaffAttendanceSubView({super.key});

  @override
  State<StaffAttendanceSubView> createState() => _StaffAttendanceSubViewState();
}

class _StaffAttendanceSubViewState extends State<StaffAttendanceSubView> {
  final _staffRepo = StaffRepository();
  DateTime _selectedDate = DateTime.now();

  void _mark(String staffId, String status) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      await _staffRepo.recordAttendance(
        staffId: staffId,
        dateStr: dateStr,
        status: status,
        checkInTime: status == AppConstants.attendancePresent ? DateFormat('HH:mm').format(DateTime.now()) : null,
      );
      if (mounted) setState(() {});
    } catch (e) {
      Get.snackbar('Error', 'Failed to mark attendance: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final isCompact = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          // Date Selector Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 620;

                  final dateControls = Row(
                    mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: isCompact ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                      ),
                      Flexible(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (d != null) setState(() => _selectedDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    DateFormat(isCompact ? 'dd MMM yyyy' : 'EEEE, dd MMMM yyyy').format(_selectedDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                      ),
                    ],
                  );

                  final statsBadges = FutureBuilder<List<Map<String, dynamic>>>(
                    future: _staffRepo.getDailyAttendance(dateStr),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];
                      final present = list.where((a) => a['attendance_status'] == AppConstants.attendancePresent).length;
                      final absent = list.where((a) => a['attendance_status'] == AppConstants.attendanceAbsent).length;
                      final leave = list.where((a) => a['attendance_status'] == AppConstants.attendanceLeave).length;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _badge('Present: $present', AppColors.success),
                          _badge('Absent: $absent', AppColors.error),
                          _badge('Leave: $leave', AppColors.warning),
                        ],
                      );
                    },
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dateControls,
                        const SizedBox(height: 10),
                        Center(child: statsBadges),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      dateControls,
                      const Spacer(),
                      statsBadges,
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Attendance Register Table
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _staffRepo.getDailyAttendance(dateStr),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(message: 'Loading attendance records...');
                }

                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'No Active Staff Members',
                    description: 'Add active staff members first to mark their attendance.',
                  );
                }

                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = list[index];
                      final staffId = row['staff_id'] as String;
                      final staffName = row['staff_name'] as String;
                      final designation = row['designation'] as String? ?? '';
                      final salaryType = row['salary_type'] as String? ?? 'Monthly';
                      final currentStatus = row['attendance_status'] as String?;

                      if (isCompact) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text('$designation • $salaryType', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _statusBtn(staffId, AppConstants.attendancePresent, 'Present', AppColors.success, currentStatus),
                                    const SizedBox(width: 6),
                                    _statusBtn(staffId, AppConstants.attendanceAbsent, 'Absent', AppColors.error, currentStatus),
                                    const SizedBox(width: 6),
                                    _statusBtn(staffId, AppConstants.attendanceHalfDay, 'Half Day', AppColors.info, currentStatus),
                                    const SizedBox(width: 6),
                                    _statusBtn(staffId, AppConstants.attendanceLeave, 'Leave', AppColors.warning, currentStatus),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(staffName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                        ),
                        title: Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$designation • $salaryType'),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            _statusBtn(staffId, AppConstants.attendancePresent, 'Present', AppColors.success, currentStatus),
                            _statusBtn(staffId, AppConstants.attendanceAbsent, 'Absent', AppColors.error, currentStatus),
                            _statusBtn(staffId, AppConstants.attendanceHalfDay, 'Half Day', AppColors.info, currentStatus),
                            _statusBtn(staffId, AppConstants.attendanceLeave, 'Leave', AppColors.warning, currentStatus),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _statusBtn(String staffId, String status, String label, Color color, String? currentStatus) {
    final isSelected = currentStatus == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: color,
      onSelected: (_) => _mark(staffId, status),
    );
  }
}

// -------------------------------------------------------------
// 3. STAFF SALARIES SUB-VIEW
// -------------------------------------------------------------
class StaffSalariesSubView extends StatefulWidget {
  const StaffSalariesSubView({super.key});

  @override
  State<StaffSalariesSubView> createState() => _StaffSalariesSubViewState();
}

class _StaffSalariesSubViewState extends State<StaffSalariesSubView> {
  final _staffRepo = StaffRepository();
  DateTime _selectedMonth = DateTime.now();

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);

  void _disburseSalary(Map<String, dynamic> salary) async {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final initialRemaining = (salary['remaining_amount'] as num?)?.toDouble() ?? 0.0;
    final staffName = salary['staff_name'] ?? 'Staff';
    final salaryId = salary['id'] as String;
    final staffId = salary['staff_id'] as String;

    final commissionController = TextEditingController();
    final bonusController = TextEditingController();
    final overtimeController = TextEditingController();
    final amountController = TextEditingController(text: initialRemaining.toStringAsFixed(0));
    final refController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'Cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isNarrow = MediaQuery.of(context).size.width < 500;
            final commVal = double.tryParse(commissionController.text.trim()) ?? 0.0;
            final bonusVal = double.tryParse(bonusController.text.trim()) ?? 0.0;
            final otVal = double.tryParse(overtimeController.text.trim()) ?? 0.0;
            final extraTotal = commVal + bonusVal + otVal;
            final totalPayable = initialRemaining + extraTotal;

            void onExtraChanged() {
              final c = double.tryParse(commissionController.text.trim()) ?? 0.0;
              final b = double.tryParse(bonusController.text.trim()) ?? 0.0;
              final o = double.tryParse(overtimeController.text.trim()) ?? 0.0;
              final tot = initialRemaining + c + b + o;
              amountController.text = tot.toStringAsFixed(0);
            }

            return AlertDialog(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.payments_rounded, color: AppColors.primaryLight, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Disburse Salary: $staffName', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              content: SizedBox(
                width: isNarrow ? double.maxFinite : 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calculation Summary Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Base Net Due:', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13)),
                                Text(Formatters.currency(initialRemaining, symbol: currency), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                            if (extraTotal > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Extra (Comm + Bonus + OT):', style: TextStyle(color: AppColors.success, fontSize: 12)),
                                  Text('+ ${Formatters.currency(extraTotal, symbol: currency)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Net Due:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  Formatters.currency(totalPayable, symbol: currency),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Allowances / Extra Earnings Heading
                      const Text(
                        'Add Allowances / Incentives (Optional)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 8),

                      // Commission, Bonus, Overtime fields
                      if (isNarrow) ...[
                        TextField(
                          controller: commissionController,
                          decoration: const InputDecoration(
                            labelText: 'Commission',
                            hintText: '0',
                            prefixText: 'Rs. ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setDialogState(onExtraChanged),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: bonusController,
                          decoration: const InputDecoration(
                            labelText: 'Bonus',
                            hintText: '0',
                            prefixText: 'Rs. ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setDialogState(onExtraChanged),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: overtimeController,
                          decoration: const InputDecoration(
                            labelText: 'Overtime',
                            hintText: '0',
                            prefixText: 'Rs. ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setDialogState(onExtraChanged),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commissionController,
                                decoration: const InputDecoration(
                                  labelText: 'Commission',
                                  hintText: '0',
                                  prefixText: 'Rs. ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setDialogState(onExtraChanged),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: bonusController,
                                decoration: const InputDecoration(
                                  labelText: 'Bonus',
                                  hintText: '0',
                                  prefixText: 'Rs. ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setDialogState(onExtraChanged),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: overtimeController,
                                decoration: const InputDecoration(
                                  labelText: 'Overtime',
                                  hintText: '0',
                                  prefixText: 'Rs. ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setDialogState(onExtraChanged),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Disbursement Amount (Rs.)
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Disbursement Amount (Rs.) *',
                          prefixText: 'Rs. ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: 'Reset to total payable',
                            onPressed: () => setDialogState(() {
                              amountController.text = totalPayable.toStringAsFixed(0);
                            }),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => paymentMethod = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: refController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Reference (Optional)',
                          hintText: 'e.g. TRX-12345 or Cheque #',
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'e.g. November final salary settlement',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  onPressed: () => Get.back(result: true),
                  label: const Text('Confirm Disbursement'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      final payAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
      if (payAmount <= 0) {
        Get.snackbar('Invalid Amount', 'Please enter a valid disbursement amount');
        return;
      }

      final commVal = double.tryParse(commissionController.text.trim()) ?? 0.0;
      final bonusVal = double.tryParse(bonusController.text.trim()) ?? 0.0;
      final otVal = double.tryParse(overtimeController.text.trim()) ?? 0.0;

      try {
        await _staffRepo.recordSalaryPayment(
          salaryId: salaryId,
          staffId: staffId,
          amount: payAmount,
          paymentMethod: paymentMethod,
          isAdvance: false,
          commission: commVal,
          bonus: bonusVal,
          overtimeAmount: otVal,
          reference: refController.text.trim(),
          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
        );

        Get.snackbar('Success', 'Salary payment recorded', backgroundColor: AppColors.success.withValues(alpha: 0.2));
        if (mounted) setState(() {});
      } catch (e) {
        Get.snackbar('Error', 'Failed to disburse salary: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      }
    }
  }

  void _generateMonthlyPayroll() async {
    try {
      final staffList = await _staffRepo.getStaffList(activeOnly: true);
      final salariedStaff = staffList.where((s) => s.salaryType != AppConstants.salaryTypeCommission).toList();

      for (var s in salariedStaff) {
        final calc = await _staffRepo.calculateSalaryForStaff(s.id, _monthKey);
        await _staffRepo.saveSalaryRecord(calc);
      }

      Get.snackbar('Payroll Synchronized', 'Calculated payroll for ${salariedStaff.length} active staff members', backgroundColor: AppColors.success.withValues(alpha: 0.2));
      if (mounted) setState(() {});
    } catch (e) {
      Get.snackbar('Error', 'Payroll calculation failed: $e');
    }
  }

  Future<void> _shareSalarySlipOnWhatsApp(
    Map<String, dynamic> sal,
    String staffName,
    double basicSalary,
    double netSalary,
    double paidAmount,
    double remainingAmount,
    String status,
    double advDeduction,
  ) async {
    final b = AuthService.to.currentBusiness.value;
    if (b == null) return;

    try {
      final salModel = SalaryModel(
        id: sal['id'],
        businessId: 'local',
        staffId: sal['staff_id'],
        staffName: staffName,
        month: sal['pay_period'],
        basicSalary: basicSalary,
        presentDays: sal['present_days'] ?? 0,
        absentDays: sal['absent_days'] ?? 0,
        halfDays: sal['half_days'] ?? 0,
        overtimeAmount: (sal['overtime_amount'] as num?)?.toDouble() ?? 0.0,
        bonusAmount: (sal['bonus'] as num?)?.toDouble() ?? 0.0,
        commissionAmount: (sal['commission'] as num?)?.toDouble() ?? 0.0,
        advanceDeduction: advDeduction,
        grossSalary: (sal['gross_salary'] as num?)?.toDouble(),
        netSalary: netSalary,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        status: status,
      );

      final pdfBytes = await PdfService.buildSalarySlipBytes(business: b, salary: salModel);
      final tempDir = await getTemporaryDirectory();
      final baseName = 'SalarySlip_${staffName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${sal['pay_period']}_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = File('${tempDir.path}/$baseName.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Only 1 item sent: the official PDF slip
      if (Platform.isWindows) {
        await WindowsClipboardService.copyFileToClipboard(pdfFile.path);
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$baseName.pdf');
      }

      final rawPhone = (sal['staff_phone'] as String? ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
      final whatsappUri = Uri.parse(rawPhone.isNotEmpty ? 'whatsapp://send?phone=$rawPhone' : 'whatsapp://send');
      final webWhatsappUri = Uri.parse(rawPhone.isNotEmpty ? 'https://web.whatsapp.com/send?phone=$rawPhone' : 'https://web.whatsapp.com');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri);
      }

      Get.snackbar(
        'Salary Slip PDF Copied!',
        'Single PDF slip copied to clipboard. Open WhatsApp & press Ctrl + V to send!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.25),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366)),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not share salary slip: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    final isCompact = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;

                  final monthControls = Row(
                    mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: isCompact ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
                      ),
                    ],
                  );

                  final calculateButton = ElevatedButton.icon(
                    onPressed: _generateMonthlyPayroll,
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: Text(
                      isCompact ? 'Calculate Payroll' : 'Calculate / Sync Month Payroll',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        monthControls,
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: calculateButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      monthControls,
                      const Spacer(),
                      calculateButton,
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _staffRepo.getSalaries(payPeriod: _monthKey),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(message: 'Loading monthly payroll...');
                }

                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.payments_rounded,
                    title: 'No Payroll Generated for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                    description: 'Click "Calculate / Sync Month Payroll" to automatically compute staff salaries and deductions.',
                  );
                }

                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sal = list[index];
                      final staffName = sal['staff_name'] as String? ?? 'Staff';
                      final status = sal['status'] as String? ?? 'Pending';
                      final basicSalary = (sal['basic_salary'] as num?)?.toDouble() ?? 0.0;
                      final netSalary = (sal['net_salary'] as num?)?.toDouble() ?? 0.0;
                      final paidAmount = (sal['paid_amount'] as num?)?.toDouble() ?? 0.0;
                      final remainingAmount = (sal['remaining_amount'] as num?)?.toDouble() ?? 0.0;
                      final advDeduction = (sal['advance_deductions'] as num?)?.toDouble() ?? 0.0;
                      final commission = (sal['commission'] as num?)?.toDouble() ?? 0.0;
                      final bonus = (sal['bonus'] as num?)?.toDouble() ?? 0.0;
                      final overtime = (sal['overtime_amount'] as num?)?.toDouble() ?? 0.0;

                      if (isCompact) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: const Icon(Icons.receipt_rounded, color: AppColors.primaryLight, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: status == 'Paid' ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'Paid' ? AppColors.success : AppColors.error)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Net: ${Formatters.currency(netSalary, symbol: currency)} • Paid: ${Formatters.currency(paidAmount, symbol: currency)} • Due: ${Formatters.currency(remainingAmount, symbol: currency)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
                              ),
                              if (commission > 0 || bonus > 0 || overtime > 0)
                                Text(
                                  'Incentives: ${overtime > 0 ? "OT: +${Formatters.currency(overtime, symbol: currency)} " : ""}${bonus > 0 ? "Bonus: +${Formatters.currency(bonus, symbol: currency)} " : ""}${commission > 0 ? "Comm: +${Formatters.currency(commission, symbol: currency)}" : ""}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                              if (advDeduction > 0)
                                Text(
                                  'Basic: ${Formatters.currency(basicSalary, symbol: currency)} • Advance/Expense Deducted: -${Formatters.currency(advDeduction, symbol: currency)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.print_rounded, size: 16),
                                    label: const Text('Slip PDF', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                    onPressed: () {
                                      final b = AuthService.to.currentBusiness.value;
                                      if (b != null) {
                                        final salModel = SalaryModel(
                                          id: sal['id'],
                                          businessId: 'local',
                                          staffId: sal['staff_id'],
                                          staffName: staffName,
                                          month: sal['pay_period'],
                                          basicSalary: basicSalary,
                                          presentDays: sal['present_days'] ?? 0,
                                          absentDays: sal['absent_days'] ?? 0,
                                          halfDays: sal['half_days'] ?? 0,
                                          overtimeAmount: overtime,
                                          bonusAmount: bonus,
                                          commissionAmount: commission,
                                          advanceDeduction: advDeduction,
                                          grossSalary: (sal['gross_salary'] as num?)?.toDouble(),
                                          netSalary: netSalary,
                                          paidAmount: paidAmount,
                                          remainingAmount: remainingAmount,
                                          status: status,
                                        );
                                        PdfService.printSalarySlip(business: b, salary: salModel);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.share, size: 16, color: Color(0xFF25D366)),
                                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11, color: Color(0xFF25D366))),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: const BorderSide(color: Color(0xFF25D366)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () => _shareSalarySlipOnWhatsApp(
                                      sal,
                                      staffName,
                                      basicSalary,
                                      netSalary,
                                      paidAmount,
                                      remainingAmount,
                                      status,
                                      advDeduction,
                                    ),
                                  ),
                                  if (remainingAmount > 0) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _disburseSalary(sal),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text('Pay', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.receipt_rounded, color: AppColors.primaryLight),
                        ),
                        title: Row(
                          children: [
                            Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: status == 'Paid' ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'Paid' ? AppColors.success : AppColors.error)),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Basic: ${Formatters.currency(basicSalary, symbol: currency)}'
                          '${(overtime > 0 || bonus > 0 || commission > 0) ? " • Extra: +${Formatters.currency(overtime + bonus + commission, symbol: currency)}" : ""}'
                          '${advDeduction > 0 ? " • Adv/Exp: -${Formatters.currency(advDeduction, symbol: currency)}" : ""}'
                          ' • Net: ${Formatters.currency(netSalary, symbol: currency)} • Paid: ${Formatters.currency(paidAmount, symbol: currency)} • Due: ${Formatters.currency(remainingAmount, symbol: currency)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print_rounded, size: 18),
                              tooltip: 'Print Pay Slip PDF',
                              onPressed: () {
                                final b = AuthService.to.currentBusiness.value;
                                if (b != null) {
                                  final salModel = SalaryModel(
                                    id: sal['id'],
                                    businessId: 'local',
                                    staffId: sal['staff_id'],
                                    staffName: staffName,
                                    month: sal['pay_period'],
                                    basicSalary: basicSalary,
                                    presentDays: sal['present_days'] ?? 0,
                                    absentDays: sal['absent_days'] ?? 0,
                                    halfDays: sal['half_days'] ?? 0,
                                    overtimeAmount: overtime,
                                    bonusAmount: bonus,
                                    commissionAmount: commission,
                                    advanceDeduction: advDeduction,
                                    grossSalary: (sal['gross_salary'] as num?)?.toDouble(),
                                    netSalary: netSalary,
                                    paidAmount: paidAmount,
                                    remainingAmount: remainingAmount,
                                    status: status,
                                  );
                                  PdfService.printSalarySlip(business: b, salary: salModel);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, size: 18, color: Color(0xFF25D366)),
                              tooltip: 'Share Pay Slip on WhatsApp',
                              onPressed: () => _shareSalarySlipOnWhatsApp(
                                sal,
                                staffName,
                                basicSalary,
                                netSalary,
                                paidAmount,
                                remainingAmount,
                                status,
                                advDeduction,
                              ),
                            ),
                            if (remainingAmount > 0)
                              ElevatedButton(
                                onPressed: () => _disburseSalary(sal),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                child: const Text('Pay'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. STAFF EXPENSES SUB-VIEW (User-defined Categories)
// -------------------------------------------------------------
class StaffExpensesSubView extends StatefulWidget {
  const StaffExpensesSubView({super.key});

  @override
  State<StaffExpensesSubView> createState() => _StaffExpensesSubViewState();
}

class _StaffExpensesSubViewState extends State<StaffExpensesSubView> {
  final _staffRepo = StaffRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _startDate;
  String? _endDate;

  void _openStaffExpenseDialog([Map<String, dynamic>? existing]) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => StaffExpenseFormDialog(existing: existing),
    );
    if (res == true && mounted) setState(() {});
  }

  Future<void> _shareStaffExpenseOnWhatsApp(Map<String, dynamic> exp) async {
    final b = AuthService.to.currentBusiness.value;
    if (b == null) return;

    try {
      final staffName = exp['staff_name'] as String? ?? 'Staff';
      final staffPhone = (exp['staff_phone'] as String? ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
      final staffDesignation = exp['designation'] as String? ?? 'Staff';

      final pdfBytes = await PdfService.buildStaffExpenseSlipBytes(
        business: b,
        expense: exp,
        staffName: staffName,
        staffPhone: exp['staff_phone'] as String?,
        staffDesignation: staffDesignation,
      );

      final tempDir = await getTemporaryDirectory();
      final baseName = 'ExpenseVoucher_${staffName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = File('${tempDir.path}/$baseName.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Only 1 item sent: the official PDF voucher
      if (Platform.isWindows) {
        await WindowsClipboardService.copyFileToClipboard(pdfFile.path);
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$baseName.pdf');
      }

      final whatsappUri = Uri.parse(staffPhone.isNotEmpty ? 'whatsapp://send?phone=$staffPhone' : 'whatsapp://send');
      final webWhatsappUri = Uri.parse(staffPhone.isNotEmpty ? 'https://web.whatsapp.com/send?phone=$staffPhone' : 'https://web.whatsapp.com');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri);
      }

      Get.snackbar(
        'Voucher PDF Copied!',
        'Single PDF voucher copied to clipboard. Open WhatsApp & press Ctrl + V to send!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.25),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366)),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not share voucher: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    final isCompact = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final searchField = TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by staff name, category...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              );
              final addButton = ElevatedButton.icon(
                onPressed: () => _openStaffExpenseDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Staff Expense'),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: addButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 14),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DateRangeFilterBar(
            onFilterChanged: (start, end, label) {
              setState(() {
                _startDate = start;
                _endDate = end;
              });
            },
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _staffRepo.getStaffExpenses(startDate: _startDate, endDate: _endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(message: 'Loading staff expenses...');
                }

                final all = snapshot.data ?? [];
                final filtered = all.where((e) {
                  final staffName = (e['staff_name'] as String? ?? '').toLowerCase();
                  final category = (e['category'] as String? ?? '').toLowerCase();
                  final ref = (e['reference'] as String? ?? '').toLowerCase();
                  return staffName.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      ref.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No Staff Expenses Logged',
                    description: 'Log advances, bonuses, commissions, or travel reimbursements here.',
                  );
                }

                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exp = filtered[index];
                      final staffName = exp['staff_name'] as String? ?? 'Staff';
                      final category = exp['category'] as String? ?? 'Expense';
                      final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
                      final date = DateTime.tryParse(exp['date']?.toString() ?? '') ?? DateTime.now();
                      final method = exp['payment_method'] as String? ?? 'Cash';
                      final ref = exp['reference'] as String?;
                      final notes = exp['notes'] as String?;
                      final id = exp['id'] as String;

                      if (isCompact) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: const Icon(Icons.badge_rounded, color: AppColors.primaryLight, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  Text(
                                    Formatters.currency(amount, symbol: currency),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.borderDark),
                                    ),
                                    child: Text(category, style: const TextStyle(fontSize: 10)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${Formatters.date(date)} • $method ${ref != null && ref.isNotEmpty ? "• $ref" : ""}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (notes != null && notes.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Notes: $notes', style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.print_rounded, size: 15),
                                    label: const Text('Slip PDF', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                    onPressed: () {
                                      final b = AuthService.to.currentBusiness.value;
                                      if (b != null) {
                                        PdfService.printStaffExpenseSlip(
                                          business: b,
                                          expense: exp,
                                          staffName: staffName,
                                          staffPhone: exp['staff_phone'] as String?,
                                          staffDesignation: exp['designation'] as String? ?? 'Staff',
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.share, size: 15, color: Color(0xFF25D366)),
                                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11, color: Color(0xFF25D366))),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: const BorderSide(color: Color(0xFF25D366)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () => _shareStaffExpenseOnWhatsApp(exp),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final confirm = await Get.dialog<bool>(
                                        AlertDialog(
                                          title: const Text('Delete Staff Expense'),
                                          content: Text('Delete this expense of ${Formatters.currency(amount, symbol: currency)}?'),
                                          actions: [
                                            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                              onPressed: () => Get.back(result: true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _staffRepo.deleteStaffExpense(id);
                                        Get.snackbar('Deleted', 'Staff expense deleted');
                                        if (mounted) setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.badge_rounded, color: AppColors.primaryLight, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Text(category, style: const TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${Formatters.date(date)} • Method: $method ${ref != null && ref.isNotEmpty ? "• Ref: $ref" : ""} ${notes != null && notes.isNotEmpty ? "• Notes: $notes" : ""}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.currency(amount, symbol: currency),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.print_rounded, size: 20, color: AppColors.primaryLight),
                              tooltip: 'Print Voucher Slip',
                              onPressed: () {
                                final b = AuthService.to.currentBusiness.value;
                                if (b != null) {
                                  PdfService.printStaffExpenseSlip(
                                    business: b,
                                    expense: exp,
                                    staffName: staffName,
                                    staffPhone: exp['staff_phone'] as String?,
                                    staffDesignation: exp['designation'] as String? ?? 'Staff',
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, size: 20, color: Color(0xFF25D366)),
                              tooltip: 'Share Voucher on WhatsApp',
                              onPressed: () => _shareStaffExpenseOnWhatsApp(exp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Delete Staff Expense'),
                                    content: Text('Delete this expense of ${Formatters.currency(amount, symbol: currency)}?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                        onPressed: () => Get.back(result: true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _staffRepo.deleteStaffExpense(id);
                                  Get.snackbar('Deleted', 'Staff expense deleted');
                                  if (mounted) setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StaffExpenseFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const StaffExpenseFormDialog({super.key, this.existing});

  @override
  State<StaffExpenseFormDialog> createState() => _StaffExpenseFormDialogState();
}

class _StaffExpenseFormDialogState extends State<StaffExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _staffRepo = StaffRepository();
  StaffModel? _selectedStaff;
  List<StaffModel> _staffList = [];

  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  late final TextEditingController _refController;
  late final TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'Cash';
  String? _receiptUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _categoryController = TextEditingController(text: e?['category'] ?? '');
    _amountController = TextEditingController(text: e != null ? (e['amount'] as num?)?.toString() ?? '' : '');
    _refController = TextEditingController(text: e?['reference'] ?? '');
    _notesController = TextEditingController(text: e?['notes'] ?? '');
    if (e != null) {
      _selectedDate = DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime.now();
      _paymentMethod = e['payment_method'] ?? 'Cash';
      _receiptUrl = e['receipt_path'];
    }
    _loadStaff();
  }

  void _loadStaff() async {
    final list = await _staffRepo.getStaffList(activeOnly: true);
    if (mounted) {
      setState(() {
        _staffList = list;
        if (widget.existing != null) {
          final sid = widget.existing!['staff_id'];
          _selectedStaff = _staffList.firstWhereOrNull((s) => s.id == sid);
        }
      });
    }
  }

  void _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final savedPath = await StorageService.saveLocalFile(
        bytes: bytes,
        fileName: 'staff_receipt_${const Uuid().v4()}.$ext',
        subfolder: 'receipts',
      );
      setState(() => _receiptUrl = savedPath);
      Get.snackbar('Attached', 'Receipt saved locally');
    } catch (e) {
      Get.snackbar('Error', 'Failed to attach receipt: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaff == null) {
      Get.snackbar('Required', 'Please select a staff member');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount');
      return;
    }

    setState(() => _isSaving = true);
    final id = widget.existing?['id'];

    try {
      await _staffRepo.saveStaffExpense(
        id: id,
        staffId: _selectedStaff!.id,
        category: _categoryController.text.trim(),
        description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : _categoryController.text.trim(),
        amount: amount,
        date: _selectedDate,
        paymentMethod: _paymentMethod,
        reference: _refController.text.trim(),
        receiptPath: _receiptUrl,
        notes: _notesController.text.trim(),
      );
      Get.back(result: true);
      Get.snackbar('Saved', 'Staff expense saved successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save staff expense: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Staff Expense' : 'Edit Staff Expense',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StaffModel>(
                  value: _selectedStaff,
                  decoration: const InputDecoration(
                    labelText: 'Select Staff Member *',
                    prefixIcon: Icon(Icons.person_rounded, size: 20),
                  ),
                  items: _staffList
                      .map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.designation})')))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStaff = val),
                  validator: (v) => v == null ? 'Select staff member' : null,
                ),
                const SizedBox(height: 14),

                // Category (Admin enters custom category directly)
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category *',
                    hintText: 'Enter category name (e.g. Advance, Food, Travel, Medical)',
                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                  ),
                  onChanged: (val) => setState(() {}),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a category' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          prefixIcon: Icon(Icons.payments_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => _selectedDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                          ),
                          child: Text(Formatters.date(_selectedDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: ['Cash', 'Bank Transfer', 'Online', 'Other']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _refController,
                        decoration: const InputDecoration(labelText: 'Reference / Voucher #'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes / Purpose'),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickReceipt,
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(_receiptUrl != null ? 'Replace Receipt' : 'Attach Receipt'),
                    ),
                    if (_receiptUrl != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 4),
                      const Text('Attached', style: TextStyle(fontSize: 12, color: AppColors.success)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save Staff Expense'),
        ),
      ],
    );
  }
}
