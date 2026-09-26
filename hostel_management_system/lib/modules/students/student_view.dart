import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/student_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/bed_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/data_table_widget.dart';
import '../../core/utils/responsive.dart';
import '../layout/main_layout_controller.dart';
import 'student_controller.dart';

class StudentView extends GetView<StudentController> {
  const StudentView({super.key});

  void _showStudentDetailsDialog(StudentModel student) {
    controller.viewStudentDetails(student);

    Get.dialog(
      Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 780,
                maxHeight: screenSize.height * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                                    style: AppStyles.h2.copyWith(color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student.fullName, style: AppStyles.h3, overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${student.studentIdCode} • Admitted: ${DateFormatter.formatDate(DateTime.tryParse(student.admissionDate))}',
                                        style: AppStyles.caption,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: student.status),
                              const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                                  onPressed: () {
                                    if (Get.isDialogOpen == true) Get.back();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        isScrollable: screenSize.width < 650,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: const [
                          Tab(text: 'General Information'),
                          Tab(text: 'Room Allocation History'),
                          Tab(text: 'Payment History'),
                        ],
                      ),
                      const SizedBox(height: 16),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Info
                      SingleChildScrollView(
                        primary: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Current Accommodation'),
                            _buildInfoGrid([
                              _infoTile('Assigned Room', student.roomNumber ?? 'Not Assigned'),
                              _infoTile('Assigned Bed', student.bedNumber ?? 'Not Assigned'),
                              _infoTile('Monthly Rent', CurrencyFormatter.format(student.monthlyRent)),
                              _infoTile('Security Deposit', CurrencyFormatter.format(student.securityDeposit)),
                              _infoTile('Current Month Rent', student.currentRentStatus ?? (student.isActive ? 'Pending' : 'N/A')),
                              if (student.currentRentRemaining != null)
                                _infoTile('Remaining Rent Due', CurrencyFormatter.format(student.currentRentRemaining!)),
                            ]),
                            const Divider(height: 24),
                            _buildSectionHeader('Personal & Contact Info'),
                            _buildInfoGrid([
                              _infoTile('Father / Guardian', student.fatherName),
                              _infoTile('CNIC / B-Form', student.cnic),
                              _infoTile('Phone Number', student.phone),
                              _infoTile('Emergency Contact', student.emergencyContact),
                              _infoTile('Permanent Address', student.address),
                            ]),
                            const Divider(height: 24),
                            _buildSectionHeader('Academic Details'),
                            _buildInfoGrid([
                              _infoTile('University / College', student.university),
                              _infoTile('Department / Major', student.department),
                              _infoTile('Semester', student.semester),
                            ]),
                            if (student.notes != null && student.notes!.isNotEmpty) ...[
                              const Divider(height: 24),
                              _buildSectionHeader('Notes / Remarks'),
                              Text(student.notes!, style: AppStyles.bodyMedium),
                            ],
                          ],
                        ),
                      ),

                      // Tab 2: Allocation History Timeline
                      Obx(() {
                        if (controller.isLoadingHistory.value) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (controller.studentAllocationHistory.isEmpty) {
                          return const Center(child: Text('No historical allocations recorded.'));
                        }
                        return ListView.separated(
                          primary: false,
                          itemCount: controller.studentAllocationHistory.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, idx) {
                            final alloc = controller.studentAllocationHistory[idx];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: alloc.isCurrent ? AppColors.successBg : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  alloc.isCurrent ? Icons.meeting_room_rounded : Icons.history_rounded,
                                  color: alloc.isCurrent ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                              title: Text(
                                'Room ${alloc.roomNumber} - ${alloc.bedNumber}',
                                style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'From ${DateFormatter.formatDate(DateTime.tryParse(alloc.startDate))} ${alloc.endDate != null ? 'to ${DateFormatter.formatDate(DateTime.tryParse(alloc.endDate!))}' : '(Current)'}\nReason: ${alloc.reason}${alloc.notes != null ? ' - ${alloc.notes}' : ''}',
                                style: AppStyles.caption,
                              ),
                              trailing: alloc.isCurrent ? const StatusBadge(status: 'Current') : const StatusBadge(status: 'Past'),
                            );
                          },
                        );
                      }),

                      // Tab 3: Payment Records
                      Obx(() {
                        if (controller.isLoadingHistory.value) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (controller.studentPaymentHistory.isEmpty) {
                          return const Center(child: Text('No payment records found for this student.'));
                        }
                        return ListView.separated(
                          primary: false,
                          itemCount: controller.studentPaymentHistory.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, idx) {
                            final payment = controller.studentPaymentHistory[idx];
                            return ListTile(
                              leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                              title: Text(
                                'Receipt: ${payment.receiptNumber}',
                                style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'Date: ${DateFormatter.formatDate(DateTime.tryParse(payment.paymentDate))} • Method: ${payment.paymentMethod}',
                                style: AppStyles.caption,
                              ),
                              trailing: Text(
                                CurrencyFormatter.format(payment.amount),
                                style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.success),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
),
);
  }

  void _showRoomTransferDialog(StudentModel student) {
    if (!student.isActive) {
      Get.snackbar('Notice', 'Cannot transfer an inactive/left student.');
      return;
    }

    controller.loadAvailableRoomsForTransfer();
    final selectedRoom = Rx<RoomModel?>(null);
    final selectedBed = Rx<BedModel?>(null);
    final reasonCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormatter.toIsoDate(DateTime.now()));

    CustomDialog.show(
      title: 'Change Room for ${student.fullName}',
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Current: Room ${student.roomNumber ?? '-'} / ${student.bedNumber ?? '-'}. Moving to a new room will automatically free the old bed and record historical timeline.',
                    style: AppStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Destination Room *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<RoomModel>(
            initialValue: selectedRoom.value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            hint: const Text('Choose available room'),
            items: controller.availableRooms.map((r) {
              return DropdownMenuItem(
                value: r,
                child: Text('Room ${r.roomNumber} (${r.availableBedsCount} beds free) - ${r.block}'),
              );
            }).toList(),
            onChanged: (room) {
              if (room != null) {
                selectedRoom.value = room;
                selectedBed.value = null;
                controller.loadAvailableBedsForRoom(room.id!);
              }
            },
          ),
          const SizedBox(height: 14),
          if (selectedRoom.value != null) ...[
            Text('Select Destination Bed *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<BedModel>(
              initialValue: selectedBed.value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: const Text('Choose available bed'),
              items: controller.availableBedsForTransfer.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text('${b.bedNumber} (Available)'),
                );
              }).toList(),
              onChanged: (b) => selectedBed.value = b,
            ),
            const SizedBox(height: 14),
          ],
          CustomTextField(
            label: 'Transfer Effective Date (YYYY-MM-DD)',
            controller: dateCtrl,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Reason for Transfer',
            hint: 'e.g. Student requested ground floor, management change',
            controller: reasonCtrl,
          ),
        ],
      )),
      actions: [
        CustomButton(
          text: 'Cancel',
          type: ButtonType.secondary,
          onPressed: () {
            if (Get.isDialogOpen == true) Get.back();
          },
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Confirm Room Transfer',
          onPressed: () {
            if (selectedRoom.value == null || selectedBed.value == null) {
              Get.snackbar('Validation', 'Please select both destination room and bed.');
              return;
            }
            controller.transferRoom(
              studentId: student.id!,
              newRoomId: selectedRoom.value!.id!,
              newBedId: selectedBed.value!.id!,
              transferDate: dateCtrl.text,
              reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Transferred by management',
            );
          },
        ),
      ],
    );
  }

  Future<void> _showLeaveStudentDialog(StudentModel student) async {
    if (!student.isActive) {
      Get.snackbar('Notice', 'Student has already left.');
      return;
    }

    final reasonCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormatter.toIsoDate(DateTime.now()));
    final pendingRent = await controller.getStudentPendingRent(student.id!);
    final securityDeposit = student.securityDeposit;

    // Default adjust is min(security, pendingRent)
    final defaultAdjust = securityDeposit >= pendingRent ? pendingRent : securityDeposit;
    final defaultRefund = (securityDeposit - defaultAdjust).clamp(0.0, double.infinity);

    final adjustCtrl = TextEditingController();
    final refundCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    CustomDialog.show(
      title: 'Departure & Security Settlement: ${student.fullName}',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Rent & Security Overview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Student Rent & Security Overview',
                        style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Rent Package:', style: AppStyles.caption),
                      Text(CurrencyFormatter.format(student.monthlyRent), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Security Deposit Received / Available:', style: AppStyles.caption),
                      Text(
                        CurrencyFormatter.format(securityDeposit),
                        style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Unpaid / Pending Rent Dues:', style: AppStyles.caption),
                      Text(
                        CurrencyFormatter.format(pendingRent),
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: pendingRent > 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Settlement Balance:', style: AppStyles.caption),
                      Text(
                        (securityDeposit - pendingRent) >= 0
                            ? '+${CurrencyFormatter.format(securityDeposit - pendingRent)} (Refundable)'
                            : '-${CurrencyFormatter.format((pendingRent - securityDeposit))} (Deficit / Due)',
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: (securityDeposit - pendingRent) >= 0 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Leaving Date (YYYY-MM-DD) *',
                    controller: dateCtrl,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Reason for Leaving',
                    hint: 'e.g. Completed studies, Job relocation',
                    controller: reasonCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildSectionHeader('Security Settlement Options'),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Adjust Towards Rent (PKR)',
                    hint: defaultAdjust > 0 ? 'e.g. ${defaultAdjust.toStringAsFixed(0)}' : '0',
                    controller: adjustCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Refund to Student (PKR)',
                    hint: defaultRefund > 0 ? 'e.g. ${defaultRefund.toStringAsFixed(0)}' : '0',
                    controller: refundCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '• Leave blank to apply recommended settlement (${CurrencyFormatter.format(defaultAdjust)} adjust, ${CurrencyFormatter.format(defaultRefund)} refund).\n• Adjusted amount clears unpaid rent records.\n• Refunded amount marks security returned to student.',
              style: AppStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Settlement Notes / Remarks',
              hint: 'e.g. Room keys handed over, deposit refunded via cash',
              controller: notesCtrl,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        CustomButton(
          text: 'Cancel',
          type: ButtonType.secondary,
          onPressed: () {
            if (Get.isDialogOpen == true) Get.back();
          },
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Confirm Departure & Settle',
          type: ButtonType.danger,
          onPressed: () {
            final adjustVal = adjustCtrl.text.trim().isNotEmpty
                ? (double.tryParse(adjustCtrl.text.trim()) ?? 0.0)
                : defaultAdjust;
            final refundVal = refundCtrl.text.trim().isNotEmpty
                ? (double.tryParse(refundCtrl.text.trim()) ?? 0.0)
                : defaultRefund;

            if (adjustVal + refundVal > securityDeposit) {
              Get.snackbar(
                'Invalid Settlement',
                'Adjusted + Refunded total (Rs. ${adjustVal + refundVal}) cannot exceed available security (Rs. $securityDeposit).',
              );
              return;
            }

            final reasonVal = reasonCtrl.text.trim().isNotEmpty
                ? reasonCtrl.text.trim()
                : 'Completed studies';

            controller.markStudentAsLeft(
              studentId: student.id!,
              leavingDate: dateCtrl.text,
              reason: reasonVal,
              adjustSecurityToRent: adjustVal,
              refundSecurityAmount: refundVal,
              settlementNotes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
            );
          },
        ),
      ],
    );
  }

  void _showEditStudentDialog(StudentModel student) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: student.fullName);
    final fatherCtrl = TextEditingController(text: student.fatherName);
    final cnicCtrl = TextEditingController(text: student.cnic);
    final phoneCtrl = TextEditingController(text: student.phone);
    final emergencyCtrl = TextEditingController(text: student.emergencyContact);
    final addressCtrl = TextEditingController(text: student.address);
    final uniCtrl = TextEditingController(text: student.university);
    final deptCtrl = TextEditingController(text: student.department);
    final semCtrl = TextEditingController(text: student.semester);
    final rentCtrl = TextEditingController(text: student.monthlyRent.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: student.notes ?? '');

    CustomDialog.show(
      title: 'Edit Student Details',
      width: 650,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Full Name *',
                    controller: nameCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Father / Guardian Name',
                    controller: fatherCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'CNIC / B-Form',
                    hint: '35202-xxxxxxx-x',
                    controller: cnicCtrl,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Phone Number *',
                    hint: '03001234567',
                    controller: phoneCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Emergency Contact Phone',
                    controller: emergencyCtrl,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Monthly Rent (PKR) *',
                    controller: rentCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Valid rent required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'University / Institute',
                    controller: uniCtrl,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Department',
                    controller: deptCtrl,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Semester',
                    controller: semCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Permanent Address',
              controller: addressCtrl,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Notes / Remarks',
              controller: notesCtrl,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        CustomButton(
          text: 'Cancel',
          type: ButtonType.secondary,
          onPressed: () {
            if (Get.isDialogOpen == true) Get.back();
          },
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Save Changes',
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final updated = student.copyWith(
                fullName: nameCtrl.text,
                fatherName: fatherCtrl.text,
                cnic: cnicCtrl.text,
                phone: phoneCtrl.text,
                emergencyContact: emergencyCtrl.text,
                address: addressCtrl.text,
                university: uniCtrl.text,
                department: deptCtrl.text,
                semester: semCtrl.text,
                monthlyRent: double.tryParse(rentCtrl.text) ?? 0.0,
                notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
              );
              controller.updateStudent(updated);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = Get.find<MainLayoutController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            ResponsiveHeader(
              title: 'Student Directory',
              subtitle: 'Manage registered students, room allocations, transfers, and historical records',
              actions: [
                CustomButton(
                  text: 'Admit New Student',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => layout.setNavIndex(3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Filter Controls
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final searchInput = TextField(
                  onChanged: (val) {
                    controller.searchQuery.value = val;
                    controller.fetchStudents();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by student name, ID code, phone, CNIC, or room number...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );

                final statusDropdown = Obx(() => DropdownButton<String>(
                  value: controller.statusFilter.value,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Students')),
                    DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                    DropdownMenuItem(value: 'Left', child: Text('Left / Archived')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.statusFilter.value = v;
                      controller.fetchStudents();
                    }
                  },
                ));

                return Container(
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
                            Align(alignment: Alignment.centerLeft, child: statusDropdown),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 16),
                            statusDropdown,
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Students Data Table
            Expanded(
              child: Obx(() {
                final studentList = controller.students;

                final List<List<Widget>> tableRows = studentList.map((s) {
                  return [
                    Text(s.studentIdCode, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.fullName, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text(s.university, style: AppStyles.caption),
                      ],
                    ),
                    Text(s.phone, style: AppStyles.bodySmall),
                    Text(s.roomNumber != null ? 'Room ${s.roomNumber}' : '-', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    Text(s.bedNumber ?? '-', style: AppStyles.bodySmall),
                    Text(CurrencyFormatter.format(s.monthlyRent), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    Text(CurrencyFormatter.format(s.securityDeposit), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge(status: s.currentRentStatus ?? (s.isActive ? 'Pending' : 'N/A')),
                        if (s.currentRentRemaining != null && s.currentRentRemaining! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Due: ${CurrencyFormatter.format(s.currentRentRemaining!)}',
                              style: AppStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    StatusBadge(status: s.status),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                          tooltip: 'View Profile & History',
                          onPressed: () => _showStudentDetailsDialog(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Edit Details',
                          onPressed: () => _showEditStudentDialog(s),
                        ),
                        if (s.isActive) ...[
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.accent),
                            tooltip: 'Transfer Room / Bed',
                            onPressed: () => _showRoomTransferDialog(s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.warning),
                            tooltip: 'Mark as Left (Archive)',
                            onPressed: () => _showLeaveStudentDialog(s),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          tooltip: 'Delete Student',
                          onPressed: () async {
                            final confirmed = await CustomDialog.showConfirm(
                              title: 'Delete Student Record?',
                              message: 'Are you sure you want to permanently delete "${s.fullName}" (${s.studentIdCode})? This will release their bed and remove student records.',
                              confirmText: 'Yes, Delete Student',
                              confirmButtonType: ButtonType.danger,
                            );
                            if (confirmed) {
                              controller.deleteStudent(s);
                            }
                          },
                        ),
                      ],
                    ),
                  ];
                }).toList();

                return DataTableWidget(
                  isLoading: controller.isLoading.value,
                  columns: const [
                    TableColumnDef(title: 'Student ID'),
                    TableColumnDef(title: 'Full Name'),
                    TableColumnDef(title: 'Phone'),
                    TableColumnDef(title: 'Room'),
                    TableColumnDef(title: 'Bed'),
                    TableColumnDef(title: 'Monthly Rent'),
                    TableColumnDef(title: 'Security Deposit'),
                    TableColumnDef(title: 'Rent Status'),
                    TableColumnDef(title: 'Status'),
                    TableColumnDef(title: 'Actions', alignment: Alignment.center),
                  ],
                  rows: tableRows,
                  emptyTitle: 'No Students Found',
                  emptySubtitle: 'No student records match the given query or filter.',
                  emptyActionText: 'Admit Student',
                  onEmptyAction: () => layout.setNavIndex(3),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: children,
    );
  }

  Widget _infoTile(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 2),
          Text(value.isNotEmpty ? value : '-', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
