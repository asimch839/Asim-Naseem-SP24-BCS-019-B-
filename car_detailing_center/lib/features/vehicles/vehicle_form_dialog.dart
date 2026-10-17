import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/vehicle_repository.dart';

class VehicleFormDialog extends StatefulWidget {
  final VehicleModel? vehicle;
  final String? preselectedCustomerId;
  final String? preselectedCustomerName;

  const VehicleFormDialog({
    super.key,
    this.vehicle,
    this.preselectedCustomerId,
    this.preselectedCustomerName,
  });

  @override
  State<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _regNumberController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late final TextEditingController _mileageController;
  late final TextEditingController _notesController;

  String? _selectedCustomerId;
  bool _isSaving = false;
  List<CustomerModel> _customers = [];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _regNumberController = TextEditingController(text: v?.registrationNumber ?? '');
    _makeController = TextEditingController(text: v?.make ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(text: v?.year?.toString() ?? '');
    _colorController = TextEditingController(text: v?.color ?? '');
    _mileageController = TextEditingController(text: v?.mileage?.toString() ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
    _selectedCustomerId = v?.customerId ?? widget.preselectedCustomerId;

    _loadCustomers();
  }

  void _loadCustomers() async {
    final customerRepo = Get.find<CustomerRepository>();
    final list = await customerRepo.getCustomers();
    if (mounted) {
      setState(() {
        _customers = list;
        if (_selectedCustomerId == null && list.isNotEmpty) {
          _selectedCustomerId = list.first.id;
        }
      });
    }
  }

  void _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      Get.snackbar('Error', 'Please select the vehicle owner / customer', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    setState(() => _isSaving = true);
    final id = widget.vehicle?.id ?? 'veh_${const Uuid().v4().substring(0, 8)}';

    final vehicle = VehicleModel(
      id: id,
      businessId: 'local',
      customerId: _selectedCustomerId!,
      registrationNumber: _regNumberController.text.trim().toUpperCase(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
      color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
      mileage: int.tryParse(_mileageController.text.trim()) ?? 0,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: widget.vehicle?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final vehicleRepo = Get.find<VehicleRepository>();
      await vehicleRepo.saveVehicle(vehicle);

      Get.back(result: true);
      Get.snackbar('Success', 'Vehicle profile saved to SQLite', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save vehicle: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
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
                      widget.vehicle == null ? 'Register New Vehicle' : 'Edit Vehicle Details',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Customer Selection
                DropdownButtonFormField<String>(
                  value: _selectedCustomerId,
                  decoration: const InputDecoration(labelText: 'Vehicle Owner (Customer) *', prefixIcon: Icon(Icons.person_rounded)),
                  items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.fullName} (${c.phone})'))).toList(),
                  onChanged: widget.preselectedCustomerId != null
                      ? null
                      : (val) => setState(() => _selectedCustomerId = val),
                  validator: (val) => val == null ? 'Please select owner' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _regNumberController,
                        decoration: const InputDecoration(labelText: 'Registration / Plate # *', hintText: 'e.g. LEA-20-4598'),
                        textCapitalization: TextCapitalization.characters,
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(labelText: 'Model Year', hintText: 'e.g. 2022'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _makeController,
                        decoration: const InputDecoration(labelText: 'Vehicle Name / Make *', hintText: 'e.g. Toyota, Honda, Audi'),
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. Fortuner, Civic, A6'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(labelText: 'Vehicle Color', hintText: 'e.g. Pearl White, Black'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _mileageController,
                        decoration: const InputDecoration(labelText: 'Current Odometer (KM)', hintText: 'e.g. 45000'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Vehicle Notes (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveVehicle,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.vehicle == null ? 'Register Vehicle' : 'Save Changes'),
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
