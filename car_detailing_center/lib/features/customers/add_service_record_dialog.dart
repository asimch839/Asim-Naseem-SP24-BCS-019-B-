import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';

class AddServiceRecordDialog extends StatefulWidget {
  final CustomerModel customer;
  final VehicleModel vehicle;

  const AddServiceRecordDialog({
    super.key,
    required this.customer,
    required this.vehicle,
  });

  @override
  State<AddServiceRecordDialog> createState() => _AddServiceRecordDialogState();
}

class _AddServiceRecordDialogState extends State<AddServiceRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _staffController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final DateTime _serviceDate = DateTime.now();
  final DateTime _deliveryDate = DateTime.now();
  String _paymentStatus = 'Paid';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle.mileage != null) {
      _odometerController.text = widget.vehicle.mileage.toString();
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final km = double.tryParse(_odometerController.text.trim()) ?? 0.0;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    try {
      final vehRepo = Get.find<VehicleRepository>();
      await vehRepo.addServiceHistory(
        vehicleId: widget.vehicle.id,
        customerId: widget.customer.id,
        date: _serviceDate,
        serviceDescription: _serviceController.text.trim(),
        odometer: km,
        amount: amount,
        deliveryDate: _deliveryDate,
        paymentStatus: _paymentStatus,
        staffNames: _staffController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      Get.back(result: true);
      Get.snackbar('Service Logged', 'Service record permanently saved to SQLite', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save service record: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Service: ${widget.vehicle.make} ${widget.vehicle.model} (${widget.vehicle.registrationNumber})'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Service Description * (e.g. Paint Correction, Ceramic 9H, Wash)',
                    prefixIcon: Icon(Icons.cleaning_services_rounded, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter service' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _odometerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Odometer (KM) *',
                          prefixIcon: Icon(Icons.speed_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount Charged *',
                          prefixIcon: Icon(Icons.payments_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _staffController,
                        decoration: const InputDecoration(labelText: 'Staff / Tech Assigned'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentStatus,
                        decoration: const InputDecoration(labelText: 'Payment Status'),
                        items: const [
                          DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                          DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                          DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Service Notes / Warranty'),
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
              : const Text('Save Record'),
        ),
      ],
    );
  }
}
