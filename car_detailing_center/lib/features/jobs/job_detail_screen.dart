import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                              const SizedBox(height: 4),
                              Text(_job.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                              Text(_job.vehicleDisplayName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Workflow Status Progression Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Update Workflow Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.allJobStatuses.map((st) {
                        final isCurrent = _job.status == st;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrent ? AppColors.getJobStatusColor(st) : Colors.grey.withValues(alpha: 0.15),
                            foregroundColor: isCurrent ? Colors.white : AppColors.textDark,
                          ),
                          onPressed: _isProcessing ? null : () => _updateStatus(st),
                          child: Text(st),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Services Rendered
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Services & Labour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _recordStockDeductionDialog,
                  icon: const Icon(Icons.inventory_2_rounded, size: 16),
                  label: const Text('Record Chemical / Stock Usage'),
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
                      trailing: Text(Formatters.currency(amt, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Billing / Invoice Action
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Issue a formatted invoice and collect remaining customer payment.', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                      ],
                    ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
