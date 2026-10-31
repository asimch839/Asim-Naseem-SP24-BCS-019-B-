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
import '../../data/repositories/staff_repository.dart';
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
  final TextEditingController _odometerInController = TextEditingController();

  List<CustomerModel> _customers = [];
  List<VehicleModel> _customerVehicles = [];
  List<StaffModel> _staffList = [];
  List<DetailingPackageModel> _availablePackages = [];

  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;
  bool _isEnteringNewVehicle = false;
  final List<SimpleServiceItem> _selectedServices = [];
  final List<StaffModel> _assignedStaff = [];

  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isWalkInCustomer =>
      _selectedCustomer == null && _customerController.text.trim().isNotEmpty;

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
    _odometerInController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final customerRepo = Get.find<CustomerRepository>();
    final staffRepo = Get.find<StaffRepository>();
    final packageRepo = Get.find<DetailingPackageRepository>();

    final customers = await customerRepo.getCustomers();
    final staff = await staffRepo.getStaffList();
    final packages = await packageRepo.getPackages(activeOnly: true);

    if (mounted) {
      setState(() {
        _customers = customers;
        _staffList = staff;
        _availablePackages = packages;

        if (widget.preselectedVehicle != null) {
          _selectedVehicle = widget.preselectedVehicle;
          _odometerInController.text = widget.preselectedVehicle!.mileage?.toString() ?? '0';
          _selectedCustomer = customers.firstWhereOrNull((c) => c.id == widget.preselectedVehicle!.customerId);
          if (_selectedCustomer != null) {
            _customerController.text = _selectedCustomer!.fullName;
          }
        }

        _isLoading = false;
      });

      if (_selectedCustomer != null) {
        _onCustomerSelected(_selectedCustomer!, preselectedVehicle: widget.preselectedVehicle);
      }
    }
  }

  Future<void> _reloadPackages() async {
    final packageRepo = Get.find<DetailingPackageRepository>();
    final packages = await packageRepo.getPackages(activeOnly: true);
    if (mounted) {
      setState(() {
        _availablePackages = packages;
        // Remove any selected services that may have been deleted
        _selectedServices.removeWhere((s) => !packages.any((p) => p.name == s.name));
      });
    }
  }

  void _onCustomerSelected(CustomerModel customer, {VehicleModel? preselectedVehicle}) async {
    setState(() {
      _selectedCustomer = customer;
      _customerController.text = customer.fullName;
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

  void _createJob() async {
    final customerName = _customerController.text.trim();
    if (customerName.isEmpty && _selectedCustomer == null) {
      Get.snackbar('Required', 'Please enter or select a Customer', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }
    if (_selectedServices.isEmpty) {
      Get.snackbar('Required', 'Please select at least one detailing service', backgroundColor: AppColors.error.withValues(alpha: 0.2));
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
      } else {
        // Check if typed name matches an existing customer exactly
        final matchedCustomer = _customers.firstWhereOrNull(
          (c) => c.fullName.trim().toLowerCase() == customerName.toLowerCase(),
        );
        if (matchedCustomer != null) {
          customerId = matchedCustomer.id;
          _selectedCustomer = matchedCustomer;
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

  // --- Quick Add Package Dialog ---
  void _showAddPackageDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Detailing Package', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Operation / Package Name *',
                  hintText: 'e.g. Glass Ceramic Coating (10H)',
                  prefixIcon: Icon(Icons.car_repair_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter package name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (PKR) *',
                  hintText: 'e.g. 5000',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter price';
                  if (double.tryParse(v.trim()) == null) return 'Enter valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final packageRepo = Get.find<DetailingPackageRepository>();
              final newPkg = DetailingPackageModel(
                id: 'pkg_${const Uuid().v4().substring(0, 8)}',
                name: nameCtrl.text.trim(),
                price: double.parse(priceCtrl.text.trim()),
                sortOrder: _availablePackages.length + 1,
              );
              await packageRepo.savePackage(newPkg);
              if (ctx.mounted) Navigator.pop(ctx);
              await _reloadPackages();
              setState(() {
                _selectedServices.add(SimpleServiceItem(newPkg.name, newPkg.price, id: newPkg.id));
              });
              Get.snackbar(
                'Package Added',
                '${newPkg.name} has been added to detailing packages',
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
              );
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  // --- Manage Packages Dialog ---
  void _showManagePackagesDialog() async {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Manage Detailing Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Admin can add, edit, or remove operations. Only packages listed here will appear in Job Cards.',
                    style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add New Operation / Package'),
                    onPressed: () async {
                      await _quickAddPackage();
                      await _reloadPackages();
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _availablePackages.isEmpty
                          ? const Center(child: Text('No packages configured. Click "+ Add New" to add one.'))
                          : ListView.separated(
                              itemCount: _availablePackages.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final p = _availablePackages[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: Text(Formatters.currency(p.price, symbol: currency),
                                      style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.info),
                                        tooltip: 'Edit Package',
                                        onPressed: () async {
                                          await _editPackage(p);
                                          await _reloadPackages();
                                          setDialogState(() {});
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                        tooltip: 'Delete Package',
                                        onPressed: () async {
                                          await _deletePackage(p);
                                          await _reloadPackages();
                                          setDialogState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
    await _reloadPackages();
  }

  Future<void> _quickAddPackage() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Operation / Package', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Package Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (PKR) *'),
                validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Enter valid price' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final packageRepo = Get.find<DetailingPackageRepository>();
              final newPkg = DetailingPackageModel(
                id: 'pkg_${const Uuid().v4().substring(0, 8)}',
                name: nameCtrl.text.trim(),
                price: double.parse(priceCtrl.text.trim()),
                sortOrder: _availablePackages.length + 1,
              );
              await packageRepo.savePackage(newPkg);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Package'),
          ),
        ],
      ),
    );
  }

  Future<void> _editPackage(DetailingPackageModel pkg) async {
    final nameCtrl = TextEditingController(text: pkg.name);
    final priceCtrl = TextEditingController(text: pkg.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Detailing Package', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Package Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (PKR) *'),
                validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Enter valid price' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final packageRepo = Get.find<DetailingPackageRepository>();
              final updated = pkg.copyWith(
                name: nameCtrl.text.trim(),
                price: double.parse(priceCtrl.text.trim()),
                updatedAt: DateTime.now(),
              );
              await packageRepo.savePackage(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePackage(DetailingPackageModel pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Detailing Package?'),
        content: Text('Are you sure you want to remove "${pkg.name}" from available packages?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final packageRepo = Get.find<DetailingPackageRepository>();
      await packageRepo.deletePackage(pkg.id);
      _selectedServices.removeWhere((s) => s.name == pkg.name);
    }
  }

  Future<void> _editServicePrice(SimpleServiceItem service) async {
    final priceCtrl = TextEditingController(text: service.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Price: ${service.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter custom job charge for "${service.name}":', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Custom Price (PKR) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Enter valid price' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                service.price = double.parse(priceCtrl.text.trim());
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save Price'),
          ),
        ],
      ),
    );
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

                          // Walk-in Customer Extra Info (if custom name typed)
                          if (_isWalkInCustomer) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Walk-in / New Customer "${_customerController.text.trim()}". Record will be saved automatically.',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 190,
                                    child: TextFormField(
                                      controller: _walkInPhoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone (Optional)',
                                        isDense: true,
                                        prefixIcon: Icon(Icons.phone_rounded, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Odometer In & Staff
                          if (isWide)
                            Row(
                              children: [
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<StaffModel>(
                                    decoration: const InputDecoration(labelText: 'Assign Primary Technician', prefixIcon: Icon(Icons.badge_rounded)),
                                    items: _staffList.map((st) => DropdownMenuItem(value: st, child: Text('${st.name} (${st.designation})', overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) {
                                      if (val != null && !_assignedStaff.contains(val)) {
                                        setState(() => _assignedStaff.add(val));
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            TextFormField(
                              controller: _odometerInController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Odometer In (KM)',
                                prefixIcon: Icon(Icons.speed_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<StaffModel>(
                              decoration: const InputDecoration(labelText: 'Assign Primary Technician', prefixIcon: Icon(Icons.badge_rounded)),
                              items: _staffList.map((st) => DropdownMenuItem(value: st, child: Text('${st.name} (${st.designation})', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) {
                                if (val != null && !_assignedStaff.contains(val)) {
                                  setState(() => _assignedStaff.add(val));
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Services Selection Header with Dynamic Add & Manage Buttons
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Detailing Operations & Packages',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text('(${_selectedServices.length} Selected)',
                                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add_rounded, size: 15),
                                    label: const Text('Add Package', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: _showAddPackageDialog,
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.tune_rounded, size: 15),
                                    label: const Text('Manage', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: _showManagePackagesDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Dynamic Packages List
                          SizedBox(
                            height: isWide ? 200 : 160,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _availablePackages.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textDarkSecondary),
                                          const SizedBox(height: 8),
                                          const Text('No detailing operations added yet.'),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: _showAddPackageDialog,
                                            icon: const Icon(Icons.add_rounded, size: 16),
                                            label: const Text('Add Detailing Package'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _availablePackages.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final s = _availablePackages[index];
                                        final selectedItem = _selectedServices.firstWhereOrNull((item) => item.name == s.name);
                                        final isSelected = selectedItem != null;

                                        return Container(
                                          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                                          child: ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            leading: Checkbox(
                                              value: isSelected,
                                              activeColor: AppColors.primary,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedServices.add(SimpleServiceItem(s.name, s.price, id: s.id));
                                                  } else {
                                                    _selectedServices.removeWhere((item) => item.name == s.name);
                                                  }
                                                });
                                              },
                                            ),
                                            title: Text(
                                              s.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isSelected ? AppColors.primaryLight : null,
                                              ),
                                            ),
                                            subtitle: isSelected && selectedItem.price != s.price
                                                ? Text(
                                                    'Customized (Standard: ${Formatters.currency(s.price, symbol: currency)})',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                                                  )
                                                : Text(
                                                    'Standard: ${Formatters.currency(s.price, symbol: currency)}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                                                  ),
                                            trailing: isSelected
                                                ? Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _editServicePrice(selectedItem),
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primary.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: AppColors.primary),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                Formatters.currency(selectedItem.price, symbol: currency),
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: AppColors.primaryLight,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (selectedItem.price != s.price) ...[
                                                        const SizedBox(width: 4),
                                                        IconButton(
                                                          icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.textDarkMuted),
                                                          tooltip: 'Reset to standard price',
                                                          onPressed: () {
                                                            setState(() {
                                                              selectedItem.price = s.price;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ],
                                                  )
                                                : Text(
                                                    Formatters.currency(s.price, symbol: currency),
                                                    style: const TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
                                                  ),
                                            onTap: () {
                                              setState(() {
                                                if (!isSelected) {
                                                  _selectedServices.add(SimpleServiceItem(s.name, s.price, id: s.id));
                                                } else {
                                                  _selectedServices.removeWhere((item) => item.name == s.name);
                                                }
                                              });
                                            },
                                          ),
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
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
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
