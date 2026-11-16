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
  late final TextEditingController _sellingPriceController;
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
    _sellingPriceController = TextEditingController(text: it != null ? it.sellingPrice.toStringAsFixed(0) : '0');
    _descController = TextEditingController(text: it?.description ?? '');
    _notesController = TextEditingController(text: it?.notes ?? '');
    final pDate = it?.purchaseDate;
    if (pDate != null) {
      _purchaseDate = pDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? purchasePrice;

    try {
      await _inventoryRepo.saveItem(
        id: widget.item?.id,
        itemName: _nameController.text.trim(),
        currentQuantity: quantity,
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'Units',
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice > 0 ? sellingPrice : purchasePrice,
        purchaseDate: _purchaseDate,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
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
    final isMobile = MediaQuery.of(context).size.width < 560;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item == null ? 'Add Stock Item' : 'Edit Stock Item',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

            // 2. Form Body (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
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

                      // Brand & Unit
                      if (isMobile) ...[
                        TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            hintText: 'e.g., Meguiar\'s, Koch Chemie',
                            prefixIcon: Icon(Icons.branding_watermark_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                            hintText: 'e.g., Liters, Bottles, Pieces, Packs',
                            prefixIcon: Icon(Icons.straighten_rounded, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter unit' : null,
                        ),
                      ] else ...[
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
                                  hintText: 'e.g., Liters, Bottles, Pieces',
                                  prefixIcon: Icon(Icons.straighten_rounded, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Enter unit' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Current Quantity & Purchase Date
                      if (isMobile) ...[
                        TextFormField(
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
                        const SizedBox(height: 14),
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
                      ] else ...[
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
                              child: InkWell(
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
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Purchase Price & Selling Price
                      if (isMobile) ...[
                        TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price (Cost) *',
                            helperText: 'Khareed qeemat',
                            prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter price';
                            if (double.tryParse(v.trim()) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (Farokht) *',
                            helperText: 'Jis py customer ko bechna hai',
                            prefixIcon: Icon(Icons.point_of_sale_rounded, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter selling price';
                            if (double.tryParse(v.trim()) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _purchasePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Price (Cost) *',
                                  helperText: 'Khareed qeemat',
                                  prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter price';
                                  if (double.tryParse(v.trim()) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _sellingPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Selling Price (Farokht) *',
                                  helperText: 'Jis py bechna hai',
                                  prefixIcon: Icon(Icons.point_of_sale_rounded, size: 20),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter selling price';
                                  if (double.tryParse(v.trim()) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Expected Profit Margin Banner
                      Builder(
                        builder: (_) {
                          final buy = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
                          final sell = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
                          final diff = sell - buy;
                          final pct = buy > 0 ? (diff / buy) * 100 : 0.0;
                          final isProfit = diff >= 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: 16,
                                  color: isProfit ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isProfit
                                        ? 'Expected Profit Margin: +Rs. ${diff.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}% per unit)'
                                        : 'Notice: Selling below cost (-Rs. ${(-diff).toStringAsFixed(0)} per unit)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isProfit ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Specifications, application instructions...',
                          prefixIcon: Icon(Icons.description_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes
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

            // 3. Footer Actions
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
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.item == null ? 'Save Stock Item' : 'Update Item'),
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
