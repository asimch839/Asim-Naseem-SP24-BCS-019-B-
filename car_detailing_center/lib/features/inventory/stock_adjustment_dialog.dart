import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/staff_repository.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final InventoryItemModel? item;
  final bool isAdding; // true for + Add Stock, false for - Remove / Issue to Staff

  const StockAdjustmentDialog({
    super.key,
    this.item,
    required this.isAdding,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryRepo = InventoryRepository();
  final _staffRepo = StaffRepository();
  final _jobRepo = JobRepository();

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _vendorRefController = TextEditingController();
  final TextEditingController _customStaffController = TextEditingController();
  final TextEditingController _customVehicleController = TextEditingController();

  List<InventoryItemModel> _availableItems = [];
  InventoryItemModel? _selectedItem;

  List<StaffModel> _staffList = [];
  String? _selectedStaffName;

  List<Map<String, dynamic>> _activeJobs = [];
  String? _selectedJobInfo; // e.g. "JC-00013 • Cultus 675" or "General Workshop"

  DateTime _selectedDateTime = DateTime.now();
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.item;
    _reasonController.text = widget.isAdding ? 'Restock / Purchase Arrival' : 'Car Detailing';
    _selectedJobInfo = 'General Workshop / Detailing';
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final items = await _inventoryRepo.getItems();
      final staff = await _staffRepo.getStaffList(activeOnly: true);
      final jobs = await _jobRepo.getJobs(status: 'Active');

      if (mounted) {
        setState(() {
          _availableItems = items;
          if (_selectedItem == null && items.isNotEmpty) {
            _selectedItem = items.first;
          } else if (_selectedItem != null) {
            // Re-match from fresh items if possible
            final match = items.firstWhereOrNull((i) => i.id == _selectedItem!.id);
            if (match != null) _selectedItem = match;
          }

          _staffList = staff;
          if (staff.isNotEmpty) {
            _selectedStaffName = staff.first.name;
          } else {
            _selectedStaffName = 'General Staff';
          }

          _activeJobs = jobs;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _vendorRefController.dispose();
    _customStaffController.dispose();
    _customVehicleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentItem = _selectedItem;
    if (currentItem == null) {
      Get.snackbar('Error', 'Please select a stock item', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      Get.snackbar('Invalid Quantity', 'Please enter a quantity greater than 0', backgroundColor: AppColors.warning.withValues(alpha: 0.2));
      return;
    }

    if (!widget.isAdding && qty > currentItem.currentQuantity) {
      Get.snackbar(
        'Insufficient Stock',
        'Cannot deduct $qty ${currentItem.unit}. Current available stock is only ${currentItem.currentQuantity} ${currentItem.unit}',
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
      );
      return;
    }

    final changeAmount = widget.isAdding ? qty : -qty;

    setState(() => _isSaving = true);

    try {
      final finalStaffName = _selectedStaffName == 'Other / Custom'
          ? (_customStaffController.text.trim().isNotEmpty ? _customStaffController.text.trim() : 'Staff Member')
          : (_selectedStaffName ?? 'Staff Member');

      final finalJobInfo = _selectedJobInfo == 'Custom Vehicle Reg #'
          ? (_customVehicleController.text.trim().isNotEmpty ? _customVehicleController.text.trim() : 'Custom Vehicle')
          : (_selectedJobInfo ?? 'General Workshop');

      final transactionType = widget.isAdding ? 'Purchase / Addition' : 'Staff / Job Usage';

      await _inventoryRepo.adjustStock(
        itemId: currentItem.id,
        changeAmount: changeAmount,
        transactionType: transactionType,
        reasonNotes: _reasonController.text.trim(),
        userName: widget.isAdding ? 'Manager' : finalStaffName,
        jobId: widget.isAdding ? '' : finalJobInfo,
        vendorReference: _vendorRefController.text.trim().isNotEmpty ? _vendorRefController.text.trim() : null,
        customDateTime: _selectedDateTime,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      Get.snackbar(
        widget.isAdding ? 'Stock Added' : 'Item Issued to Staff',
        widget.isAdding
            ? 'Added $qty ${currentItem.unit} of ${currentItem.name}'
            : 'Issued $qty ${currentItem.unit} to $finalStaffName for $finalJobInfo',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdding ? '+ Add Stock / Restock' : '- Issue Material to Staff / Job';
    final actionColor = widget.isAdding ? AppColors.success : AppColors.warning;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: _isLoadingData
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.cardDark,
                      border: Border(bottom: BorderSide(color: AppColors.borderDark)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.isAdding ? Icons.add_circle_outline_rounded : Icons.outbox_rounded,
                            color: actionColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                widget.isAdding
                                    ? 'Record vendor purchase arrival or inventory addition'
                                    : 'Record shampoo, microfibers, or consumables given to staff for car detailing',
                                style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDarkMuted),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ],
                    ),
                  ),

                  // 2. Form Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item Selector (if opened from item vs generic)
                            if (widget.item == null) ...[
                              DropdownButtonFormField<InventoryItemModel>(
                                value: _selectedItem,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Select Inventory Item *',
                                  prefixIcon: Icon(Icons.inventory_2_rounded, size: 20),
                                ),
                                items: _availableItems.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text('${item.name} (${item.currentQuantity.toStringAsFixed(1)} ${item.unit} in stock)'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedItem = val);
                                },
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Stock status pill
                            if (_selectedItem != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedItem!.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_selectedItem!.brand != null && _selectedItem!.brand!.isNotEmpty)
                                            Text(
                                              'Brand: ${_selectedItem!.brand}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Available Stock:', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                                        Text(
                                          '${_selectedItem!.currentQuantity.toStringAsFixed(1)} ${_selectedItem!.unit}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // Date & Time Picker
                            InkWell(
                              onTap: _pickDateTime,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.borderDark),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.cardDark,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryLight),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Date & Time of Issuance / Transaction', style: TextStyle(fontSize: 10, color: AppColors.textDarkSecondary)),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: AppColors.textDarkSecondary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // IF ISSUING / DEDUCTING: Staff & Vehicle selection
                            if (!widget.isAdding) ...[
                              // Staff Member Dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedStaffName,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Staff Member Who Took Item *',
                                  prefixIcon: Icon(Icons.person_rounded, size: 20),
                                  helperText: 'Select staff member who received the material',
                                ),
                                items: [
                                  ..._staffList.map((s) => DropdownMenuItem(
                                        value: s.name,
                                        child: Text('${s.name} (${s.designation})'),
                                      )),
                                  const DropdownMenuItem(
                                    value: 'Shop Lead',
                                    child: Text('Shop Lead / Supervisor'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'General Staff',
                                    child: Text('General Workshop Staff'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'Other / Custom',
                                    child: Text('Other / Custom Staff Name...'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStaffName = val);
                                },
                              ),
                              if (_selectedStaffName == 'Other / Custom') ...[
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _customStaffController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter Staff Member Name *',
                                    hintText: 'e.g. Tariq, Ali, Babar',
                                    prefixIcon: Icon(Icons.badge_rounded, size: 20),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter staff name' : null,
                                ),
                              ],
                              if (_selectedJobInfo == 'Custom Vehicle Reg #') ...[
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _customVehicleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter Vehicle Plate / Details *',
                                    hintText: 'e.g. Cultus 675 / Civic ABC-123',
                                    prefixIcon: Icon(Icons.tag_rounded, size: 20),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter vehicle plate' : null,
                                ),
                              ],
                              const SizedBox(height: 14),
                            ],

                            // Quantity to Add / Issue
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: widget.isAdding ? 'Quantity to Add / Restock *' : 'Quantity Issued / Taken *',
                                suffixText: _selectedItem?.unit ?? 'Unit',
                                prefixIcon: Icon(
                                  widget.isAdding ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                                  color: actionColor,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter quantity';
                                final parsed = double.tryParse(v.trim());
                                if (parsed == null || parsed <= 0) return 'Enter a valid quantity';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Reason / Purpose Free text
                            TextFormField(
                              controller: _reasonController,
                              decoration: InputDecoration(
                                labelText: widget.isAdding ? 'Reason / Purchase Note *' : 'Purpose / Notes *',
                                hintText: widget.isAdding ? 'e.g. New shipment from supplier' : 'e.g. Detailing & Interior cleaning',
                                prefixIcon: const Icon(Icons.comment_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter reason/purpose' : null,
                            ),

                            // Vendor reference (if adding)
                            if (widget.isAdding) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _vendorRefController,
                                decoration: const InputDecoration(
                                  labelText: 'Vendor / Bill Reference (Optional)',
                                  hintText: 'e.g. Supplier invoice # or PO-9812',
                                  prefixIcon: Icon(Icons.receipt_long_rounded),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Actions Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.cardDark,
                      border: Border(top: BorderSide(color: AppColors.borderDark)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(widget.isAdding ? Icons.add_circle_outline_rounded : Icons.check_circle_outline_rounded, size: 18),
                          label: Text(widget.isAdding ? '+ Add Stock' : 'Confirm Issue to Staff'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}