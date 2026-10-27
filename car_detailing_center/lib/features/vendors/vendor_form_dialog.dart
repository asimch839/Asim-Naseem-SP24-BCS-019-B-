import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vendor_model.dart';
import '../../data/repositories/vendor_repository.dart';

class VendorFormDialog extends StatefulWidget {
  final VendorModel? existing;

  const VendorFormDialog({super.key, this.existing});

  @override
  State<VendorFormDialog> createState() => _VendorFormDialogState();
}

class _VendorFormDialogState extends State<VendorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vendorRepo = Get.find<VendorRepository>();

  late final TextEditingController _personNameController;
  late final TextEditingController _shopNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _personNameController = TextEditingController(text: v?.name ?? '');
    _shopNameController = TextEditingController(text: v?.company ?? '');
    _phoneController = TextEditingController(text: v?.phone ?? '');
    _descriptionController = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final vendor = VendorModel(
        id: widget.existing?.id ?? '',
        businessId: 'local',
        name: _personNameController.text.trim(),
        company: _shopNameController.text.trim().isNotEmpty ? _shopNameController.text.trim() : null,
        phone: _phoneController.text.trim(),
        notes: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        createdAt: widget.existing?.createdAt,
      );

      await _vendorRepo.saveVendor(vendor);

      Get.back(result: true);
      Get.snackbar(
        'Success',
        widget.existing == null ? 'Vendor registered successfully' : 'Vendor details updated',
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save vendor: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        colorText: AppColors.error,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Vendor' : 'Add New Vendor',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Enter vendor contact and shop details',
                          style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(result: false),
                  ),
                ],
              ),
            ),

            // Form Body with strictly the 4 requested fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Person Name
                      TextFormField(
                        controller: _personNameController,
                        decoration: const InputDecoration(
                          labelText: 'Person Name *',
                          hintText: 'e.g. Muhammad Asim',
                          prefixIcon: Icon(Icons.person_rounded, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Person name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Shop Name
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name *',
                          hintText: 'e.g. Asim Auto Spare Parts & Chemicals',
                          prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Shop name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Phone Number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: 'e.g. 0300 1234567',
                          prefixIcon: Icon(Icons.phone_rounded, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g. Supplies car wash shampoos, microfibers, polishing pads and detailing tools',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.description_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isEditing ? 'Update Vendor' : 'Save Vendor'),
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
