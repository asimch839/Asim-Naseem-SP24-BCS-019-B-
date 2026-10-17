import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryFormDialog extends StatefulWidget {
  final InventoryItemModel? item;
  const InventoryFormDialog({super.key, this.item});

  @override
  State<InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryRepo = InventoryRepository();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _brandController;
  late final TextEditingController _unitController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _descController;
  late final TextEditingController _notesController;

  DateTime _purchaseDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _nameController = TextEditingController(text: it?.name ?? '');
    _quantityController = TextEditingController(text: it != null ? it.currentQuantity.toStringAsFixed(0) : '0');
    _brandController = TextEditingController(text: it?.brand ?? '');
    _unitController = TextEditingController(text: it?.unit ?? 'Units');
    _purchasePriceController = TextEditingController(text: it != null ? it.purchasePrice.toStringAsFixed(0) : '0');
    _descController = TextEditingController(text: it?.description ?? '');
    _notesController = TextEditingController(text: it?.notes ?? '');
    final pDate = it?.purchaseDate;
    if (pDate != null) {
      _purchaseDate = pDate;
    }
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final price = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;

    try {
      await _inventoryRepo.saveItem(
        id: widget.item?.id,
        itemName: _nameController.text.trim(),
        currentQuantity: quantity,
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'Units',
        purchasePrice: price,
        purchaseDate: _purchaseDate,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      Get.back(result: true);
      Get.snackbar(
        'Stock Item Saved',
        widget.item == null ? 'Registered ${_nameController.text.trim()}' : 'Updated ${_nameController.text.trim()}',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save item: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Stock Item' : 'Edit Stock Item'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Item Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., Meguiars Synthetic X-Press Spray Wax',
                    prefixIcon: Icon(Icons.inventory_2_rounded, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter item name' : null,
                ),
                const SizedBox(height: 14),

                // 2. Brand & Unit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          hintText: 'e.g., Meguiar\'s, Koch Chemie',
                          prefixIcon: Icon(Icons.branding_watermark_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          hintText: 'e.g., Liters, Bottles, Pieces, Packs',
                          prefixIcon: Icon(Icons.straighten_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter unit' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Current Quantity & Purchase Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Current Quantity *',
                          prefixIcon: Icon(Icons.format_list_numbered_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter quantity';
                          if (double.tryParse(v.trim()) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Purchase Price (Cost) *',
                          prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter price';
                          if (double.tryParse(v.trim()) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Purchase Date
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d != null) setState(() => _purchaseDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                    ),
                    child: Text(Formatters.date(_purchaseDate)),
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Specifications, application instructions...',
                    prefixIcon: Icon(Icons.description_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Storage shelf location, supplier notes...',
                    prefixIcon: Icon(Icons.note_alt_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveItem,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Stock Item'),
        ),
      ],
    );
  }
}
