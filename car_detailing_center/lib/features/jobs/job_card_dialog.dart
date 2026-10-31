import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/job_repository.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/digital_signature_dialog.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/job_model.dart';

class ServiceRowItem {
  final TextEditingController descriptionCtrl;
  final TextEditingController amountCtrl;

  ServiceRowItem({String description = '', double amount = 0.0})
      : descriptionCtrl = TextEditingController(text: description),
        amountCtrl = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : '');

  double get amount => double.tryParse(amountCtrl.text.trim()) ?? 0.0;
}

class JobCardDialog extends StatefulWidget {
  final CustomerModel customer;
  final VehicleModel vehicle;
  final JobModel? existingJob;

  const JobCardDialog({
    super.key,
    required this.customer,
    required this.vehicle,
    this.existingJob,
  });

  @override
  State<JobCardDialog> createState() => _JobCardDialogState();
}

class _JobCardDialogState extends State<JobCardDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _jobNumberCtrl;
  late final TextEditingController _technicianCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _customerAddressCtrl;
  late final TextEditingController _variantCtrl;
  late final TextEditingController _modelYearCtrl;
  late final TextEditingController _chassisCtrl;
  late final TextEditingController _odometerInCtrl;
  late final TextEditingController _odometerOutCtrl;
  late final TextEditingController _specificInfoCtrl;
  late final TextEditingController _specialInstructionsCtrl;
  late final TextEditingController _labourAmountCtrl;
  late final TextEditingController _partsAmountCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _paidAmountCtrl;

  String _fuelGauge = '1/2';
  final Set<String> _selectedServiceTypes = {'PPF', 'Detailing'};
  String _paymentMethod = 'Cash';
  final DateTime _receivingDateTime = DateTime.now();
  DateTime _expectedDateTime = DateTime.now().add(const Duration(hours: 4));
  bool _isSaving = false;

  String? _customerAuthSigPath;
  String? _customerDeliverySigPath;
  String? _advisorSigPath;
  String? _authorizedSigPath;

  final List<ServiceRowItem> _serviceRows = [];

  final List<String> _checklistNames = [
    'Battery Code',
    'EVB/CR/USB',
    'CIG-LIGHTER',
    'ASHTRAY',
    'RADIO ANTENA',
    'FLOOR MATS',
    'WIPER BLADES',
    'MONOGRAMS',
    'WHEEL CAPS',
    'SPARE WHEEL',
    'SEAT COVERS',
    'LCD WORKING',
    'BACK CAMERA',
    'FRONT CAMERA',
    'JACK & WHEEL BRACE',
    'TOOLS',
    'NAVIGATION CARD',
    'Others',
  ];
  final Map<String, bool> _checklistStatus = {};

  @override
  void initState() {
    super.initState();
    final j = widget.existingJob;
    final prefix = AuthService.to.currentBusiness.value?.jobPrefix ?? 'JOB-';
    _jobNumberCtrl = TextEditingController(text: j?.jobNumber ?? '$prefix${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _technicianCtrl = TextEditingController(text: j?.assignedStaffNames.isNotEmpty == true ? j!.assignedStaffNames.first : 'Lead Technician');
    _companyNameCtrl = TextEditingController(text: widget.customer.notes ?? '');
    _customerAddressCtrl = TextEditingController(text: widget.customer.address ?? '');
    _variantCtrl = TextEditingController(text: '');
    _modelYearCtrl = TextEditingController(text: widget.vehicle.year?.toString() ?? '');
    _chassisCtrl = TextEditingController(text: widget.vehicle.vin ?? '');
    _odometerInCtrl = TextEditingController(text: widget.vehicle.mileage?.toString() ?? '');
    _odometerOutCtrl = TextEditingController(text: widget.vehicle.mileage?.toString() ?? '');
    _specificInfoCtrl = TextEditingController();
    _specialInstructionsCtrl = TextEditingController(text: j?.notes ?? '');
    _labourAmountCtrl = TextEditingController(text: j != null ? j.subtotal.toStringAsFixed(0) : '0');
    _partsAmountCtrl = TextEditingController(text: '0');
    _discountCtrl = TextEditingController(text: j != null ? j.discount.toStringAsFixed(0) : '0');
    _paidAmountCtrl = TextEditingController(text: j != null ? j.paidAmount.toStringAsFixed(0) : '0');

    if (j != null) {
      _customerAuthSigPath = j.customerSignature;
      _advisorSigPath = j.serviceAdvisorSignature;
      _authorizedSigPath = j.authorizedSignature;
    }

    // Initialize 18 Checklist items to checked/present
    for (var item in _checklistNames) {
      _checklistStatus[item] = true;
    }

    if (j != null && j.services.isNotEmpty) {
      for (var s in j.services) {
        _serviceRows.add(ServiceRowItem(description: s.serviceName, amount: s.price));
      }
    } else {
      _serviceRows.add(ServiceRowItem(description: 'Full Exterior Wash & Clay Treatment', amount: 3000));
      _serviceRows.add(ServiceRowItem(description: 'Interior Deep Detailing & Shampoo', amount: 5000));
    }
  }

  @override
  void dispose() {
    _jobNumberCtrl.dispose();
    _technicianCtrl.dispose();
    _companyNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _variantCtrl.dispose();
    _modelYearCtrl.dispose();
    _chassisCtrl.dispose();
    _odometerInCtrl.dispose();
    _odometerOutCtrl.dispose();
    _specificInfoCtrl.dispose();
    _specialInstructionsCtrl.dispose();
    _labourAmountCtrl.dispose();
    _partsAmountCtrl.dispose();
    _discountCtrl.dispose();
    _paidAmountCtrl.dispose();
    for (var r in _serviceRows) {
      r.descriptionCtrl.dispose();
      r.amountCtrl.dispose();
    }
    super.dispose();
  }

  double get _serviceLabour => double.tryParse(_labourAmountCtrl.text.trim()) ?? 0.0;
  double get _parts => double.tryParse(_partsAmountCtrl.text.trim()) ?? 0.0;
  double get _discount => double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
  double get _paid => double.tryParse(_paidAmountCtrl.text.trim()) ?? 0.0;

  double get _grandTotal {
    double itemsTotal = _serviceRows.fold(0.0, (sum, item) => sum + item.amount);
    double base = itemsTotal > 0 ? itemsTotal : _serviceLabour;
    return (base + _parts - _discount).clamp(0.0, double.infinity);
  }

  double get _remaining => (_grandTotal - _paid).clamp(0.0, double.infinity);

  void _saveAndGeneratePdf() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final businessId = AuthService.to.businessId;
    final jobId = widget.existingJob?.id ?? const Uuid().v4();

    final List<JobServiceItem> services = _serviceRows
        .where((r) => r.descriptionCtrl.text.trim().isNotEmpty)
        .map((r) => JobServiceItem(
              serviceId: const Uuid().v4(),
              serviceName: r.descriptionCtrl.text.trim(),
              price: r.amount,
            ))
        .toList();

    final damageChecklistData = _checklistStatus.entries
        .map((e) => {'item': e.key, 'status': e.value ? 'OK' : 'Missing/Issue'})
        .toList();

    final combinedNotes = [
      if (_specificInfoCtrl.text.trim().isNotEmpty) 'Alterations: ${_specificInfoCtrl.text.trim()}',
      if (_specialInstructionsCtrl.text.trim().isNotEmpty) 'Instructions: ${_specialInstructionsCtrl.text.trim()}',
      'Fuel: $_fuelGauge | Services: ${_selectedServiceTypes.join(",")}',
    ].join(' | ');

    final job = JobModel(
      id: jobId,
      jobNumber: _jobNumberCtrl.text.trim(),
      businessId: businessId,
      customerId: widget.customer.id,
      customerName: widget.customer.fullName,
      customerPhone: widget.customer.phone,
      vehicleId: widget.vehicle.id,
      vehicleRegNumber: widget.vehicle.registrationNumber,
      vehicleDisplayName: '${widget.vehicle.make} ${widget.vehicle.model}',
      services: services,
      assignedStaffNames: [_technicianCtrl.text.trim()],
      status: AppConstants.jobStatusInProgress,
      subtotal: _serviceLabour > 0 ? _serviceLabour : _grandTotal,
      discount: _discount,
      grandTotal: _grandTotal,
      paidAmount: _paid,
      remainingAmount: _remaining,
      customerSignature: _customerAuthSigPath,
      serviceAdvisorSignature: _advisorSigPath,
      authorizedSignature: _authorizedSigPath,
      notes: combinedNotes,
      createdAt: widget.existingJob?.createdAt ?? DateTime.now(),
    );

    try {
      final jobRepo = Get.find<JobRepository>();
      await jobRepo.saveJob(
        id: jobId,
        jobNumber: _jobNumberCtrl.text.trim(),
        customerId: widget.customer.id,
        vehicleId: widget.vehicle.id,
        technicianName: _technicianCtrl.text.trim(),
        serviceAdvisor: 'Service Advisor',
        status: AppConstants.jobStatusInProgress,
        receivingDate: _receivingDateTime,
        expectedDeliveryDate: _expectedDateTime,
        odometerIn: double.tryParse(_odometerInCtrl.text.trim()) ?? 0.0,
        odometerOut: double.tryParse(_odometerOutCtrl.text.trim()) ?? 0.0,
        specialInstructions: combinedNotes,
        serviceLabour: _serviceLabour > 0 ? _serviceLabour : _grandTotal,
        partsTotal: _parts,
        discount: _discount,
        paidAmount: _paid,
        customerSignature: _customerAuthSigPath,
        serviceAdvisorSignature: _advisorSigPath,
        authorizedSignature: _authorizedSigPath,
        services: services.map((s) => {'description': s.serviceName, 'amount': s.price}).toList(),
      );

      final business = AuthService.to.currentBusiness.value;
      if (business != null) {
        await PdfService.printJobCard(
          business: business,
          job: job,
          customerName: widget.customer.fullName,
          companyName: _companyNameCtrl.text.trim(),
          contactNumber: widget.customer.phone,
          currentAddress: _customerAddressCtrl.text.trim(),
          regNo: widget.vehicle.registrationNumber,
          vehicleModel: '${widget.vehicle.make} ${widget.vehicle.model}',
          variant: _variantCtrl.text.trim(),
          modelYear: _modelYearCtrl.text.trim(),
          chassisNo: _chassisCtrl.text.trim(),
          odometerIn: _odometerInCtrl.text.trim(),
          odometerOut: _odometerOutCtrl.text.trim(),
          fuelGauge: _fuelGauge,
          selectedServiceTypes: _selectedServiceTypes.toList(),
          receivingDate: _receivingDateTime,
          deliveryDate: _expectedDateTime,
          paymentMode: _paymentMethod,
          specificInfo: _specificInfoCtrl.text.trim(),
          damageChecklist: damageChecklistData,
          customerAuthSignature: _customerAuthSigPath,
          customerDeliverySignature: _customerDeliverySigPath,
          serviceAdvisorSignature: _advisorSigPath,
          authorizedSignature: _authorizedSigPath,
          serviceLabour: _serviceLabour > 0 ? _serviceLabour : _grandTotal,
          partsTotal: _parts,
          discount: _discount,
          grandTotal: _grandTotal,
        );
      }

      Get.back(result: true);
      Get.snackbar('Job Card Saved', 'Job Card #${job.jobNumber} created & PDF generated successfully', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save Job Card: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A6836).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.assignment_rounded, color: Color(0xFF0A6836), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DAWOOD'S GARAGE - REPAIR ORDER / INVOICE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A6836)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Job Card #${_jobNumberCtrl.text}  |  Detail & Performance',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HEADER DETAILS (R.O #, Tech, Date)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          TextFormField(
                            controller: _jobNumberCtrl,
                            decoration: const InputDecoration(labelText: 'R.O # / Job Card Number *', isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _technicianCtrl,
                                  decoration: const InputDecoration(labelText: 'Assigned Technician (Tech) *', isDense: true),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Date', isDense: true),
                                  child: Text(Formatters.date(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _jobNumberCtrl,
                            decoration: const InputDecoration(labelText: 'R.O # / Job Card Number *', isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _technicianCtrl,
                            decoration: const InputDecoration(labelText: 'Assigned Technician (Tech) *', isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date', isDense: true),
                            child: Text(Formatters.date(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 2. THREE-COLUMN INFO CARDS (Customer, Vehicle, Service)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0A6836).withValues(alpha: 0.3)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildCustomerCol()),
                                const VerticalDivider(width: 24),
                                Expanded(child: _buildVehicleCol()),
                                const VerticalDivider(width: 24),
                                Expanded(child: _buildServiceCol()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildCustomerCol(),
                                const Divider(height: 20),
                                _buildVehicleCol(),
                                const Divider(height: 20),
                                _buildServiceCol(),
                              ],
                            );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 3. PAYMENT MODE & SPECIFIC INFORMATION
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          const Text('Payment Mode: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0A6836))),
                          ...['Cash', 'BTC', 'Online', 'Others'].map((mode) {
                            final isSel = _paymentMethod == mode;
                            return ChoiceChip(
                              label: Text(mode, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              selected: isSel,
                              selectedColor: const Color(0xFF0A6836).withValues(alpha: 0.2),
                              onSelected: (sel) {
                                if (sel) setState(() => _paymentMethod = mode);
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _specificInfoCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Specific Information (any alteration) / Notes',
                          hintText: 'Customer requests, custom detailing directions, alterations...',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. MIDDLE SECTION: SERVICES TABLE & DAMAGE CHECKLIST
                const Text(
                  '* Should any defects are detected in the inspection, indicate them with marks on the diagram & checklist.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF0A6836), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    final servicesCard = Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Services & Labour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0A6836))),
                              TextButton.icon(
                                onPressed: () => setState(() => _serviceRows.add(ServiceRowItem())),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('+ Add Row', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _serviceRows.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final row = _serviceRows[index];
                              return Row(
                                children: [
                                  Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: row.descriptionCtrl,
                                      decoration: const InputDecoration(labelText: 'Description', isDense: true),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: row.amountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Amount', isDense: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  if (_serviceRows.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                                      onPressed: () => setState(() => _serviceRows.removeAt(index)),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );

                    final checklistCard = Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.checklist_rounded, size: 16, color: Color(0xFF0A6836)),
                              SizedBox(width: 4),
                              Text('Check For Damage Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A6836))),
                            ],
                          ),
                          const Divider(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _checklistNames.map((name) {
                              final isChecked = _checklistStatus[name] ?? true;
                              return FilterChip(
                                label: Text(name, style: TextStyle(fontSize: 10, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
                                selected: isChecked,
                                selectedColor: const Color(0xFF0A6836).withValues(alpha: 0.15),
                                checkmarkColor: const Color(0xFF0A6836),
                                padding: const EdgeInsets.all(2),
                                visualDensity: VisualDensity.compact,
                                onSelected: (val) {
                                  setState(() => _checklistStatus[name] = val);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: servicesCard),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: checklistCard),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          servicesCard,
                          const SizedBox(height: 12),
                          checklistCard,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 5. FINANCIAL TOTALS CARD
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A6836).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0A6836).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          if (isNarrow)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _labourAmountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Labour (Rs.)', isDense: true),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _partsAmountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Parts (Rs.)', isDense: true),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _discountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Discount (Rs.)', isDense: true),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _paidAmountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Paid (Rs.)', isDense: true),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _labourAmountCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(labelText: 'Service Labour (Rs.)', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _partsAmountCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(labelText: 'Parts (Rs.)', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _discountCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(labelText: 'Discount (Rs.)', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _paidAmountCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(labelText: 'Paid (Rs.)', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text('Grand Total: ${Formatters.currency(_grandTotal, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0A6836))),
                              Text('Remaining Due: ${Formatters.currency(_remaining, symbol: currency)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _remaining > 0 ? AppColors.error : AppColors.success)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 6. DISCLAIMERS & SIGNATURES
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "I hereby authorise the repair work set to be done along with necessary services and materials. I grant you and your employee permission to operate the vehicle in your premises. Any pre-existing faults are my responsibility. Dawood's Garage will not be responsible for any unforeseen damage including accident, fire, theft or any other event beyond our control. All charges are to be paid before the delivery of the vehicle.",
                        style: TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 650;
                          final b1 = _buildSignatureBox('Customer (Authorisation)', _customerAuthSigPath, (p) => setState(() => _customerAuthSigPath = p));
                          final b2 = _buildSignatureBox('Customer (Delivery)', _customerDeliverySigPath, (p) => setState(() => _customerDeliverySigPath = p));
                          final b3 = _buildSignatureBox('Service Advisor', _advisorSigPath, (p) => setState(() => _advisorSigPath = p));
                          final b4 = _buildSignatureBox('Authorized Sig', _authorizedSigPath, (p) => setState(() => _authorizedSigPath = p));

                          if (isNarrow) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: b1),
                                    const SizedBox(width: 8),
                                    Expanded(child: b2),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: b3),
                                    const SizedBox(width: 8),
                                    Expanded(child: b4),
                                  ],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: b1),
                              const SizedBox(width: 10),
                              Expanded(child: b2),
                              const SizedBox(width: 10),
                              Expanded(child: b3),
                              const SizedBox(width: 10),
                              Expanded(child: b4),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A6836),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _saveAndGeneratePdf,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.print_rounded),
          label: const Text('Save Job Card & Print PDF'),
        ),
      ],
    );
  }

  Widget _buildCustomerCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A6836))),
        const SizedBox(height: 8),
        Text('Name: ${widget.customer.fullName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Contact: ${widget.customer.phone}', style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'Company Name', isDense: true),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _customerAddressCtrl,
          decoration: const InputDecoration(labelText: 'Current Address', isDense: true),
        ),
      ],
    );
  }

  Widget _buildVehicleCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A6836))),
        const SizedBox(height: 8),
        Text('Reg #: ${widget.vehicle.registrationNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A6836))),
        Text('Model: ${widget.vehicle.make} ${widget.vehicle.model}', style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _variantCtrl,
                decoration: const InputDecoration(labelText: 'Varient', isDense: true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                controller: _modelYearCtrl,
                decoration: const InputDecoration(labelText: 'Model Year', isDense: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _chassisCtrl,
          decoration: const InputDecoration(labelText: 'Chassis # (VIN)', isDense: true),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _odometerInCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Odo In (KM)', isDense: true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                controller: _odometerOutCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Odo Out (KM)', isDense: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Fuel Gauge
        Row(
          children: [
            const Text('Fuel: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0A6836))),
            ...['E', '1/4', '1/2', '3/4', 'F'].map((lvl) {
              final isSel = _fuelGauge == lvl;
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: ChoiceChip(
                  label: Text(lvl, style: TextStyle(fontSize: 9, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  selected: isSel,
                  selectedColor: const Color(0xFF0A6836).withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  onSelected: (s) {
                    if (s) setState(() => _fuelGauge = lvl);
                  },
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A6836))),
        const SizedBox(height: 6),
        const Text('Type of Service:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: ['PPF', 'Detailing', 'Wash', 'Tuning', 'Polish', 'Others'].map((st) {
            final isSel = _selectedServiceTypes.contains(st);
            return FilterChip(
              label: Text(st, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
              selected: isSel,
              selectedColor: const Color(0xFF0A6836).withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedServiceTypes.add(st);
                  } else {
                    _selectedServiceTypes.remove(st);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Receiving Date & Time', isDense: true),
          child: Text(Formatters.dateTime(_receivingDateTime), style: const TextStyle(fontSize: 11)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _expectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (d != null) setState(() => _expectedDateTime = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Promise/Delivery Date', isDense: true),
            child: Text(Formatters.dateTime(_expectedDateTime), style: const TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureBox(String role, String? path, Function(String) onSigned) {
    final hasSignature = path != null && File(path).existsSync();

    return InkWell(
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (_) => DigitalSignatureDialog(
            title: 'Sign: $role',
            signerRole: role,
          ),
        );
        if (result != null) {
          onSigned(result);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 75,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasSignature ? const Color(0xFF0A6836) : AppColors.borderDark,
            width: hasSignature ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasSignature) ...[
              Expanded(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_rounded, color: Color(0xFF0A6836)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$role (Signed)',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0A6836)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.textDarkSecondary),
              const SizedBox(height: 2),
              Text(
                role,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
