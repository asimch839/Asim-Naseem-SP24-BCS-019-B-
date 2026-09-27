import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/rent_record_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/data_table_widget.dart';
import '../../core/utils/responsive.dart';
import '../receipts/receipt_controller.dart';
import 'rent_controller.dart';

class RentView extends GetView<RentController> {
  const RentView({super.key});

  List<DropdownMenuItem<String>> _buildMonthFilterItems() {
    final now = DateTime.now();
    final currentIso = DateFormatter.toIsoMonth(now);
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'All', child: Text('All Billing Months')),
      DropdownMenuItem(value: currentIso, child: Text('This Month (${DateFormatter.formatMonthYear(now)})')),
    ];

    for (int i = 1; i <= 11; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      final iso = DateFormatter.toIsoMonth(d);
      items.add(DropdownMenuItem(
        value: iso,
        child: Text(DateFormatter.formatMonthYear(d)),
      ));
    }
    return items;
  }

  void _showGenerateBillsDialog() {
    final now = DateTime.now();
    final selectedMonth = DateFormatter.toIsoMonth(now).obs;

    CustomDialog.show(
      title: 'Generate Monthly Rent Bills',
      content: Column(
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
                    'This action scans all currently active students and creates their rent dues for the target billing month. Existing bills are preserved without duplication.',
                    style: AppStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Target Billing Month *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            initialValue: selectedMonth.value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: List.generate(12, (i) {
              final d = DateTime(now.year, now.month - 2 + i, 1);
              final iso = DateFormatter.toIsoMonth(d);
              return DropdownMenuItem(
                value: iso,
                child: Text(DateFormatter.formatMonthYear(d)),
              );
            }),
            onChanged: (v) {
              if (v != null) selectedMonth.value = v;
            },
          )),
        ],
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
        Obx(() => CustomButton(
          text: 'Generate Bills',
          icon: Icons.receipt_long_rounded,
          isLoading: controller.isGeneratingBills.value,
          onPressed: () {
            if (Get.isDialogOpen == true) Get.back();
            controller.generateBills(selectedMonth.value);
          },
        )),
      ],
    );
  }

  void _showRecordPaymentDialog(RentRecordModel rent) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: rent.remainingAmount.toStringAsFixed(0));
    final hasPendingSecurity = (rent.studentSecurityDeposit != null && rent.studentSecurityDeposit! > 0) &&
        (rent.paidAmount == 0 || rent.isPending);
    final initialSecurity = hasPendingSecurity ? (rent.studentSecurityDeposit ?? 0.0).toStringAsFixed(0) : '0';
    final securityAmountCtrl = TextEditingController(text: initialSecurity);
    final dateCtrl = TextEditingController(text: DateFormatter.toIsoDate(DateTime.now()));
    final selectedMethod = AppStrings.paymentMethodCash.obs;
    final notesCtrl = TextEditingController();
    final isProcessing = false.obs;

    // Reactive computation of total payable amount
    final rentAmountRx = (rent.remainingAmount).obs;
    final securityAmountRx = (double.tryParse(initialSecurity) ?? 0.0).obs;

    amountCtrl.addListener(() {
      rentAmountRx.value = double.tryParse(amountCtrl.text) ?? 0.0;
    });
    securityAmountCtrl.addListener(() {
      securityAmountRx.value = double.tryParse(securityAmountCtrl.text) ?? 0.0;
    });

    CustomDialog.show(
      title: 'Record Payment for ${rent.studentName}',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dues summary box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Billing Month:', style: AppStyles.caption),
                      Text(DateFormatter.formatMonthYearString(rent.rentMonth), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Rent Amount:', style: AppStyles.caption),
                      Text(CurrencyFormatter.format(rent.rentAmount), style: AppStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Already Paid:', style: AppStyles.caption),
                      Text(CurrencyFormatter.format(rent.paidAmount), style: AppStyles.bodySmall.copyWith(color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Security Deposit Available:', style: AppStyles.caption),
                      Text(
                        CurrencyFormatter.format(rent.studentSecurityDeposit ?? 0.0),
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: (rent.studentSecurityDeposit ?? 0.0) > 0 ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining Balance Due:', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        CurrencyFormatter.format(rent.remainingAmount),
                        style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.danger),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if ((rent.studentSecurityDeposit ?? 0.0) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.accent),
                  label: Text(
                    'Use Available Security Deposit (Max Rs. ${(rent.studentSecurityDeposit ?? 0.0) < rent.remainingAmount ? CurrencyFormatter.format(rent.studentSecurityDeposit ?? 0.0) : CurrencyFormatter.format(rent.remainingAmount)})',
                    style: AppStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    selectedMethod.value = AppStrings.paymentMethodSecurityDeposit;
                    final maxUsable = (rent.studentSecurityDeposit ?? 0.0) < rent.remainingAmount
                        ? (rent.studentSecurityDeposit ?? 0.0)
                        : rent.remainingAmount;
                    amountCtrl.text = maxUsable.toStringAsFixed(0);
                    securityAmountCtrl.text = '0';
                  },
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Rent Payment (PKR) *',
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p < 0) return 'Enter valid amount';
                      if (p > rent.remainingAmount) return 'Cannot exceed balance';
                      if (selectedMethod.value == AppStrings.paymentMethodSecurityDeposit) {
                        final available = rent.studentSecurityDeposit ?? 0.0;
                        if (p > available) return 'Exceeds available security ($available)';
                      }
                      final sec = double.tryParse(securityAmountCtrl.text) ?? 0.0;
                      if (p <= 0 && sec <= 0) return 'Enter rent or security amount';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Security Deposit (PKR)',
                    hint: '0 if not paying security',
                    controller: securityAmountCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final s = double.tryParse(v ?? '0');
                      if (s == null || s < 0) return 'Enter valid deposit';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Payment Date (YYYY-MM-DD) *',
                    controller: dateCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount Payable:', style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(rentAmountRx.value + securityAmountRx.value),
                          style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Method *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod.value,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    AppStrings.paymentMethodCash,
                    AppStrings.paymentMethodBank,
                    AppStrings.paymentMethodSecurityDeposit,
                    AppStrings.paymentMethodOther,
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {
                    if (v != null) selectedMethod.value = v;
                  },
                ),
              ],
            )),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Notes / Remarks',
              hint: 'e.g. Bank ref #, cash received by warden',
              controller: notesCtrl,
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
        Obx(() => CustomButton(
          text: 'Submit Payment & Receipt',
          icon: Icons.receipt_rounded,
          isLoading: isProcessing.value,
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              isProcessing.value = true;
              try {
                final rentAmt = double.tryParse(amountCtrl.text) ?? 0.0;
                final secAmt = double.tryParse(securityAmountCtrl.text) ?? 0.0;

                final receipt = await controller.recordPayment(
                  rentRecordId: rent.id!,
                  amount: rentAmt,
                  securityAmount: secAmt,
                  paymentDate: dateCtrl.text,
                  paymentMethod: selectedMethod.value,
                  notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                );
                
                // Safely close dialog before opening receipt preview
                if (Get.isDialogOpen == true) {
                  Get.back();
                }

                await Future.delayed(const Duration(milliseconds: 200));

                // Prompt preview of receipt
                if (Get.isRegistered<ReceiptController>()) {
                  Get.find<ReceiptController>().previewReceipt(receipt);
                }
              } catch (e) {
                Get.snackbar(
                  'Payment Error',
                  e.toString().replaceAll('Exception: ', ''),
                  snackPosition: SnackPosition.BOTTOM,
                );
              } finally {
                isProcessing.value = false;
              }
            }
          },
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header Bar
            ResponsiveHeader(
              title: 'Rent & Payment Management',
              subtitle: 'Manage monthly billing, record payments, calculate remaining balances, and issue receipts',
              actions: [
                CustomButton(
                  text: 'Overdue Dues',
                  icon: Icons.notifications_active_rounded,
                  type: ButtonType.outline,
                  onPressed: () {
                    controller.statusFilter.value = 'Overdue';
                    controller.fetchRentRecords();
                  },
                ),
                const SizedBox(width: 10),
                CustomButton(
                  text: 'Generate Monthly Bills',
                  icon: Icons.playlist_add_check_rounded,
                  onPressed: _showGenerateBillsDialog,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Filters Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final searchInput = TextField(
                  onChanged: (val) {
                    controller.searchQuery.value = val;
                    controller.fetchRentRecords();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by student name, ID code, or room number...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );

                final monthDropdown = Obx(() {
                  final monthItems = _buildMonthFilterItems();
                  final currentValue = monthItems.any((item) => item.value == controller.monthFilter.value)
                      ? controller.monthFilter.value
                      : 'All';
                  return DropdownButton<String>(
                    value: currentValue,
                    underline: const SizedBox.shrink(),
                    items: monthItems,
                    onChanged: (v) {
                      if (v != null) {
                        controller.monthFilter.value = v;
                        controller.fetchRentRecords();
                      }
                    },
                  );
                });

                final statusDropdown = Obx(() => DropdownButton<String>(
                  value: controller.statusFilter.value,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Payment Statuses')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.statusFilter.value = v;
                      controller.fetchRentRecords();
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            searchInput,
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                monthDropdown,
                                statusDropdown,
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 16),
                            monthDropdown,
                            const SizedBox(width: 16),
                            statusDropdown,
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Rent Records Data Table
            Obx(() {
              final list = controller.rentRecords;

                final List<List<Widget>> tableRows = list.map((r) {
                  return [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(r.studentName ?? '-', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text('${r.studentIdCode ?? '-'} • ${r.studentPhone ?? '-'}', style: AppStyles.caption),
                      ],
                    ),
                    Text('Room ${r.roomNumber ?? '-'}\n${r.bedNumber ?? '-'}', style: AppStyles.caption),
                    Text(DateFormatter.formatMonthYearString(r.rentMonth), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    Text(CurrencyFormatter.format(r.rentAmount), style: AppStyles.bodySmall),
                    Text(
                      CurrencyFormatter.format(r.studentSecurityDeposit ?? 0.0),
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: (r.studentSecurityDeposit ?? 0.0) > 0 ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                    Text(CurrencyFormatter.format(r.paidAmount), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.success)),
                    Text(
                      CurrencyFormatter.format(r.remainingAmount),
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: r.remainingAmount > 0 ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                    Text(DateFormatter.formatDate(DateTime.tryParse(r.dueDate)), style: AppStyles.caption),
                    StatusBadge(status: r.status),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (r.remainingAmount > 0) ...[
                          CustomButton(
                            text: 'Pay',
                            icon: Icons.payments_rounded,
                            height: 32,
                            onPressed: () => _showRecordPaymentDialog(r),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Send WhatsApp Rent Reminder',
                            child: InkWell(
                              onTap: () => controller.sendRentReminder(context, r),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.whatsappDark.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.whatsappDark.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_rounded, color: AppColors.whatsappDark, size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      'Remind',
                                      style: TextStyle(
                                        color: AppColors.whatsappDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                      ],
                    ),
                  ];
                }).toList();

                return DataTableWidget(
                  isLoading: controller.isLoading.value,
                  columns: const [
                    TableColumnDef(title: 'Student'),
                    TableColumnDef(title: 'Room/Bed'),
                    TableColumnDef(title: 'Month'),
                    TableColumnDef(title: 'Rent Amount'),
                    TableColumnDef(title: 'Security Deposit'),
                    TableColumnDef(title: 'Paid'),
                    TableColumnDef(title: 'Remaining'),
                    TableColumnDef(title: 'Due Date'),
                    TableColumnDef(title: 'Status'),
                    TableColumnDef(title: 'Action', alignment: Alignment.center),
                  ],
                  rows: tableRows,
                  emptyTitle: 'No Rent Records Found',
                  emptySubtitle: 'Generate monthly bills for your active students or adjust filter criteria.',
                  emptyActionText: 'Generate Rent Bills',
                  onEmptyAction: _showGenerateBillsDialog,
                );
              }),
            ],
          ),
        );
    }
}
