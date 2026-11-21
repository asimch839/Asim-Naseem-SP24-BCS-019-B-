import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/detailing_package_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/detailing_package_repository.dart';

class SimpleServiceItem {
  final String id;
  final String name;
  double price;
  SimpleServiceItem(this.name, this.price, {this.id = ''});
}

class JobCreateDialog extends StatefulWidget {
  final VehicleModel? preselectedVehicle;
  const JobCreateDialog({super.key, this.preselectedVehicle});

  @override
  State<JobCreateDialog> createState() => _JobCreateDialogState();
}

class _JobCreateDialogState extends State<JobCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final FocusNode _customerFocusNode = FocusNode();
  final TextEditingController _walkInPhoneController = TextEditingController();
  final TextEditingController _customVehicleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _advancePaymentController = TextEditingController(text: '0');
  final TextEditingController _odometerInController = TextEditingController();

  List<CustomerModel> _customers = [];
  List<VehicleModel> _customerVehicles = [];

  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;
  bool _isEnteringNewVehicle = false;
  final List<SimpleServiceItem> _selectedServices = [];
  final List<StaffModel> _assignedStaff = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _customerFocusNode.dispose();
    _walkInPhoneController.dispose();
    _customVehicleController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _advancePaymentController.dispose();
    _odometerInController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final customerRepo = Get.find<CustomerRepository>();
    final customers = await customerRepo.getCustomers();

    if (mounted) {
      setState(() {
        _customers = customers;

        if (widget.preselectedVehicle != null) {
          _selectedVehicle = widget.preselectedVehicle;
          _odometerInController.text = widget.preselectedVehicle!.mileage?.toString() ?? '0';
          _selectedCustomer = customers.firstWhereOrNull((c) => c.id == widget.preselectedVehicle!.customerId);
          if (_selectedCustomer != null) {
            _customerController.text = _selectedCustomer!.fullName;
            _walkInPhoneController.text = _selectedCustomer!.phone;
          }
        }

        _isLoading = false;
      });

      if (_selectedCustomer != null) {
        _onCustomerSelected(_selectedCustomer!, preselectedVehicle: widget.preselectedVehicle);
      }
    }
  }

  void _onCustomerSelected(CustomerModel customer, {VehicleModel? preselectedVehicle}) async {
    setState(() {
      _selectedCustomer = customer;
      _customerController.text = customer.fullName;
      _walkInPhoneController.text = customer.phone;
      _isEnteringNewVehicle = false;
      if (preselectedVehicle == null) {
        _selectedVehicle = null;
        _customerVehicles = [];
      }
    });

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
        } else {
          _isEnteringNewVehicle = true;
        }
      });
    }
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerController.clear();
      _customerVehicles = [];
      _selectedVehicle = null;
      _isEnteringNewVehicle = false;
      _walkInPhoneController.clear();
      _customVehicleController.clear();
    });
  }

  double get _subtotal => _selectedServices.fold(0.0, (sum, s) => sum + s.price);
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _grandTotal => (_subtotal - _discount).clamp(0.0, double.infinity);
  double get _advance => double.tryParse(_advancePaymentController.text) ?? 0.0;
  double get _remaining => (_grandTotal - _advance).clamp(0.0, double.infinity);

  void _createJob() async {
    final customerName = _customerController.text.trim();
    if (customerName.isEmpty && _selectedCustomer == null) {
      Get.snackbar('Required', 'Please enter or select a Customer', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    setState(() => _isSaving = true);
    final odoIn = double.tryParse(_odometerInController.text.trim()) ?? (_selectedVehicle?.mileage?.toDouble() ?? 0.0);

    try {
      final customerRepo = Get.find<CustomerRepository>();
      final vehicleRepo = Get.find<VehicleRepository>();
      final jobRepo = Get.find<JobRepository>();

      String customerId;
      String vehicleId;

      // 1. Resolve Customer
      if (_selectedCustomer != null) {
        customerId = _selectedCustomer!.id;
        final enteredPhone = _walkInPhoneController.text.trim();
        if (enteredPhone.isNotEmpty && enteredPhone != _selectedCustomer!.phone) {
          final updatedCust = _selectedCustomer!.copyWith(phone: enteredPhone);
          await customerRepo.saveCustomer(updatedCust);
          _selectedCustomer = updatedCust;
        }
      } else {
        // Check if typed name matches an existing customer exactly
        final matchedCustomer = _customers.firstWhereOrNull(
          (c) => c.fullName.trim().toLowerCase() == customerName.toLowerCase(),
        );
        if (matchedCustomer != null) {
          customerId = matchedCustomer.id;
          _selectedCustomer = matchedCustomer;
          final enteredPhone = _walkInPhoneController.text.trim();
          if (enteredPhone.isNotEmpty && enteredPhone != matchedCustomer.phone) {
            final updatedCust = matchedCustomer.copyWith(phone: enteredPhone);
            await customerRepo.saveCustomer(updatedCust);
          }
        } else {
          // Auto-create new customer (walk-in or quick client)
          customerId = 'cust_${const Uuid().v4().substring(0, 8)}';
          final phone = _walkInPhoneController.text.trim().isNotEmpty
              ? _walkInPhoneController.text.trim()
              : 'Walk-in';
          final newCust = CustomerModel(
            id: customerId,
            businessId: 'local',
            fullName: customerName,
            phone: phone,
            status: 'Active',
            createdAt: DateTime.now(),
          );
          await customerRepo.saveCustomer(newCust);
        }
      }

      // 2. Resolve Vehicle
      if (_selectedVehicle != null && !_isEnteringNewVehicle) {
        vehicleId = _selectedVehicle!.id;
      } else {
        final vText = _customVehicleController.text.trim();
        final vMake = vText.isNotEmpty ? vText : 'Walk-in Vehicle';
        final vPlate = vText.isNotEmpty ? vText.toUpperCase() : 'WALK-IN';

        vehicleId = 'veh_${const Uuid().v4().substring(0, 8)}';
        final newVeh = VehicleModel(
          id: vehicleId,
          businessId: 'local',
          customerId: customerId,
          make: vMake,
          registrationNumber: vPlate,
          mileage: odoIn.toInt(),
          createdAt: DateTime.now(),
        );
        await vehicleRepo.saveVehicle(newVeh);
      }

      // 3. Save Job in SQLite
      await jobRepo.saveJob(
        customerId: customerId,
        vehicleId: vehicleId,
        status: AppConstants.jobStatusNew,
        receivingDate: DateTime.now(),
        odometerIn: odoIn,
        odometerOut: odoIn,
        serviceLabour: _subtotal,
        discount: _discount,
        paidAmount: _advance,
        services: _selectedServices.map((s) => {'description': s.name, 'amount': s.price}).toList(),
        assignedStaffIds: _assignedStaff.map((st) => st.id).toList(),
        technicianName: _assignedStaff.isNotEmpty ? _assignedStaff.first.name : 'Shop Lead',
        specialInstructions: _notesController.text.trim(),
      );

      Get.back(result: true);
      Get.snackbar(
        'Job Card Created',
        'Digital Job Card registered for $customerName',
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 20),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'New Digital Job Card / Repair Order',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                          // Customer & Vehicle Section
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildCustomerField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildVehicleField()),
                              ],
                            )
                          else ...[
                            _buildCustomerField(),
                            const SizedBox(height: 10),
                            _buildVehicleField(),
                          ],

                          const SizedBox(height: 12),

                          // Phone & Odometer Section (Side-by-side in same row)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _walkInPhoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone (Optional)',
                                    prefixIcon: Icon(Icons.phone_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _odometerInController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Odometer In (KM)',
                                    prefixIcon: Icon(Icons.speed_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Advance Payment Received & Instructions
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _advancePaymentController,
                                  decoration: InputDecoration(
                                    labelText: 'Advance Payment / Deposit Received (Optional)',
                                    prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                                    hintText: 'e.g. 5000',
                                    prefixText: _advance > 0 ? '$currency ' : null,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Special Instructions / Notes (Optional)',
                                    prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                                    hintText: 'Customer requests, pre-existing vehicle marks, etc.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
                        ],
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  // --- Customer Search & Freeform Input Widget ---
  Widget _buildCustomerField() {
    return RawAutocomplete<CustomerModel>(
      textEditingController: _customerController,
      focusNode: _customerFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return _customers;
        }
        final q = textEditingValue.text.toLowerCase().trim();
        return _customers.where((c) {
          return c.fullName.toLowerCase().contains(q) || c.phone.contains(q);
        });
      },
      displayStringForOption: (CustomerModel option) => option.fullName,
      onSelected: (CustomerModel customer) {
        _onCustomerSelected(customer);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Customer (Search or Type New) *',
            hintText: 'Type name or search previous customer...',
            prefixIcon: const Icon(Icons.person_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: 'Clear Customer',
                    onPressed: _clearCustomer,
                  ),
                PopupMenuButton<CustomerModel>(
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textDarkSecondary),
                  tooltip: 'Browse Previous Customers',
                  onSelected: (c) => _onCustomerSelected(c),
                  itemBuilder: (ctx) {
                    if (_customers.isEmpty) {
                      return [
                        const PopupMenuItem(
                          enabled: false,
                          child: Text('No previous customers recorded yet'),
                        ),
                      ];
                    }
                    return _customers.map((c) {
                      return PopupMenuItem<CustomerModel>(
                        value: c,
                        child: Text('${c.fullName} (${c.phone})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
          onChanged: (val) {
            setState(() {
              if (_selectedCustomer != null && val.trim() != _selectedCustomer!.fullName.trim()) {
                _selectedCustomer = null;
                _customerVehicles = [];
                _selectedVehicle = null;
                _isEnteringNewVehicle = true;
              }
            });
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).cardColor,
            child: Container(
              width: 380,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, size: 16, color: AppColors.primaryLight),
                    ),
                    title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(c.phone, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Previous', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                    onTap: () => onSelected(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Dynamic Vehicle Field (Dropdown for existing customer, text for walk-in/new) ---
  Widget _buildVehicleField() {
    if (_selectedCustomer != null && _customerVehicles.isNotEmpty && !_isEnteringNewVehicle) {
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<VehicleModel>(
              value: _selectedVehicle,
              decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_rounded)),
              items: _customerVehicles
                  .map((v) => DropdownMenuItem(value: v, child: Text('${v.displayName} (${v.plateNumber})', overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedVehicle = val;
                  if (val != null) _odometerInController.text = val.mileage?.toString() ?? '0';
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight),
            tooltip: 'Enter another vehicle for this customer',
            onPressed: () {
              setState(() {
                _isEnteringNewVehicle = true;
                _selectedVehicle = null;
              });
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _customVehicleController,
            decoration: InputDecoration(
              labelText: 'Vehicle (e.g. Civic - LEA-123) *',
              hintText: 'Vehicle details (or Walk-in)',
              prefixIcon: const Icon(Icons.directions_car_rounded),
              suffixIcon: (_selectedCustomer != null && _customerVehicles.isNotEmpty)
                  ? IconButton(
                      icon: const Icon(Icons.list_rounded),
                      tooltip: 'Choose existing vehicle',
                      onPressed: () {
                        setState(() {
                          _isEnteringNewVehicle = false;
                          _selectedVehicle = _customerVehicles.first;
                          _odometerInController.text = _selectedVehicle!.mileage?.toString() ?? '0';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
