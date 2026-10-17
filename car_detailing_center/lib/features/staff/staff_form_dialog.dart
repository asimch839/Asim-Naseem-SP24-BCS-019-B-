import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/staff_repository.dart';
import '../../core/utils/validators.dart';
import '../../data/models/staff_model.dart';

class StaffFormDialog extends StatefulWidget {
  final StaffModel? staff;
  const StaffFormDialog({super.key, this.staff});

  @override
  State<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _cnicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _designationController;
  late final TextEditingController _baseSalaryController;
  late final TextEditingController _commissionRateController;
  late final TextEditingController _notesController;

  String _salaryType = AppConstants.salaryTypeMonthly;
  String _status = 'Active';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _nameController = TextEditingController(text: s?.name ?? '');
    _fatherNameController = TextEditingController(text: s?.fatherName ?? '');
    _cnicController = TextEditingController(text: s?.cnic ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _designationController = TextEditingController(text: s?.designation ?? 'Senior Detailer');
    _baseSalaryController = TextEditingController(text: s?.baseSalary.toStringAsFixed(0) ?? '35000');
    _commissionRateController = TextEditingController(text: s?.commissionRate.toString() ?? '0');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _salaryType = s?.salaryType ?? AppConstants.salaryTypeMonthly;
    _status = s?.status ?? 'Active';
  }

  void _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final businessId = AuthService.to.businessId;
    final id = widget.staff?.id ?? const Uuid().v4();

    final staff = StaffModel(
      id: id,
      businessId: businessId,
      name: _nameController.text.trim(),
      fatherName: _fatherNameController.text.trim().isNotEmpty ? _fatherNameController.text.trim() : null,
      cnic: _cnicController.text.trim().isNotEmpty ? _cnicController.text.trim() : null,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      designation: _designationController.text.trim(),
      baseSalary: double.tryParse(_baseSalaryController.text.trim()) ?? 0.0,
      salaryType: _salaryType,
      commissionRate: double.tryParse(_commissionRateController.text.trim()) ?? 0.0,
      status: _status,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      joiningDate: widget.staff?.joiningDate ?? DateTime.now(),
      createdAt: widget.staff?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await StaffRepository().saveStaff(staff);
      Get.back(result: true);
      Get.snackbar('Success', 'Staff member profile saved', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save staff member: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.staff == null ? 'Register New Staff Member' : 'Edit Staff Profile',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.badge_outlined)),
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fatherNameController,
                        decoration: const InputDecoration(labelText: "Father's Name"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cnicController,
                        decoration: const InputDecoration(labelText: 'CNIC / National ID', hintText: 'e.g. 35201-xxxxxxx-x', prefixIcon: Icon(Icons.credit_card_rounded)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Contact Phone *', prefixIcon: Icon(Icons.phone_outlined)),
                        validator: Validators.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _designationController,
                        decoration: const InputDecoration(labelText: 'Designation / Role *', hintText: 'Detailer, Polisher, PPF Expert'),
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _salaryType,
                        decoration: const InputDecoration(labelText: 'Salary Structure'),
                        items: AppConstants.salaryTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _salaryType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _baseSalaryController,
                        decoration: const InputDecoration(labelText: 'Base Salary *', prefixIcon: Icon(Icons.payments_outlined)),
                        keyboardType: TextInputType.number,
                        validator: Validators.nonNegativeNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _commissionRateController,
                        decoration: const InputDecoration(labelText: 'Commission Rate (%)', hintText: 'e.g. 5'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.home_outlined)),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes / Guarantor Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveStaff,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Staff Profile'),
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
