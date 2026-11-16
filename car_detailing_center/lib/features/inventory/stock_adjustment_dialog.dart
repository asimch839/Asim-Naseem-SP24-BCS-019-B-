import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final InventoryItemModel item;
  final bool isAdding; // true for + Add Quantity, false for - Remove Quantity

  const StockAdjustmentDialog({
    super.key,
    required this.item,
    required this.isAdding,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryRepo = InventoryRepository();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _vendorRefController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reasonController.text = widget.isAdding ? 'Restock / Purchase Arrival' : 'Used in Detailing Job';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _vendorRefController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      Get.snackbar('Invalid Quantity', 'Please enter a quantity greater than 0', backgroundColor: AppColors.warning.withValues(alpha: 0.2));
      return;
    }

    if (!widget.isAdding && qty > widget.item.currentQuantity) {
      Get.snackbar('Insufficient Stock', 'Cannot deduct $qty ${widget.item.unit}. Current stock is only ${widget.item.currentQuantity} ${widget.item.unit}', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    final changeAmount = widget.isAdding ? qty : -qty;

    setState(() => _isSaving = true);
    final currentUser = AuthService.to.currentUser.value;

    try {
      await _inventoryRepo.adjustStock(
        itemId: widget.item.id,
        changeAmount: changeAmount,
        transactionType: widget.isAdding ? 'Purchase / Addition' : 'Job Usage / Deduction',
        reasonNotes: _reasonController.text.trim(),
        userName: currentUser?.fullName ?? 'Manager',
        vendorReference: _vendorRefController.text.trim().isNotEmpty ? _vendorRefController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      Get.snackbar(
        'Stock Updated',
        '${widget.item.name} quantity successfully updated',
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
    final title = widget.isAdding ? '+ Add Quantity' : '- Remove Quantity';
    final actionColor = widget.isAdding ? AppColors.success : AppColors.error;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                      widget.isAdding ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                      color: actionColor,
                      size: 20,
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
                          widget.item.name,
                          style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
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

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Available Stock:', style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary)),
                            Text(
                              '${widget.item.currentQuantity.toStringAsFixed(1)} ${widget.item.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: widget.isAdding ? 'Quantity to Add *' : 'Quantity to Remove *',
                          suffixText: widget.item.unit,
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
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason / Purpose *',
                          hintText: 'e.g. Received new shipment or used for ceramic coat',
                          prefixIcon: Icon(Icons.comment_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter reason' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _vendorRefController,
                        decoration: const InputDecoration(
                          labelText: 'Optional Vendor / Invoice Reference',
                          hintText: 'e.g. PO-9812 or Vendor invoice #',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
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
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.isAdding ? '+ Add Stock' : '- Deduct Stock'),
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
