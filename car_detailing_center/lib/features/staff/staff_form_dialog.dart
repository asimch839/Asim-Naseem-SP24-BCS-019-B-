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
  final bool isCommissionBased;
  const StaffFormDialog({super.key, this.staff, this.isCommissionBased = false});

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

  bool _isCommissionWorker = false;
  String _salaryType = AppConstants.salaryTypeMonthly;
  String _status = 'Active';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    final isComm = s?.salaryType == AppConstants.salaryTypeCommission || widget.isCommissionBased;
    _isCommissionWorker = isComm;
    _nameController = TextEditingController(text: s?.name ?? '');
    _fatherNameController = TextEditingController(text: s?.fatherName ?? '');
    _cnicController = TextEditingController(text: s?.cnic ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _designationController = TextEditingController(text: s?.designation ?? '');
    _baseSalaryController = TextEditingController(text: isComm ? '0' : (s != null && s.baseSalary > 0 ? s.baseSalary.toStringAsFixed(0) : ''));
    _commissionRateController = TextEditingController(text: s != null && s.commissionRate > 0 ? s.commissionRate.toStringAsFixed(0) : '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _salaryType = s?.salaryType ?? (isComm ? AppConstants.salaryTypeCommission : AppConstants.salaryTypeMonthly);
    _status = s?.status ?? 'Active';
  }

  void _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final businessId = AuthService.to.businessId;
    final id = widget.staff?.id ?? const Uuid().v4();

    final commRate = _isCommissionWorker ? (double.tryParse(_commissionRateController.text.trim()) ?? 70.0) : 0.0;
    final baseSal = _isCommissionWorker ? 0.0 : (double.tryParse(_baseSalaryController.text.trim()) ?? 0.0);

    final staff = StaffModel(
      id: id,
      businessId: businessId,
      name: _nameController.text.trim(),
      fatherName: _fatherNameController.text.trim().isNotEmpty ? _fatherNameController.text.trim() : null,
      cnic: _cnicController.text.trim().isNotEmpty ? _cnicController.text.trim() : null,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      designation: _designationController.text.trim(),
      baseSalary: baseSal,
      salaryType: _isCommissionWorker ? AppConstants.salaryTypeCommission : _salaryType,
      commissionRate: commRate,
      status: _status,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      joiningDate: widget.staff?.joiningDate ?? DateTime.now(),
      createdAt: widget.staff?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await StaffRepository().saveStaff(staff);
      Get.back(result: true);
      Get.snackbar(
        'Success',
        _isCommissionWorker ? 'Commission worker profile saved' : 'Staff member profile saved',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
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
                        widget.staff == null
                            ? (_isCommissionWorker ? 'Register New Commission Worker' : 'Register New Staff Member')
                            : (_isCommissionWorker ? 'Edit Commission Worker' : 'Edit Staff Profile'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Employment Type Switcher (Salaried Staff vs Commission Worker)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _isCommissionWorker = false;
                              _salaryType = AppConstants.salaryTypeMonthly;
                              if (_baseSalaryController.text == '0') {
                                _baseSalaryController.text = '';
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: !_isCommissionWorker ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: !_isCommissionWorker ? Border.all(color: AppColors.primaryLight) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.badge_rounded, size: 16, color: !_isCommissionWorker ? AppColors.primaryLight : AppColors.textDarkSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Salaried Staff',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isCommissionWorker ? FontWeight.bold : FontWeight.normal,
                                    color: !_isCommissionWorker ? Colors.white : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _isCommissionWorker = true;
                              _salaryType = AppConstants.salaryTypeCommission;
                              _baseSalaryController.text = '0';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _isCommissionWorker ? AppColors.success.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: _isCommissionWorker ? Border.all(color: AppColors.success) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.handshake_rounded, size: 16, color: _isCommissionWorker ? AppColors.success : AppColors.textDarkSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Commission Worker (Denter/Painter)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isCommissionWorker ? FontWeight.bold : FontWeight.normal,
                                    color: _isCommissionWorker ? Colors.white : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 480;

                    final nameField = TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _isCommissionWorker ? 'Worker Name *' : 'Full Name *',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: Validators.required,
                    );

                    final fatherNameField = TextFormField(
                      controller: _fatherNameController,
                      decoration: const InputDecoration(labelText: "Father's Name"),
                    );

                    final cnicField = TextFormField(
                      controller: _cnicController,
                      decoration: const InputDecoration(labelText: 'CNIC / National ID', hintText: 'e.g. 35201-xxxxxxx-x', prefixIcon: Icon(Icons.credit_card_rounded)),
                    );

                    final phoneField = TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Contact Phone *', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: Validators.phone,
                    );

                    final designationField = TextFormField(
                      controller: _designationController,
                      decoration: InputDecoration(
                        labelText: 'Designation / Skill *',
                        hintText: _isCommissionWorker ? 'e.g. Denter, Painter, Electrician' : 'e.g. Detailer, Polisher, PPF Expert',
                      ),
                      validator: Validators.required,
                    );

                    final salaryTypeField = DropdownButtonFormField<String>(
                      value: _salaryType == AppConstants.salaryTypeCommission ? AppConstants.salaryTypeMonthly : _salaryType,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Salary Frequency'),
                      items: [
                        AppConstants.salaryTypeMonthly,
                        AppConstants.salaryTypeDaily,
                        AppConstants.salaryTypeWeekly,
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _salaryType = val);
                      },
                    );

                    String salaryLabel;
                    String salaryHint;
                    IconData salaryIcon;

                    if (_salaryType == AppConstants.salaryTypeDaily) {
                      salaryLabel = 'Daily Wage / Amount (Rs.) *';
                      salaryHint = 'e.g. 1500';
                      salaryIcon = Icons.today_rounded;
                    } else if (_salaryType == AppConstants.salaryTypeWeekly) {
                      salaryLabel = 'Weekly Wage / Amount (Rs.) *';
                      salaryHint = 'e.g. 9000';
                      salaryIcon = Icons.date_range_rounded;
                    } else {
                      salaryLabel = 'Monthly Base Salary (Rs.) *';
                      salaryHint = 'e.g. 35000';
                      salaryIcon = Icons.payments_outlined;
                    }

                    final baseSalaryField = TextFormField(
                      controller: _baseSalaryController,
                      decoration: InputDecoration(
                        labelText: salaryLabel,
                        hintText: salaryHint,
                        prefixIcon: Icon(salaryIcon),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _isCommissionWorker ? null : Validators.nonNegativeNumber,
                    );

                    final commissionSection = TextFormField(
                      controller: _commissionRateController,
                      decoration: const InputDecoration(
                        labelText: 'Worker Commission Rate (%) *',
                        hintText: 'e.g. 70',
                        prefixIcon: Icon(Icons.percent_rounded),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (!_isCommissionWorker) return null;
                        final val = double.tryParse(v?.trim() ?? '');
                        if (val == null || val <= 0 || val > 100) return 'Enter valid % between 1 and 100';
                        return null;
                      },
                    );

                    if (isWide) {
                      return Column(
                        children: [
                          Row(children: [Expanded(child: nameField), const SizedBox(width: 12), Expanded(child: fatherNameField)]),
                          const SizedBox(height: 12),
                          Row(children: [Expanded(child: cnicField), const SizedBox(width: 12), Expanded(child: phoneField)]),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: designationField),
                              if (!_isCommissionWorker) ...[
                                const SizedBox(width: 12),
                                Expanded(child: salaryTypeField),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (!_isCommissionWorker)
                            baseSalaryField
                          else
                            commissionSection,
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          nameField,
                          const SizedBox(height: 10),
                          fatherNameField,
                          const SizedBox(height: 10),
                          cnicField,
                          const SizedBox(height: 10),
                          phoneField,
                          const SizedBox(height: 10),
                          designationField,
                          const SizedBox(height: 10),
                          if (!_isCommissionWorker) ...[
                            salaryTypeField,
                            const SizedBox(height: 10),
                            baseSalaryField,
                          ] else ...[
                            commissionSection,
                          ],
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.home_outlined)),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes / Guarantor Details'),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  ],
                ),
                const SizedBox(height: 20),

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
