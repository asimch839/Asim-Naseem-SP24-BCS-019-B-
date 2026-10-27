import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';

class AddCustomerCarDialog extends StatefulWidget {
  final CustomerModel customer;
  const AddCustomerCarDialog({super.key, required this.customer});

  @override
  State<AddCustomerCarDialog> createState() => _AddCustomerCarDialogState();
}

class _AddCustomerCarDialogState extends State<AddCustomerCarDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _carNameController = TextEditingController();
  final TextEditingController _modelYearController = TextEditingController(text: DateTime.now().year.toString());
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _serviceAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final DateTime _serviceDate = DateTime.now();
  final DateTime _deliveryDate = DateTime.now();
  bool _isSaving = false;

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final vehicleId = 'veh_${const Uuid().v4().substring(0, 8)}';
    final carName = _carNameController.text.trim();
    final modelYear = int.tryParse(_modelYearController.text.trim()) ?? DateTime.now().year;
    final regNumber = _vehicleNumberController.text.trim().toUpperCase();
    final service = _serviceController.text.trim();
    final odometer = double.tryParse(_odometerController.text.trim()) ?? 0.0;
    final amount = double.tryParse(_serviceAmountController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    final vehicle = VehicleModel(
      id: vehicleId,
      businessId: 'local',
      customerId: widget.customer.id,
      registrationNumber: regNumber,
      make: carName.split(' ').first,
      model: carName.contains(' ') ? carName.substring(carName.indexOf(' ') + 1) : '',
      year: modelYear,
      mileage: odometer.toInt(),
      notes: notes,
    );

    try {
      final vehRepo = Get.find<VehicleRepository>();
      // 1. Save Vehicle in SQLite
      await vehRepo.saveVehicle(vehicle);

      // 2. Add permanent service history record if service is specified
      if (service.isNotEmpty) {
        await vehRepo.addServiceHistory(
          vehicleId: vehicleId,
          customerId: widget.customer.id,
          date: _serviceDate,
          serviceDescription: service,
          odometer: odometer,
          amount: amount,
          deliveryDate: _deliveryDate,
          paymentStatus: amount > 0 ? 'Paid' : 'Unpaid',
          notes: notes,
        );
      }

      Get.back(result: true);
      Get.snackbar(
        'Vehicle Registered',
        '$carName ($regNumber) associated with ${widget.customer.fullName}',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save vehicle: $e',
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.directions_car_rounded, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(child: Text('Add Car for ${widget.customer.fullName}', maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Name & Model Year
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _carNameController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Name / Model *',
                          hintText: 'e.g. Toyota Fortuner',
                          prefixIcon: Icon(Icons.directions_car_filled_outlined, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter car name' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modelYearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Model Year'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Number Plate
                TextFormField(
                  controller: _vehicleNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Registration / Plate Number *',
                    hintText: 'e.g. LEA-20-4598',
                    prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter vehicle plate number' : null,
                ),
                const SizedBox(height: 16),

                const Divider(),
                const Text('First Visit / Service Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Service Description',
                    hintText: 'e.g. Ceramic Coating 9H + Deep Detailing',
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _odometerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Current Odometer (KM)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _serviceAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Service Charge'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Vehicle Condition / Remarks'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Vehicle'),
        ),
      ],
    );
  }
}
