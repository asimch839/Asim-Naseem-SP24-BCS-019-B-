import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.staff,
      title: 'Staff Management System',
      body: Column(
        children: [
          // Sub-navigation Tabs (Staff List, Attendance, Salaries, Staff Expenses)
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: AppColors.textDarkSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.people_alt_rounded), text: 'Staff List'),
                Tab(icon: Icon(Icons.event_available_rounded), text: 'Attendance'),
                Tab(icon: Icon(Icons.payments_rounded), text: 'Salaries'),
                Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Staff Expenses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                StaffListSubView(),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search staff by name, designation, phone, or CNIC...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await showDialog<bool>(
                    context: context,
                    builder: (_) => const StaffFormDialog(),
                  );
                  if (res == true && mounted) setState(() {});
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Staff Member'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<StaffModel>>(
              future: _staffRepo.getStaffList(searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(message: 'Loading staff directory...');
                }

                final filtered = snapshot.data ?? [];

                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.badge_rounded,
                    title: 'No Staff Members Registered',
                    description: 'Add technicians, detailers, and shop managers to track attendance and payroll.',
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
                          '${staff.designation} • Phone: ${staff.phone} ${staff.cnic != null && staff.cnic!.isNotEmpty ? "• CNIC: ${staff.cnic}" : ""} • Salary: ${Formatters.currency(staff.basicSalary, symbol: currency)} (${staff.salaryType})',
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Date Selector Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                  ),
                  InkWell(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                  ),
                  const Spacer(),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _staffRepo.getDailyAttendance(dateStr),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];
                      final present = list.where((a) => a['attendance_status'] == AppConstants.attendancePresent).length;
                      final absent = list.where((a) => a['attendance_status'] == AppConstants.attendanceAbsent).length;
                      final leave = list.where((a) => a['attendance_status'] == AppConstants.attendanceLeave).length;
                      return Row(
                        children: [
                          _badge('Present: $present', AppColors.success),
                          const SizedBox(width: 8),
                          _badge('Absent: $absent', AppColors.error),
                          const SizedBox(width: 8),
                          _badge('Leave: $leave', AppColors.warning),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
    final remainingAmount = (salary['remaining_amount'] as num?)?.toDouble() ?? 0.0;
    final staffName = salary['staff_name'] ?? 'Staff';
    final salaryId = salary['id'] as String;
    final staffId = salary['staff_id'] as String;

    final amountController = TextEditingController(text: remainingAmount.toStringAsFixed(0));
    String paymentMethod = 'Cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Disburse Salary: $staffName'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Net Due: Rs. ${remainingAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Disbursement Amount (Rs.) *'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => paymentMethod = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Confirm Disbursement'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      final payAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
      if (payAmount <= 0) return;

      try {
        await _staffRepo.recordSalaryPayment(
          salaryId: salaryId,
          staffId: staffId,
          amount: payAmount,
          paymentMethod: paymentMethod,
          isAdvance: false,
          notes: 'Disbursement for $_monthKey',
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

      for (var s in staffList) {
        final calc = await _staffRepo.calculateSalaryForStaff(s.id, _monthKey);
        await _staffRepo.saveSalaryRecord(calc);
      }

      Get.snackbar('Payroll Synchronized', 'Calculated payroll for ${staffList.length} active staff members', backgroundColor: AppColors.success.withValues(alpha: 0.2));
      if (mounted) setState(() {});
    } catch (e) {
      Get.snackbar('Error', 'Payroll calculation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _generateMonthlyPayroll,
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text('Calculate / Sync Month Payroll'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
                          'Basic: ${Formatters.currency(basicSalary, symbol: currency)} • Net: ${Formatters.currency(netSalary, symbol: currency)} • Paid: ${Formatters.currency(paidAmount, symbol: currency)} • Due: ${Formatters.currency(remainingAmount, symbol: currency)}',
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
                                    netSalary: netSalary,
                                    paidAmount: paidAmount,
                                    remainingAmount: remainingAmount,
                                    status: status,
                                  );
                                  PdfService.printSalarySlip(business: b, salary: salModel);
                                }
                              },
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

  void _openStaffExpenseDialog([Map<String, dynamic>? existing]) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => StaffExpenseFormDialog(existing: existing),
    );
    if (res == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by staff name, category, or reference...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openStaffExpenseDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Staff Expense'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _staffRepo.getStaffExpenses(),
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
      title: Text(widget.existing == null ? 'Add Staff Expense' : 'Edit Staff Expense'),
      content: SizedBox(
        width: 500,
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

                // Category (User types freely)
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category * (e.g., Advance, Bonus, Medical, Travel, Food)',
                    hintText: 'Enter expense category',
                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter category' : null,
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
