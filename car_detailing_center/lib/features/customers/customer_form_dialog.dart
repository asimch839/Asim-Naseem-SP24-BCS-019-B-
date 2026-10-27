import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerFormDialog extends StatefulWidget {
  final CustomerModel? customer;
  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  String _status = 'Active';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.fullName ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
    _status = c?.status ?? 'Active';
  }

  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final id = widget.customer?.id ?? 'cust_${const Uuid().v4().substring(0, 8)}';

    final customer = CustomerModel(
      id: id,
      businessId: 'local',
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      status: _status,
      totalVisits: widget.customer?.totalVisits ?? 0,
      outstandingBalance: widget.customer?.outstandingBalance ?? 0.0,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final customerRepo = Get.find<CustomerRepository>();
      await customerRepo.saveCustomer(customer);

      Get.back(result: true);
      Get.snackbar('Success', 'Customer saved successfully in SQLite', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save customer: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.customer == null ? 'Register New Customer' : 'Edit Customer Profile',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Customer Full Name *', prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 380;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
                              validator: Validators.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.toggle_on_outlined)),
                              items: const [
                                DropdownMenuItem(value: 'Active', child: Text('Active')),
                                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
                            validator: Validators.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.toggle_on_outlined)),
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text('Active')),
                              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Customer Notes (Preferences, VIP, etc.)', prefixIcon: Icon(Icons.notes_rounded)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveCustomer,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.customer == null ? 'Register Customer' : 'Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
