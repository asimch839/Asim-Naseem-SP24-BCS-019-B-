import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/staff_repository.dart';
import '../../data/repositories/job_repository.dart';

class SimpleServiceItem {
  final String name;
  final double price;
  SimpleServiceItem(this.name, this.price);
}

class JobCreateDialog extends StatefulWidget {
  final VehicleModel? preselectedVehicle;
  const JobCreateDialog({super.key, this.preselectedVehicle});

  @override
  State<JobCreateDialog> createState() => _JobCreateDialogState();
}

class _JobCreateDialogState extends State<JobCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _odometerInController = TextEditingController();

  List<CustomerModel> _customers = [];
  List<VehicleModel> _customerVehicles = [];
  List<StaffModel> _staffList = [];

  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;
  final List<SimpleServiceItem> _selectedServices = [];
  final List<StaffModel> _assignedStaff = [];

  bool _isLoading = true;
  bool _isSaving = false;

  final List<SimpleServiceItem> _availableServices = [
    SimpleServiceItem('Full Body Ceramic Coating (9H)', 25000),
    SimpleServiceItem('Interior Deep Detailing & Shampoo', 6000),
    SimpleServiceItem('Paint Correction (3-Stage Buffing)', 12000),
    SimpleServiceItem('Underchassis Rust Protection', 5000),
    SimpleServiceItem('Headlight Restoration & UV Seal', 2500),
    SimpleServiceItem('Leather Conditioning & Treatment', 4000),
    SimpleServiceItem('Engine Bay Detailing & Dressing', 2500),
    SimpleServiceItem('Standard Detailing Foam Wash', 1500),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final customerRepo = Get.find<CustomerRepository>();
    final staffRepo = Get.find<StaffRepository>();

    final customers = await customerRepo.getCustomers();
    final staff = await staffRepo.getStaffList();

    if (mounted) {
      setState(() {
        _customers = customers;
        _staffList = staff;

        if (widget.preselectedVehicle != null) {
          _selectedVehicle = widget.preselectedVehicle;
          _odometerInController.text = widget.preselectedVehicle!.mileage?.toString() ?? '0';
          _selectedCustomer = customers.firstWhereOrNull((c) => c.id == widget.preselectedVehicle!.customerId);
        }

        _isLoading = false;
      });

      if (_selectedCustomer != null) {
        _onCustomerChanged(_selectedCustomer, preselectedVehicle: widget.preselectedVehicle);
      }
    }
  }

  void _onCustomerChanged(CustomerModel? customer, {VehicleModel? preselectedVehicle}) async {
    setState(() {
      _selectedCustomer = customer;
      if (preselectedVehicle == null) {
        _selectedVehicle = null;
        _customerVehicles = [];
      }
    });

    if (customer != null) {
      final customerRepo = Get.find<CustomerRepository>();
      final vList = await customerRepo.getCustomerVehicles(customer.id);
      if (mounted) {
        setState(() {
          _customerVehicles = vList;
          if (preselectedVehicle != null) {
            _selectedVehicle = preselectedVehicle;
          } else if (vList.isNotEmpty) {
            _selectedVehicle = vList.first;
            _odometerInController.text = _selectedVehicle!.mileage?.toString() ?? '0';
          }
        });
      }
    }
  }

  double get _subtotal => _selectedServices.fold(0.0, (sum, s) => sum + s.price);
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _grandTotal => (_subtotal - _discount).clamp(0.0, double.infinity);

  void _createJob() async {
    if (_selectedCustomer == null || _selectedVehicle == null) {
      Get.snackbar('Required', 'Please select both a Customer and a Vehicle', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }
    if (_selectedServices.isEmpty) {
      Get.snackbar('Required', 'Please select at least one detailing service', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    setState(() => _isSaving = true);
    final odoIn = double.tryParse(_odometerInController.text.trim()) ?? (_selectedVehicle!.mileage?.toDouble() ?? 0.0);

    try {
      final jobRepo = Get.find<JobRepository>();
      await jobRepo.saveJob(
        customerId: _selectedCustomer!.id,
        vehicleId: _selectedVehicle!.id,
        status: AppConstants.jobStatusNew,
        receivingDate: DateTime.now(),
        odometerIn: odoIn,
        odometerOut: odoIn,
        serviceLabour: _subtotal,
        discount: _discount,
        services: _selectedServices.map((s) => {'description': s.name, 'amount': s.price}).toList(),
        assignedStaffIds: _assignedStaff.map((st) => st.id).toList(),
        technicianName: _assignedStaff.isNotEmpty ? _assignedStaff.first.name : 'Shop Lead',
        specialInstructions: _notesController.text.trim(),
      );

      Get.back(result: true);
      Get.snackbar(
        'Job Card Created',
        'Digital Job Card registered in SQLite',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save job card: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Digital Job Card / Repair Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Customer & Vehicle Selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<CustomerModel>(
                            value: _selectedCustomer,
                            decoration: const InputDecoration(labelText: 'Customer *', prefixIcon: Icon(Icons.person_rounded)),
                            items: _customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.fullName} (${c.phone})'))).toList(),
                            onChanged: (val) => _onCustomerChanged(val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<VehicleModel>(
                            value: _selectedVehicle,
                            decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_rounded)),
                            items: _customerVehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.displayName} (${v.plateNumber})'))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedVehicle = val;
                                if (val != null) _odometerInController.text = val.mileage?.toString() ?? '0';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Odometer In & Staff
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odometerInController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Odometer In (KM) *',
                              prefixIcon: Icon(Icons.speed_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<StaffModel>(
                            decoration: const InputDecoration(labelText: 'Assign Primary Technician', prefixIcon: Icon(Icons.badge_rounded)),
                            items: _staffList.map((st) => DropdownMenuItem(value: st, child: Text('${st.name} (${st.designation})'))).toList(),
                            onChanged: (val) {
                              if (val != null && !_assignedStaff.contains(val)) {
                                setState(() => _assignedStaff.add(val));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Services Selection Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detailing Operations & Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${_selectedServices.length} Selected', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          itemCount: _availableServices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = _availableServices[index];
                            final isSelected = _selectedServices.any((item) => item.name == s.name);

                            return CheckboxListTile(
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(Formatters.currency(s.price, symbol: currency)),
                              value: isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedServices.add(s);
                                  } else {
                                    _selectedServices.removeWhere((item) => item.name == s.name);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Financial Summary Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: TextFormField(
                                  controller: _discountController,
                                  decoration: const InputDecoration(labelText: 'Discount'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Subtotal: ${Formatters.currency(_subtotal, symbol: currency)}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                              Text(
                                'Grand Total: ${Formatters.currency(_grandTotal, symbol: currency)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _createJob,
                          child: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create Digital Job Card'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
