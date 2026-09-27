import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/date_range_picker_widget.dart';
import '../../widgets/data_table_widget.dart';
import '../../core/utils/responsive.dart';
import 'expense_controller.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({super.key});

  void _showExpenseFormDialog([ExpenseModel? exp]) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: exp?.title ?? '');
    final selectedCategory = (exp?.category ?? 'Electricity').obs;
    final amountCtrl = TextEditingController(text: exp != null ? exp.amount.toStringAsFixed(0) : '');
    final dateCtrl = TextEditingController(text: exp?.expenseDate ?? DateFormatter.toIsoDate(DateTime.now()));
    final selectedMethod = (exp?.paymentMethod ?? 'Cash').obs;
    final descCtrl = TextEditingController(text: exp?.description ?? '');
    final notesCtrl = TextEditingController(text: exp?.notes ?? '');

    CustomDialog.show(
      title: exp == null ? 'Record New Expense' : 'Edit Expense',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Expense Title *',
              hint: 'e.g. Electricity Bill August 2026',
              controller: titleCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory.value,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: AppStrings.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) {
                          if (v != null) selectedCategory.value = v;
                        },
                      ),
                    ],
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CustomTextField(
                    label: 'Amount (PKR) *',
                    hint: 'e.g. 45000',
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p <= 0) return 'Valid amount required';
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
                    label: 'Expense Date (YYYY-MM-DD) *',
                    controller: dateCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Obx(() => Column(
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
                          AppStrings.paymentMethodOther,
                        ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) {
                          if (v != null) selectedMethod.value = v;
                        },
                      ),
                    ],
                  )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Description / Invoice Ref',
              hint: 'e.g. LESCO Bill # 1234567890',
              controller: descCtrl,
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
          text: exp == null ? 'Save Expense' : 'Update Expense',
          onPressed: () {
            if (formKey.currentState!.validate()) {
              controller.saveExpense(
                id: exp?.id,
                title: titleCtrl.text,
                category: selectedCategory.value,
                amount: double.tryParse(amountCtrl.text) ?? 0.0,
                expenseDate: dateCtrl.text,
                paymentMethod: selectedMethod.value,
                description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
              );
            }
          },
        ),
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
              title: 'Expense Management',
              subtitle: 'Track hostel bills, utilities, staff payroll, and daily operational expenditures',
              actions: [
                DateRangePickerWidget(
                  initialFrom: controller.fromDate,
                  initialTo: controller.toDate,
                  onRangeChanged: controller.updateDateRange,
                ),
                CustomButton(
                  text: 'Add New Expense',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () => _showExpenseFormDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Summary Chips with Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                return Obx(() {
                  final totalSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Expenses (${controller.dateLabel.value})', style: AppStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(controller.totalExpensesSum.value),
                        style: AppStyles.h2.copyWith(color: AppColors.danger),
                      ),
                    ],
                  );

                  final chipsSection = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: controller.categoryTotals.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(CurrencyFormatter.format(entry.value), style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppStyles.cardDecoration,
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              totalSection,
                              const SizedBox(height: 12),
                              chipsSection,
                            ],
                          )
                        : Row(
                            children: [
                              totalSection,
                              const SizedBox(width: 24),
                              Container(
                                height: 44,
                                width: 1,
                                color: AppColors.border,
                              ),
                              const SizedBox(width: 24),
                              Expanded(child: chipsSection),
                            ],
                          ),
                  );
                });
              },
            ),
            const SizedBox(height: 20),

            // Search and Category Filter with Responsive Stacking
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;
                final searchInput = TextField(
                  onChanged: (val) {
                    controller.searchQuery.value = val;
                    controller.fetchExpenses();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by expense title, description, or notes...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );

                final categoryDropdown = Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.categoryFilter.value,
                      isDense: true,
                      borderRadius: BorderRadius.circular(8),
                      dropdownColor: AppColors.surface,
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                        ...AppStrings.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          controller.categoryFilter.value = v;
                          controller.fetchExpenses();
                        }
                      },
                    ),
                  ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            searchInput,
                            const SizedBox(height: 10),
                            categoryDropdown,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 16),
                            categoryDropdown,
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Expense Table
            Obx(() {
              final list = controller.expenses;

                final List<List<Widget>> tableRows = list.map((exp) {
                  return [
                    Text(DateFormatter.formatDate(DateTime.tryParse(exp.expenseDate)), style: AppStyles.bodySmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(exp.title, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        if (exp.description != null) Text(exp.description!, style: AppStyles.caption),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(exp.category, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text(exp.paymentMethod, style: AppStyles.bodySmall),
                    Text(
                      CurrencyFormatter.format(exp.amount),
                      style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.danger),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          onPressed: () => _showExpenseFormDialog(exp),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () async {
                            final confirmed = await CustomDialog.showConfirm(
                              title: 'Delete Expense?',
                              message: 'Are you sure you want to delete "${exp.title}"?',
                            );
                            if (confirmed) {
                              controller.deleteExpense(exp);
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
                    TableColumnDef(title: 'Date'),
                    TableColumnDef(title: 'Title / Description'),
                    TableColumnDef(title: 'Category'),
                    TableColumnDef(title: 'Method'),
                    TableColumnDef(title: 'Amount'),
                    TableColumnDef(title: 'Action', alignment: Alignment.center),
                  ],
                  rows: tableRows,
                  emptyTitle: 'No Expenses Recorded',
                  emptySubtitle: 'No expenses match the current date filter or search query.',
                  emptyActionText: 'Record Expense',
                  onEmptyAction: () => _showExpenseFormDialog(),
                );
              }),
            ],
        ),
      );
    }
}
