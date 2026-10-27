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
  late final TextEditingController _odometerInCtrl;
  late final TextEditingController _odometerOutCtrl;
  late final TextEditingController _specialInstructionsCtrl;
  late final TextEditingController _specificInfoCtrl; // Section 31
  late final TextEditingController _labourAmountCtrl;
  late final TextEditingController _partsAmountCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _paidAmountCtrl;

  final DateTime _receivingDateTime = DateTime.now();
  DateTime _expectedDateTime = DateTime.now().add(const Duration(hours: 4));
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  String? _customerSignaturePath;
  String? _advisorSignaturePath;
  String? _authorizedSignaturePath;

  final List<ServiceRowItem> _serviceRows = [];

  @override
  void initState() {
    super.initState();
    final j = widget.existingJob;
    final prefix = AuthService.to.currentBusiness.value?.jobPrefix ?? 'JOB-';
    _jobNumberCtrl = TextEditingController(text: j?.jobNumber ?? '$prefix${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _technicianCtrl = TextEditingController(text: j?.assignedStaffNames.isNotEmpty == true ? j!.assignedStaffNames.first : 'Lead Technician');
    _odometerInCtrl = TextEditingController(text: widget.vehicle.mileage?.toString() ?? '');
    _odometerOutCtrl = TextEditingController(text: widget.vehicle.mileage?.toString() ?? '');
    _specialInstructionsCtrl = TextEditingController(text: j?.notes ?? '');
    _specificInfoCtrl = TextEditingController();
    _labourAmountCtrl = TextEditingController(text: j != null ? j.subtotal.toStringAsFixed(0) : '0');
    _partsAmountCtrl = TextEditingController(text: '0');
    _discountCtrl = TextEditingController(text: j != null ? j.discount.toStringAsFixed(0) : '0');
    _paidAmountCtrl = TextEditingController(text: j != null ? j.paidAmount.toStringAsFixed(0) : '0');

    if (j != null && j.services.isNotEmpty) {
      for (var s in j.services) {
        _serviceRows.add(ServiceRowItem(description: s.serviceName, amount: s.price));
      }
    } else {
      _serviceRows.add(ServiceRowItem(description: 'Full Exterior Wash & Clay Treatment', amount: 3000));
      _serviceRows.add(ServiceRowItem(description: 'Interior Deep Detailing & Shampoo', amount: 5000));
    }
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
      subtotal: _serviceLabour + _parts,
      discount: _discount,
      grandTotal: _grandTotal,
      paidAmount: _paid,
      remainingAmount: _remaining,
      customerSignature: _customerSignaturePath,
      serviceAdvisorSignature: _advisorSignaturePath,
      authorizedSignature: _authorizedSignaturePath,
      notes: '${_specificInfoCtrl.text.trim()} | Instructions: ${_specialInstructionsCtrl.text.trim()}',
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
        specialInstructions: '${_specificInfoCtrl.text.trim()} | Instructions: ${_specialInstructionsCtrl.text.trim()}',
        serviceLabour: _serviceLabour,
        partsTotal: _parts,
        discount: _discount,
        paidAmount: _paid,
        customerSignature: _customerSignaturePath,
        serviceAdvisorSignature: _advisorSignaturePath,
        authorizedSignature: _authorizedSignaturePath,
        services: services.map((s) => {'description': s.serviceName, 'amount': s.price}).toList(),
      );

      final business = AuthService.to.currentBusiness.value;
      if (business != null) {
        await PdfService.printJobCard(business: business, job: job);
      }

      Get.back(result: true);
      Get.snackbar('Job Card Saved', 'Job Card #${job.jobNumber} created & PDF prepared', backgroundColor: AppColors.success.withValues(alpha: 0.2));
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
      title: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Digital Job Card / Repair Order (${_jobNumberCtrl.text})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 580;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Details Row: R.O #, Technician, Date
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _jobNumberCtrl,
                              decoration: const InputDecoration(labelText: 'R.O / Job Card Number *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _technicianCtrl,
                              decoration: const InputDecoration(labelText: 'Assigned Technician *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Order Date'),
                              child: Text(Formatters.date(DateTime.now())),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TextFormField(
                        controller: _jobNumberCtrl,
                        decoration: const InputDecoration(labelText: 'R.O / Job Card Number *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _technicianCtrl,
                        decoration: const InputDecoration(labelText: 'Assigned Technician *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Order Date'),
                        child: Text(Formatters.date(DateTime.now())),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Customer & Vehicle Info Cards
                    Card(
                      color: AppColors.backgroundDark.withValues(alpha: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer & Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                            const SizedBox(height: 8),
                            if (isWide) ...[
                              Row(
                                children: [
                                  Expanded(child: Text('Customer: ${widget.customer.fullName}', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                  Expanded(child: Text('Phone: ${widget.customer.phone}', overflow: TextOverflow.ellipsis)),
                                  Expanded(child: Text('Address: ${widget.customer.address ?? "-"}', overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: Text('Vehicle: ${widget.vehicle.make} ${widget.vehicle.model}', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                  Expanded(child: Text('Plate Number: ${widget.vehicle.registrationNumber}', overflow: TextOverflow.ellipsis)),
                                  Expanded(child: Text('Year: ${widget.vehicle.year ?? "-"}', overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ] else ...[
                              Text('Customer: ${widget.customer.fullName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Phone: ${widget.customer.phone}'),
                              if (widget.customer.address != null) ...[
                                const SizedBox(height: 4),
                                Text('Address: ${widget.customer.address}'),
                              ],
                              const Divider(height: 16),
                              Text('Vehicle: ${widget.vehicle.make} ${widget.vehicle.model}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Plate Number: ${widget.vehicle.registrationNumber}'),
                              if (widget.vehicle.year != null) ...[
                                const SizedBox(height: 4),
                                Text('Year: ${widget.vehicle.year}'),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Odometer In / Out
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _odometerInCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Odometer In (KM)'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _odometerOutCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Odometer Out (KM)'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: const InputDecoration(labelText: 'Payment Method'),
                              items: ['Cash', 'Online', 'Bank', 'Other']
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _paymentMethod = val);
                              },
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TextFormField(
                        controller: _odometerInCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Odometer In (KM)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _odometerOutCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Odometer Out (KM)'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: ['Cash', 'Online', 'Bank', 'Other']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Schedule Dates: Receiving, Expected/Promise, Delivery
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Receiving Date & Time'),
                              child: Text(Formatters.dateTime(_receivingDateTime)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _expectedDateTime,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (d != null) setState(() => _expectedDateTime = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Expected / Promise Date'),
                                child: Text(Formatters.date(_expectedDateTime)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Receiving Date & Time'),
                        child: Text(Formatters.dateTime(_receivingDateTime)),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _expectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (d != null) setState(() => _expectedDateTime = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Expected / Promise Date'),
                          child: Text(Formatters.date(_expectedDateTime)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Section 31: Specific Information / Any Alteration
                    TextFormField(
                      controller: _specificInfoCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Specific Information / Any Alteration *',
                        hintText: 'Customer requests, pre-existing issues, alterations, or custom detailing guidelines...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 32: Service Items Table (Sr #, Description, Amount)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service Items & Labour (Multi-Row)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _serviceRows.add(ServiceRowItem());
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Add Row'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _serviceRows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = _serviceRows[index];
                        return Row(
                          children: [
                            Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: row.descriptionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Description / Work',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: row.amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            if (_serviceRows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                onPressed: () => setState(() => _serviceRows.removeAt(index)),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section 34: Financial Summary (Service Labour, Parts, Discount, Grand Total, Paid, Remaining)
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            if (isWide)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _partsAmountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Parts (Rs.)'),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _discountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Discount (Rs.)'),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _paidAmountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Paid (Rs.)'),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              TextFormField(
                                controller: _partsAmountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Parts (Rs.)'),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _discountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Discount (Rs.)'),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _paidAmountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Paid (Rs.)'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                Text('Grand Total: ${Formatters.currency(_grandTotal, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryLight)),
                                Text('Remaining Due: ${Formatters.currency(_remaining, symbol: currency)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _remaining > 0 ? AppColors.error : AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                // Section 9 & 35: Interactive Digital Signatures
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.draw_rounded, color: AppColors.primaryLight, size: 20),
                          SizedBox(width: 8),
                          Text('Digital Signatures (Click to sign / re-sign):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 580;
                          return isWide
                              ? Row(
                                  children: [
                                    Expanded(child: _buildSignatureBox('Customer Signature', _customerSignaturePath, (path) => setState(() => _customerSignaturePath = path))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildSignatureBox('Service Advisor', _advisorSignaturePath, (path) => setState(() => _advisorSignaturePath = path))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildSignatureBox('Authorized Signatory', _authorizedSignaturePath, (path) => setState(() => _authorizedSignaturePath = path))),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildSignatureBox('Customer Signature', _customerSignaturePath, (path) => setState(() => _customerSignaturePath = path)),
                                    const SizedBox(height: 10),
                                    _buildSignatureBox('Service Advisor', _advisorSignaturePath, (path) => setState(() => _advisorSignaturePath = path)),
                                    const SizedBox(height: 10),
                                    _buildSignatureBox('Authorized Signatory', _authorizedSignaturePath, (path) => setState(() => _authorizedSignaturePath = path)),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAndGeneratePdf,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.print_rounded),
          label: const Text('Save Job Card & Print PDF'),
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
            title: 'Sign as $role',
            signerRole: role,
          ),
        );
        if (result != null) {
          onSigned(result);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 85,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasSignature ? AppColors.success : AppColors.borderDark,
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
                  errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_rounded, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$role (Signed)',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ] else ...[
              const Icon(Icons.edit_note_rounded, size: 26, color: AppColors.textDarkSecondary),
              const SizedBox(height: 4),
              Text(
                'Tap to sign: $role',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
