import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/garage_expense_repository.dart';
import '../../data/repositories/staff_repository.dart';
import '../dashboard/dashboard_controller.dart';

class GarageExpenseScreen extends StatefulWidget {
  const GarageExpenseScreen({super.key});

  @override
  State<GarageExpenseScreen> createState() => _GarageExpenseScreenState();
}

class _GarageExpenseScreenState extends State<GarageExpenseScreen> {
  final _expenseRepo = GarageExpenseRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  String _searchQuery = '';
  String _vendorQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      await StaffRepository().syncStaffPaymentsToExpenses();
    } catch (_) {}
    final cats = await _expenseRepo.getUniqueCategories();
    if (mounted) {
      setState(() {
        _categories = ['All', ...cats];
      });
    }
  }

  void _openExpenseDialog([ExpenseModel? existing]) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => GarageExpenseFormDialog(existing: existing),
    );
    if (res == true && mounted) {
      _loadCategories();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return AppScaffold(
      currentRoute: AppRoutes.garageExpenses,
      title: 'Garage Expense',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Garage Expense'),
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 12 : 24),
        child: Column(
          children: [
            // Search & Filter Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search by category or notes...',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _vendorController,
                            decoration: const InputDecoration(
                              hintText: 'Filter by vendor...',
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                            onChanged: (val) => setState(() => _vendorQuery = val.trim()),
                          ),
                          if (_categories.length > 1) ...[
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedCategory,
                              underline: const SizedBox(),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search by category, description, or notes...',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _vendorController,
                            decoration: const InputDecoration(
                              hintText: 'Filter by vendor name or company...',
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                            onChanged: (val) => setState(() => _vendorQuery = val.trim()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_categories.length > 1)
                          DropdownButton<String>(
                            value: _selectedCategory,
                            underline: const SizedBox(),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expense List
            Expanded(
              child: FutureBuilder<List<ExpenseModel>>(
                future: _expenseRepo.getExpenses(
                  category: _selectedCategory != 'All' ? _selectedCategory : null,
                  vendorQuery: _vendorQuery.isNotEmpty ? _vendorQuery : null,
                  searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(message: 'Loading garage expenses...');
                  }

                  final list = snapshot.data ?? [];
                  final totalAmount = list.fold<double>(0.0, (acc, item) => acc + item.amount);

                  if (list.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Garage Expenses Found',
                      description: 'Log center operating expenses such as rent, utility bills, machine maintenance, or cleaning supplies.',
                      actionLabel: 'Add Expense',
                      onAction: () => _openExpenseDialog(),
                    );
                  }

                  return Column(
                    children: [
                      // Financial total banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text('Found ${list.length} expense records', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Total: ', style: TextStyle(color: AppColors.textDarkSecondary)),
                                Text(
                                  Formatters.currency(totalAmount, symbol: currency),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final exp = list[index];
                              final isStaff = (exp.category ?? '').toLowerCase().contains('staff');

                              return Card(
                      color: exp.isCompleted ? Colors.grey.shade200 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isStaff ? AppColors.warning.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                          child: Icon(
                            isStaff ? Icons.badge_outlined : Icons.receipt_long_rounded,
                            color: isStaff ? AppColors.warning : AppColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(exp.category ?? exp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (exp.vendorName != null && exp.vendorName!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isStaff ? AppColors.warning.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isStaff
                                        ? 'Staff: ${exp.vendorName}'
                                        : 'Vendor: ${exp.vendorName}${exp.vendorCompany != null && exp.vendorCompany!.isNotEmpty ? " (${exp.vendorCompany})" : ""}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isStaff ? AppColors.warning : AppColors.primaryLight,
                                      fontWeight: isStaff ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${Formatters.date(exp.date)} • Method: ${exp.paymentMethod} ${exp.referenceNumber != null && exp.referenceNumber!.isNotEmpty ? "• Ref: ${exp.referenceNumber}" : ""}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                            ),
                            if (exp.description.isNotEmpty)
                              Text(
                                exp.description,
                                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                            if (exp.notes != null && exp.notes!.isNotEmpty)
                              Text(
                                'Notes: ${exp.notes}',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textDarkSecondary),
                              ),
                            if (exp.staffName != null && exp.staffName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Technician: ${exp.staffName}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.info),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.currency(exp.amount, symbol: currency),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _openExpenseDialog(exp),
                            ),
                            if (!exp.isCompleted)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                tooltip: 'Mark as completed',
                                onPressed: () async {
                                  await _expenseRepo.markCompleted(exp.id);
                                  setState(() {});
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Delete Expense Record'),
                                    content: Text('Are you sure you want to delete this expense of ${Formatters.currency(exp.amount, symbol: currency)}?'),
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
                                  await _expenseRepo.deleteExpense(exp.id);
                                  _loadCategories();
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GarageExpenseFormDialog extends StatefulWidget {
  final ExpenseModel? existing;
  final String? prefillVendorName;
  final String? prefillVendorCompany;
  final String? prefillVendorPhone;
  final String? prefillVendorAddress;

  const GarageExpenseFormDialog({
    super.key,
    this.existing,
    this.prefillVendorName,
    this.prefillVendorCompany,
    this.prefillVendorPhone,
    this.prefillVendorAddress,
  });

  @override
  State<GarageExpenseFormDialog> createState() => _GarageExpenseFormDialogState();
}

class _GarageExpenseFormDialogState extends State<GarageExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _expenseRepo = GarageExpenseRepository();

  late final TextEditingController _categoryController;
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'Cash';
  String? _receiptPath;
  bool _isUploading = false;
  bool _isSaving = false;

  final List<String> _paymentMethods = ['Cash', 'Bank Transfer', 'Online', 'Card', 'Cheque', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _categoryController = TextEditingController(text: e?.category ?? e?.name ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _amountController = TextEditingController(text: e != null ? e.amount.toStringAsFixed(0) : '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _selectedDate = e.date;
      _paymentMethod = e.paymentMethod;
      _receiptPath = e.receiptUrl;
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
        fileName: 'garage_receipt_${const Uuid().v4()}.$ext',
        subfolder: 'receipts',
      );
      setState(() => _receiptPath = savedPath);
      Get.snackbar('Attached', 'Receipt saved locally', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to attach receipt: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid expense amount', backgroundColor: AppColors.warning.withValues(alpha: 0.2));
      return;
    }

    setState(() => _isSaving = true);
    final id = widget.existing?.id ?? 'gexp_${const Uuid().v4().substring(0, 8)}';

    final model = ExpenseModel(
      id: id,
      businessId: 'local',
      expenseType: 'center',
      name: _categoryController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : _categoryController.text.trim(),
      amount: amount,
      date: _selectedDate,
      paymentMethod: _paymentMethod,
      vendorName: null,
      vendorCompany: null,
      vendorPhone: null,
      vendorAddress: null,
      referenceNumber: null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      receiptUrl: _receiptPath,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      await _expenseRepo.saveExpense(model);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshData();
      }
      Get.back(result: true);
      Get.snackbar('Saved', 'Garage expense saved successfully', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save expense: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Garage Expense' : 'Edit Garage Expense',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category (User types category freely per Section 14)
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category * (e.g., Rent, Utilities, Machinery, Polish Pads, Water)',
                    hintText: 'Type expense category freely',
                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a category' : null,
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Description of the item/service purchased',
                    prefixIcon: Icon(Icons.description_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Amount & Date
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

                // Payment Method
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.credit_card_rounded, size: 20),
                  ),
                  items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional remarks...',
                    prefixIcon: Icon(Icons.note_alt_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Receipt Upload
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickReceipt,
                      icon: _isUploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(_receiptPath != null ? 'Replace Receipt' : 'Upload Receipt Photo'),
                    ),
                    if (_receiptPath != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 4),
                          const Text('Receipt attached', style: TextStyle(fontSize: 12, color: AppColors.success)),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                            onPressed: () => setState(() => _receiptPath = null),
                            tooltip: 'Remove Receipt',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Expense'),
        ),
      ],
    );
  }
}
