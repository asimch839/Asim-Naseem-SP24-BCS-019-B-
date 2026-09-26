import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/services/excel_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/room_allocation_model.dart';
import '../../data/models/rent_record_model.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/rent_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/status_badge.dart';
import '../receipts/receipt_controller.dart';

class HistoryController extends GetxController {
  final HistoryRepository _historyRepo = HistoryRepository();
  final StudentRepository _studentRepo = StudentRepository();
  final RentRepository _rentRepo = RentRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  // Tab: 0 = Students History & Ledgers, 1 = System Activity Logs
  final selectedTab = 0.obs;

  // ==========================================
  // TAB 1: STUDENT HISTORY STATE
  // ==========================================
  final students = <StudentModel>[].obs;
  final isLoadingStudents = true.obs;
  final studentSearchQuery = ''.obs;
  final studentStatusFilter = 'All'.obs; // 'All', 'Active', 'Left'

  // Selected Student Detailed History State
  final selectedStudent = Rx<StudentModel?>(null);
  final studentPayments = <PaymentModel>[].obs;
  final studentAllocations = <RoomAllocationModel>[].obs;
  final studentRentRecords = <RentRecordModel>[].obs;
  final isLoadingStudentDetails = false.obs;

  // ==========================================
  // TAB 2: SYSTEM AUDIT LOGS STATE
  // ==========================================
  final logs = <ActivityLogModel>[].obs;
  final summary = Rx<HistorySummaryData?>(null);
  final isLoading = true.obs;

  // Unified Filter State
  late DateTime fromDate;
  late DateTime toDate;
  final dateFilterLabel = 'This Month'.obs;
  final searchQuery = ''.obs;
  final activityTypeFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    dateFilterLabel.value = 'This Month (${DateFormatter.formatMonthYear(now)})';

    fetchStudentsHistory();
    fetchHistoryLogs();
  }

  // ==========================================
  // STUDENT HISTORY METHODS
  // ==========================================
  Future<void> fetchStudentsHistory() async {
    isLoadingStudents.value = true;
    try {
      students.value = await _studentRepo.getAllStudents(
        search: studentSearchQuery.value,
        statusFilter: studentStatusFilter.value,
        autoSyncRent: false,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load students history: $e');
    } finally {
      isLoadingStudents.value = false;
    }
  }

  Future<void> openStudentHistoryModal(StudentModel student) async {
    selectedStudent.value = student;
    isLoadingStudentDetails.value = true;

    // Show modal immediately with loading indicator
    _showStudentCompleteHistoryDialog(student);

    try {
      if (student.id != null) {
        final results = await Future.wait([
          _rentRepo.getStudentPaymentHistory(student.id!),
          _studentRepo.getStudentAllocations(student.id!),
          _rentRepo.getStudentRentRecords(student.id!),
        ]);
        studentPayments.value = results[0] as List<PaymentModel>;
        studentAllocations.value = results[1] as List<RoomAllocationModel>;
        studentRentRecords.value = results[2] as List<RentRecordModel>;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch student detailed ledger: $e');
    } finally {
      isLoadingStudentDetails.value = false;
    }
  }

  void _showStudentCompleteHistoryDialog(StudentModel student) {
    Get.dialog(
      Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1050,
                maxHeight: screenSize.height * 0.92,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: student.isActive
                              ? AppColors.primaryLight.withValues(alpha: 0.15)
                              : AppColors.textMuted.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.person_rounded,
                            color: student.isActive ? AppColors.primary : AppColors.textSecondary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(student.fullName, style: AppStyles.h3),
                                  const SizedBox(width: 10),
                                  StatusBadge(status: student.status),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Roll / ID: ${student.studentIdCode} • Phone: ${student.phone} • Room: ${student.roomNumber ?? "None"} (Bed: ${student.bedNumber ?? "None"})',
                                style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                          onPressed: () {
                            if (Get.isDialogOpen == true) Get.back();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Scrollable Profile & History Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Complete Student Details Card
                            _buildStudentProfileSection(student),
                            const SizedBox(height: 20),

                            // Section 2: Financial Ledger & Payment History
                            _buildPaymentHistorySection(),
                            const SizedBox(height: 20),

                            // Section 3: Security Deposit & Departure Settlement History
                            _buildSecuritySettlementSection(student),
                            const SizedBox(height: 20),

                            // Section 4: Room Allocation History
                            _buildRoomAllocationHistorySection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentProfileSection(StudentModel s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Complete Student Profile & Admission Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildDetailItem('Father Name', s.fatherName),
              _buildDetailItem('CNIC Number', s.cnic),
              _buildDetailItem('Phone Number', s.phone),
              _buildDetailItem('Emergency Contact', s.emergencyContact),
              _buildDetailItem('University / College', s.university),
              _buildDetailItem('Department', s.department),
              _buildDetailItem('Semester', s.semester),
              _buildDetailItem('Permanent Address', s.address),
              _buildDetailItem('Admission Date', DateFormatter.formatDate(DateTime.tryParse(s.admissionDate))),
              if (s.leavingDate != null && s.leavingDate!.isNotEmpty)
                _buildDetailItem('Leaving / Departure Date', DateFormatter.formatDate(DateTime.tryParse(s.leavingDate!))),
              _buildDetailItem('Monthly Rent Package', CurrencyFormatter.format(s.monthlyRent)),
              _buildDetailItem('Security Deposit Balance', CurrencyFormatter.format(s.securityDeposit)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value.isNotEmpty ? value : '-',
            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Obx(() {
      final payments = studentPayments;
      final totalPaid = payments.fold<double>(0.0, (sum, p) => sum + p.amount);

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_rounded, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text(
                      'Rent & Payment History Ledger',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${payments.length} Payments',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total Paid: ${CurrencyFormatter.format(totalPaid)}',
                  style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoadingStudentDetails.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (payments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No payment records found for this student yet.',
                    style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    columns: const [
                      DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Billing Month', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Receipt #', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Notes / Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: payments.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text(DateFormatter.formatDate(DateTime.tryParse(p.paymentDate)), style: AppStyles.bodySmall)),
                          DataCell(Text(p.rentMonth ?? '-', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                          DataCell(Text(
                            CurrencyFormatter.format(p.amount),
                            style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                          )),
                          DataCell(_buildMethodBadge(p.paymentMethod)),
                          DataCell(Text(p.receiptNumber, style: AppStyles.caption.copyWith(fontFamily: 'monospace'))),
                          DataCell(
                            Tooltip(
                              message: p.notes != null && p.notes!.isNotEmpty ? p.notes! : 'No notes',
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  p.notes != null && p.notes!.isNotEmpty ? p.notes! : '-',
                                  style: AppStyles.caption.copyWith(color: AppColors.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                                tooltip: 'Preview Receipt',
                                onPressed: () => _openReceiptForPayment(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
                                tooltip: 'Share Receipt',
                                onPressed: () => _shareReceiptWhatsAppForPayment(p),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildMethodBadge(String method) {
    Color bg = AppColors.surfaceSecondary;
    Color fg = AppColors.textPrimary;

    if (method.toLowerCase().contains('refund')) {
      bg = AppColors.success.withValues(alpha: 0.15);
      fg = AppColors.success;
    } else if (method.toLowerCase().contains('cash')) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
    } else if (method.toLowerCase().contains('bank') || method.toLowerCase().contains('online')) {
      bg = AppColors.primary.withValues(alpha: 0.12);
      fg = AppColors.primary;
    } else if (method.toLowerCase().contains('security')) {
      bg = AppColors.accent.withValues(alpha: 0.15);
      fg = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        method,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildRoomAllocationHistorySection() {
    return Obx(() {
      final allocs = studentAllocations;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.meeting_room_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Room & Bed Allocation History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoadingStudentDetails.value)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (allocs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No room allocation transitions recorded.',
                    style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
                    columns: const [
                    DataColumn(label: Text('Room #', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Bed #', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Allocated From', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Vacated Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: allocs.map((a) {
                    return DataRow(
                      cells: [
                        DataCell(Text('Room ${a.roomNumber ?? a.roomId}', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                        DataCell(Text('Bed ${a.bedNumber ?? a.bedId}', style: AppStyles.bodySmall)),
                        DataCell(Text(DateFormatter.formatDate(DateTime.tryParse(a.startDate)), style: AppStyles.bodySmall)),
                        DataCell(Text(
                          a.endDate != null ? DateFormatter.formatDate(DateTime.tryParse(a.endDate!)) : 'Current Active Bed',
                          style: AppStyles.bodySmall.copyWith(
                            color: a.endDate == null ? AppColors.success : AppColors.textSecondary,
                            fontWeight: a.endDate == null ? FontWeight.bold : FontWeight.normal,
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSecuritySettlementSection(StudentModel s) {
    return Obx(() {
      final payments = studentPayments;
      
      // Calculate adjusted to rent from payments or notes
      double adjustedRentTotal = payments
          .where((p) => p.paymentMethod == 'Security Deposit' || (p.notes != null && p.notes!.toLowerCase().contains('adjusted towards rent')))
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      // Calculate refunded from payments or notes
      double refundedAmount = payments
          .where((p) => p.paymentMethod == 'Security Refund' || (p.notes != null && p.notes!.toLowerCase().contains('refunded upon departure')))
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      // Fallback to notes parsing if payments were made before ledger sync
      if (s.notes != null) {
        if (adjustedRentTotal == 0.0) {
          final adjustMatch = RegExp(r'Security adjusted towards rent: Rs\.\s*([\d\.]+)').firstMatch(s.notes!);
          if (adjustMatch != null && adjustMatch.group(1) != null) {
            adjustedRentTotal = double.tryParse(adjustMatch.group(1)!) ?? 0.0;
          }
        }
        if (refundedAmount == 0.0) {
          final refundMatch = RegExp(r'Security refunded to student: Rs\.\s*([\d\.]+)').firstMatch(s.notes!);
          if (refundMatch != null && refundMatch.group(1) != null) {
            refundedAmount = double.tryParse(refundMatch.group(1)!) ?? 0.0;
          }
        }
      }

      final initialSecurity = s.securityDeposit + adjustedRentTotal + refundedAmount;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Text(
                      'Security Deposit & Departure Settlement History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.isLeft
                        ? (s.securityDeposit <= 0 ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12))
                        : AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: s.isLeft
                          ? (s.securityDeposit <= 0 ? AppColors.success : AppColors.warning)
                          : AppColors.accent,
                    ),
                  ),
                  child: Text(
                    s.isLeft ? (s.securityDeposit <= 0 ? 'Settled & Closed' : 'Partially Settled') : 'Active Escrow',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: s.isLeft
                          ? (s.securityDeposit <= 0 ? AppColors.success : AppColors.warning)
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary metrics
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildSettlementStat('Initial Security Deposit', CurrencyFormatter.format(initialSecurity), AppColors.textPrimary, Icons.savings_outlined),
                _buildSettlementStat('Adjusted Towards Rent', CurrencyFormatter.format(adjustedRentTotal), AppColors.primary, Icons.sync_alt_rounded),
                _buildSettlementStat('Refunded Upon Departure', CurrencyFormatter.format(refundedAmount), AppColors.success, Icons.assignment_return_outlined),
                _buildSettlementStat('Current Security Balance', CurrencyFormatter.format(s.securityDeposit), AppColors.accent, Icons.account_balance_wallet_outlined),
              ],
            ),

            if (s.notes != null && (s.notes!.contains('Departure:') || s.notes!.contains('Security adjusted') || s.notes!.contains('Security refunded') || s.notes!.contains('Settlement note:'))) ...[
              const SizedBox(height: 14),
              const Divider(color: AppColors.divider, height: 14),
              const SizedBox(height: 6),
              Text('Departure Settlement Details & Audit Trail:', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  s.notes!,
                  style: AppStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ] else if (s.isLeft) ...[
              const SizedBox(height: 12),
              Text(
                'Student departed on ${s.leavingDate != null ? DateFormatter.formatDate(DateTime.tryParse(s.leavingDate!)) : "-"}. Security deposit balance is settled.',
                style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Resident is currently active. Security deposit is safely held in hostel escrow and will be settled upon departure.',
                style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSettlementStat(String label, String value, Color color, IconData icon) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReceiptForPayment(PaymentModel p) async {
    if (p.id == null) return;
    try {
      final receipt = await _rentRepo.getReceiptByPaymentId(p.id!);
      if (receipt != null) {
        if (Get.isRegistered<ReceiptController>()) {
          Get.find<ReceiptController>().previewReceipt(receipt);
        } else {
          final rc = Get.put(ReceiptController());
          rc.previewReceipt(receipt);
        }
      } else {
        Get.snackbar('Notice', 'No formal receipt generated for this transaction.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open receipt: $e');
    }
  }

  Future<void> _shareReceiptWhatsAppForPayment(PaymentModel p) async {
    if (p.id == null) return;
    try {
      final receipt = await _rentRepo.getReceiptByPaymentId(p.id!);
      final settings = await _settingsRepo.getSettings();
      if (receipt != null && Get.context != null) {
        WhatsAppService.showShareDialog(
          context: Get.context!,
          receipt: receipt,
          settings: settings,
        );
      } else {
        Get.snackbar('Notice', 'Receipt not found for this transaction.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not prepare WhatsApp receipt: $e');
    }
  }

  // ==========================================
  // TAB 2: SYSTEM AUDIT LOGS METHODS
  // ==========================================
  void updateDateRange(DateTime from, DateTime to, String label) {
    fromDate = from;
    toDate = to;
    dateFilterLabel.value = label;
    fetchHistoryLogs();
  }

  Future<void> fetchHistoryLogs() async {
    isLoading.value = true;
    try {
      final startIso = fromDate.toIso8601String();
      final endIso = toDate.toIso8601String();
      final startDay = DateFormatter.toIsoDate(fromDate);
      final endDay = DateFormatter.toIsoDate(toDate);

      logs.value = await _historyRepo.getHistoricalLogs(
        startDateTime: startIso,
        endDateTime: endIso,
        search: searchQuery.value,
        activityTypeFilter: activityTypeFilter.value,
      );

      summary.value = await _historyRepo.getSummaryForDateRange(
        startDate: startDay,
        endDate: endDay,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load historical records: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void inspectLogDetails(ActivityLogModel log) {
    CustomDialog.show(
      title: 'Activity Log Details',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow('Activity Type:', log.activityType),
          _buildRow('Description:', log.description),
          _buildRow('Timestamp:', DateFormatter.formatDateTime(DateTime.tryParse(log.createdAt))),
          _buildRow('User / Operator:', log.username),
          if (log.studentName != null) _buildRow('Related Student:', '${log.studentName} (${log.studentIdCode ?? '-'})'),
          if (log.roomNumber != null) _buildRow('Related Room:', 'Room ${log.roomNumber}'),
          if (log.recordId != null) _buildRow('Linked Record ID:', '#${log.recordId}'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  /// Export the complete filtered dataset to Excel
  Future<void> exportToExcel() async {
    if (logs.isEmpty) {
      Get.snackbar('Notice', 'No logs to export.');
      return;
    }

    try {
      final headers = ['Date & Time', 'Activity Type', 'Description', 'Student', 'Student ID', 'Room', 'User'];
      final rows = logs.map((log) {
        return [
          DateFormatter.formatDateTime(DateTime.tryParse(log.createdAt)),
          log.activityType,
          log.description,
          log.studentName ?? '-',
          log.studentIdCode ?? '-',
          log.roomNumber != null ? 'Room ${log.roomNumber}' : '-',
          log.username,
        ];
      }).toList();

      final filePath = await ExcelService.exportToExcel(
        fileNamePrefix: 'Hostel_History_Report',
        sheetTitle: 'Operational & Financial History',
        dateRangeText: dateFilterLabel.value,
        headers: headers,
        rows: rows,
      );

      if (filePath != null) {
        Get.snackbar('Export Complete', 'Saved report to $filePath');
      }
    } catch (e) {
      Get.snackbar('Export Failed', e.toString());
    }
  }
}
