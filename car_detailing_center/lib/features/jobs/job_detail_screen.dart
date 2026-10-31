import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/job_model.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../invoices/invoice_create_dialog.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobModel _job;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _jobServices = [];

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    final jobRepo = Get.find<JobRepository>();
    final details = await jobRepo.getJobById(_job.id);
    if (details != null && mounted) {
      setState(() {
        _jobServices = List<Map<String, dynamic>>.from(details['services'] ?? []);
        final status = details['status'] as String? ?? _job.status;
        _job = _job.copyWith(
          status: status,
          grandTotal: (details['grand_total'] as num?)?.toDouble() ?? _job.grandTotal,
          paidAmount: (details['paid_amount'] as num?)?.toDouble() ?? _job.paidAmount,
          remainingAmount: (details['remaining_amount'] as num?)?.toDouble() ?? _job.remainingAmount,
        );
      });
    }
  }

  void _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    final jobRepo = Get.find<JobRepository>();

    try {
      await jobRepo.updateJobStatus(
        _job.id,
        newStatus,
        actualDeliveryDate: (newStatus == 'Delivered' || newStatus == 'Completed') ? DateTime.now() : null,
      );

      setState(() => _job = _job.copyWith(status: newStatus));
      Get.snackbar('Status Updated', 'Job status moved to $newStatus', backgroundColor: AppColors.success.withValues(alpha: 0.2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _recordStockDeductionDialog() async {
    final invRepo = Get.find<InventoryRepository>();
    final allItems = await invRepo.getItems();

    if (allItems.isEmpty) {
      Get.snackbar('Inventory Empty', 'Please register stock items in the Inventory module first', backgroundColor: AppColors.warning.withValues(alpha: 0.2));
      return;
    }

    InventoryItemModel selectedItem = allItems.first;
    final qtyCtrl = TextEditingController(text: '1');

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Record Consumable / Material Usage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select materials used from garage inventory for this job card:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<InventoryItemModel>(
                    value: selectedItem,
                    decoration: const InputDecoration(labelText: 'Stock Item'),
                    items: allItems.map((item) => DropdownMenuItem(value: item, child: Text('${item.name} (${item.quantity} ${item.unit} available)'))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedItem = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    decoration: InputDecoration(labelText: 'Quantity Used (${selectedItem.unit})'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                    if (qty <= 0) return;
                    try {
                      await invRepo.adjustStock(
                        itemId: selectedItem.id,
                        changeAmount: -qty,
                        transactionType: 'Job Usage',
                        reasonNotes: 'Material usage on Job #${_job.jobNumber}',
                        jobId: _job.id,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      Get.snackbar('Stock Deducted', 'Deducted $qty ${selectedItem.unit} of ${selectedItem.name}', backgroundColor: AppColors.success.withValues(alpha: 0.2));
                    } catch (e) {
                      Get.snackbar('Error', '$e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                    }
                  },
                  child: const Text('Deduct From Stock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditServicesPricesDialog() async {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final List<Map<String, dynamic>> tempServices = _jobServices.map((s) => {
      'description': s['description'] ?? 'Detailing Service',
      'amount': (s['amount'] as num?)?.toDouble() ?? 0.0,
    }).toList();
    final discountCtrl = TextEditingController(text: _job.discount.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final subtotal = tempServices.fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
            final disc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
            final grand = (subtotal - disc).clamp(0.0, double.infinity);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Services & Job Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adjust the price of any service or package on this job card:',
                        style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 14),
                      ...tempServices.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final priceCtrl = TextEditingController(text: ((s['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              final isNarrow = constraints.maxWidth < 360;
                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s['description'] as String? ?? 'Service',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                          tooltip: 'Remove service',
                                          onPressed: () {
                                            setDlgState(() {
                                              tempServices.removeAt(idx);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    TextFormField(
                                      controller: priceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Price ($currency)',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) {
                                        final p = double.tryParse(v.trim());
                                        if (p != null) {
                                          s['amount'] = p;
                                          setDlgState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      s['description'] as String? ?? 'Service',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 130,
                                    child: TextFormField(
                                      controller: priceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Price ($currency)',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) {
                                        final p = double.tryParse(v.trim());
                                        if (p != null) {
                                          s['amount'] = p;
                                          setDlgState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    tooltip: 'Remove service',
                                    onPressed: () {
                                      setDlgState(() {
                                        tempServices.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Another Operation / Service'),
                          onPressed: () async {
                            final nameCtrl = TextEditingController();
                            final pCtrl = TextEditingController();
                            await showDialog(
                              context: ctx,
                              builder: (subCtx) => AlertDialog(
                                title: const Text('Add Service Line'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name')),
                                    const SizedBox(height: 8),
                                    TextField(controller: pCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(subCtx), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (nameCtrl.text.trim().isNotEmpty) {
                                        setDlgState(() {
                                          tempServices.add({
                                            'description': nameCtrl.text.trim(),
                                            'amount': double.tryParse(pCtrl.text.trim()) ?? 0.0,
                                          });
                                        });
                                        Navigator.pop(subCtx);
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount',
                                isDense: true,
                              ),
                              onChanged: (_) => setDlgState(() {}),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Subtotal: ${Formatters.currency(subtotal, symbol: currency)}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                              Text(
                                'Grand Total: ${Formatters.currency(grand, symbol: currency)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final jobRepo = Get.find<JobRepository>();
                    await jobRepo.updateJobServices(
                      jobId: _job.id,
                      services: tempServices,
                      serviceLabour: subtotal,
                      discount: disc,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadJobDetails();
                    Get.snackbar(
                      'Pricing Updated',
                      'Job services & prices updated successfully',
                      backgroundColor: AppColors.success.withValues(alpha: 0.2),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Card: ${_job.jobNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print Digital Job Card',
            onPressed: () async {
              final business = AuthService.to.currentBusiness.value;
              if (business != null) {
                await PdfService.printJobCard(business: business, job: _job);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 650;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_job.jobNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.getJobStatusColor(_job.status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _job.status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getJobStatusColor(_job.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Total: ${Formatters.currency(_job.grandTotal, symbol: currency)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                                    const SizedBox(height: 4),
                                    Text(_job.customerName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                    Text('Phone: ${_job.customerPhone}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                                    const SizedBox(height: 4),
                                    Text(_job.vehicleDisplayName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                    Text('Plate #: ${_job.vehicleRegNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                                    const SizedBox(height: 4),
                                    Text('Paid: ${Formatters.currency(_job.paidAmount, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      'Remaining: ${Formatters.currency(_job.remainingAmount, symbol: currency)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _job.remainingAmount > 0 ? AppColors.error : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                              const SizedBox(height: 4),
                              Text(_job.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Phone: ${_job.customerPhone}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                              const Divider(height: 16),
                              const Text('Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                              const SizedBox(height: 4),
                              Text(_job.vehicleDisplayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Plate #: ${_job.vehicleRegNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                              const Divider(height: 16),
                              const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                              const SizedBox(height: 4),
                              Text('Paid: ${Formatters.currency(_job.paidAmount, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                'Remaining: ${Formatters.currency(_job.remainingAmount, symbol: currency)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _job.remainingAmount > 0 ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Interactive Workflow Status Progression Pipeline
            _buildWorkflowStatusCard(),
            const SizedBox(height: 20),

            // Services Rendered
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                const Text('Services & Labour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showEditServicesPricesDialog,
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Edit Prices & Services'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _recordStockDeductionDialog,
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Record Chemical / Stock Usage'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_jobServices.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No service items listed.'))))
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _jobServices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = _jobServices[i];
                    final desc = item['description'] ?? 'Detailing Service';
                    final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                    return ListTile(
                      title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formatters.currency(amt, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryLight),
                            tooltip: 'Edit price',
                            onPressed: _showEditServicesPricesDialog,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Billing / Invoice Action
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobileCard = constraints.maxWidth < 540;
                    if (isMobileCard) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Generate Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Issue a formatted invoice and collect remaining customer payment.', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long_rounded),
                            label: const Text('Create Invoice from Job'),
                            onPressed: () async {
                              final res = await showDialog(
                                context: context,
                                builder: (_) => InvoiceCreateDialog(preselectedJob: _job),
                              );
                              if (res == true) _loadJobDetails();
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Generate Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Issue a formatted invoice and collect remaining customer payment.', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text('Create Invoice from Job'),
                          onPressed: () async {
                            final res = await showDialog(
                              context: context,
                              builder: (_) => InvoiceCreateDialog(preselectedJob: _job),
                            );
                            if (res == true) _loadJobDetails();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _nextLogicalStatus {
    switch (_job.status) {
      case 'New':
      case 'Inspection Pending':
      case 'Waiting':
        return 'In Progress';
      case 'In Progress':
        return 'Ready for Delivery';
      case 'Ready for Delivery':
        return 'Delivered';
      case 'Delivered':
        return 'Completed';
      default:
        return null;
    }
  }

  Widget _buildWorkflowStatusCard() {
    final nextStatus = _nextLogicalStatus;
    const primaryStages = ['New', 'In Progress', 'Ready for Delivery', 'Completed'];
    final currentStatusIdx = primaryStages.indexOf(_job.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Service Progression & Floor Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.getJobStatusColor(_job.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.getJobStatusColor(_job.status).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Current: ${_job.status}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.getJobStatusColor(_job.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visual Pipeline Stepper
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(primaryStages.length, (i) {
                  final stage = primaryStages[i];
                  final isDone = currentStatusIdx >= i || (_job.status == 'Delivered' && i <= 2);
                  final isCurrent = _job.status == stage || (_job.status == 'Delivered' && stage == 'Ready for Delivery');
                  final color = isCurrent
                      ? AppColors.getJobStatusColor(stage)
                      : isDone
                          ? AppColors.success
                          : AppColors.textDarkMuted;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _isProcessing ? null : () => _updateStatus(stage),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrent ? color.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color, width: isCurrent ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                stage,
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                  color: isCurrent ? Colors.white : AppColors.textDarkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < primaryStages.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: isDone ? AppColors.success : AppColors.textDarkMuted),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 1-Click Fast Advance Button
            if (nextStatus != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _updateStatus(nextStatus),
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.fast_forward_rounded, size: 18),
                  label: Text('Advance to Next Stage ➔ $nextStatus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getJobStatusColor(nextStatus),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Other statuses (Dropdown / chips)
            Row(
              children: [
                const Text('More Actions / Override: ', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.allJobStatuses.where((s) => s != _job.status && s != nextStatus).map((st) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _isProcessing ? null : () => _updateStatus(st),
                            child: Text(st, style: const TextStyle(fontSize: 11)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
