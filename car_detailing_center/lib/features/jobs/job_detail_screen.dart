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
import '../inventory/inventory_form_dialog.dart';
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

  int _getStatusRank(String status) {
    switch (status) {
      case 'New':
        return 0;
      case 'Inspection Pending':
        return 1;
      case 'Waiting':
        return 2;
      case 'In Progress':
        return 3;
      case 'Ready for Delivery':
        return 4;
      case 'Delivered':
        return 5;
      case 'Completed':
        return 6;
      case 'Cancelled':
        return 999;
      default:
        return 0;
    }
  }

  void _updateStatus(String newStatus) async {
    final currentRank = _getStatusRank(_job.status);
    final targetRank = _getStatusRank(newStatus);

    if (_job.status == 'Completed') {
      Get.snackbar(
        'Job Finalized',
        'This job is already completed and cannot be modified.',
        backgroundColor: AppColors.warning.withValues(alpha: 0.2),
      );
      return;
    }

    if (_job.status == 'Cancelled') {
      Get.snackbar(
        'Job Cancelled',
        'This job is cancelled.',
        backgroundColor: AppColors.warning.withValues(alpha: 0.2),
      );
      return;
    }

    // STRICT FORWARD CHECK: Service progression cannot move backward
    if (newStatus != 'Cancelled' && targetRank < currentRank) {
      Get.snackbar(
        'Action Blocked',
        'Vehicle progression cannot be moved backward to a previous stage ($newStatus).',
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
      );
      return;
    }

    if (newStatus == _job.status) return;

    setState(() => _isProcessing = true);
    final jobRepo = Get.find<JobRepository>();

    try {
      await jobRepo.updateJobStatus(
        _job.id,
        newStatus,
        actualDeliveryDate: (newStatus == 'Delivered' || newStatus == 'Completed') ? DateTime.now() : null,
      );

      setState(() => _job = _job.copyWith(status: newStatus));
      if (newStatus == 'Completed' || newStatus == 'Delivered') {
        Get.snackbar(
          'Order Completed!',
          'Job order completed & archived to Vehicle Service History. Removed from active workshop orders.',
          backgroundColor: AppColors.success.withValues(alpha: 0.25),
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar('Status Updated', 'Job status moved forward to $newStatus', backgroundColor: AppColors.success.withValues(alpha: 0.2));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showEditAdvanceDialog(String currency) {
    final ctrl = TextEditingController(text: _job.paidAmount > 0 ? _job.paidAmount.toStringAsFixed(0) : '0');
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.payments_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Record / Edit Advance Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Total: ${Formatters.currency(_job.grandTotal, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Advance Amount Received',
                prefixIcon: Icon(Icons.currency_exchange_rounded),
                hintText: 'e.g. 5000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
              final jobRepo = Get.find<JobRepository>();
              await jobRepo.updateJobAdvancePayment(jobId: _job.id, paidAmount: val);
              Get.back();
              await _loadJobDetails();
              Get.snackbar(
                'Advance Updated',
                'Advance payment updated to ${Formatters.currency(val, symbol: currency)}',
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
              );
            },
            child: const Text('Save Advance'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() async {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final jobRepo = Get.find<JobRepository>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text('Add Service / Labour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Service / Operation Name *',
                        hintText: 'e.g. Polish, Wash, Labour, Wax',
                        prefixIcon: Icon(Icons.build_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price / Labour Charge ($currency) *',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.payments_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description / Notes',
                        hintText: 'e.g. Details, warranty, panel info...',
                        prefixIcon: Icon(Icons.description_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('Required', 'Please enter a service name', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                      return;
                    }
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final desc = descCtrl.text.trim();
                    final fullDescription = desc.isNotEmpty ? '$name - $desc' : name;
                    try {
                      await jobRepo.addServiceToJob(
                        jobId: _job.id,
                        description: fullDescription,
                        amount: price,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadJobDetails();
                      Get.snackbar(
                        'Service Added',
                        'Added "$fullDescription" ($currency $price) to Job #${_job.jobNumber}',
                        backgroundColor: AppColors.success.withValues(alpha: 0.2),
                      );
                    } catch (e) {
                      Get.snackbar('Error', '$e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                    }
                  },
                  child: const Text('Add Service'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordStockDeductionDialog() async {
    final invRepo = Get.find<InventoryRepository>();
    final jobRepo = Get.find<JobRepository>();
    final allItems = await invRepo.getItems();

    if (allItems.isEmpty) {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.inventory_2_outlined, color: AppColors.warning, size: 22),
              SizedBox(width: 8),
              Text('Inventory is Empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'No stock items or chemicals are registered in the inventory yet.\n\nWould you like to register a new stock item now?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Stock Item Now'),
            ),
          ],
        ),
      );

      if (shouldAdd == true && mounted) {
        final added = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InventoryFormDialog(),
        );
        if (added == true && mounted) {
          _recordStockDeductionDialog();
        }
      }
      return;
    }

    InventoryItemModel selectedItem = allItems.first;
    final qtyCtrl = TextEditingController(text: '1');
    final defaultPrice = selectedItem.sellingPrice > 0 ? selectedItem.sellingPrice : selectedItem.purchasePrice;
    final priceCtrl = TextEditingController(text: defaultPrice.toStringAsFixed(0));
    bool billToCustomer = true;
    String selectedStaff = _job.assignedStaffNames.isNotEmpty ? _job.assignedStaffNames.first : 'Shop Lead';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.inventory_2_rounded, color: AppColors.primaryLight, size: 22),
                      SizedBox(width: 8),
                      Text('Stock / Chemical Usage', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final added = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const InventoryFormDialog(),
                      );
                      if (added == true && mounted) {
                        Navigator.of(ctx).pop();
                        _recordStockDeductionDialog();
                      }
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('New Item', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select chemical or material used for this job:', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InventoryItemModel>(
                      value: selectedItem,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Stock Item *'),
                      items: allItems.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text('${item.name} (${item.quantity} ${item.unit} available)', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedItem = val;
                            final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                            final unitP = val.sellingPrice > 0 ? val.sellingPrice : val.purchasePrice;
                            priceCtrl.text = (unitP * qty).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStaff,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Staff Member (Who Took Item) *',
                        prefixIcon: Icon(Icons.person_rounded, size: 18),
                      ),
                      items: [
                        ..._job.assignedStaffNames.map((s) => DropdownMenuItem(value: s, child: Text('$s (Assigned Staff)'))),
                        if (!_job.assignedStaffNames.contains('Shop Lead'))
                          const DropdownMenuItem(value: 'Shop Lead', child: Text('Shop Lead')),
                        if (!_job.assignedStaffNames.contains('General Staff'))
                          const DropdownMenuItem(value: 'General Staff', child: Text('General Staff')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStaff = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            decoration: InputDecoration(labelText: 'Quantity (${selectedItem.unit}) *'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final qty = double.tryParse(v.trim()) ?? 0.0;
                              final unitP = selectedItem.sellingPrice > 0 ? selectedItem.sellingPrice : selectedItem.purchasePrice;
                              priceCtrl.text = (unitP * qty).toStringAsFixed(0);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            decoration: InputDecoration(
                              labelText: 'Price ($currency)',
                              helperText: '0 if complimentary',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: billToCustomer,
                      title: const Text('Add to Job Card / Invoice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Appears in Services & Labour list and adds to grand total', style: TextStyle(fontSize: 11)),
                      onChanged: (v) => setDialogState(() => billToCustomer = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                    if (qty <= 0) {
                      Get.snackbar('Invalid Quantity', 'Please enter a valid quantity greater than 0', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                      return;
                    }
                    final charge = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    try {
                      // 1. Deduct from Inventory with staff & vehicle tracking
                      final carInfo = '${_job.jobNumber} • ${_job.vehicleDisplayName}${_job.vehicleRegNumber.isNotEmpty ? " (${_job.vehicleRegNumber})" : ""}';
                      await invRepo.adjustStock(
                        itemId: selectedItem.id,
                        changeAmount: -qty,
                        transactionType: 'Staff / Job Usage',
                        reasonNotes: 'Material usage on $carInfo',
                        userName: selectedStaff,
                        jobId: carInfo,
                      );

                      // 2. Add as item on Job Card if checked
                      if (billToCustomer) {
                        final desc = '${selectedItem.name} (${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)} ${selectedItem.unit})';
                        await jobRepo.addServiceToJob(
                          jobId: _job.id,
                          description: desc,
                          amount: charge,
                        );
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadJobDetails();
                      Get.snackbar(
                        'Stock & Job Updated',
                        'Deducted $qty ${selectedItem.unit} of ${selectedItem.name}${billToCustomer ? " and added to Job Card ($currency $charge)" : ""}',
                        backgroundColor: AppColors.success.withValues(alpha: 0.2),
                      );
                    } catch (e) {
                      Get.snackbar('Error', '$e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                    }
                  },
                  child: const Text('Deduct & Add to Job'),
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                                        InkWell(
                                          onTap: () => _showEditAdvanceDialog(currency),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryLight),
                                                SizedBox(width: 2),
                                                Text('Advance', style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Paid Advance: ${Formatters.currency(_job.paidAmount, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                                  InkWell(
                                    onTap: () => _showEditAdvanceDialog(currency),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryLight),
                                          SizedBox(width: 2),
                                          Text('Advance', style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Paid Advance: ${Formatters.currency(_job.paidAmount, symbol: currency)}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    ElevatedButton.icon(
                      onPressed: _showAddServiceDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Service / Labour'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _recordStockDeductionDialog,
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Record Chemical / Stock Usage'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showEditServicesPricesDialog,
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Adjust Pricing'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_jobServices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cleaning_services_rounded, size: 38, color: AppColors.textDarkSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        const Text('No service items listed yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text(
                          'Add detailing services, labour, or chemicals from stock for this job card.',
                          style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showAddServiceDialog,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Service / Labour'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _recordStockDeductionDialog,
                              icon: const Icon(Icons.inventory_2_rounded, size: 16),
                              label: const Text('Record Chemical / Stock'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
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
                    final sId = item['id']?.toString() ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                      ),
                      title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formatters.currency(amt, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primaryLight),
                            tooltip: 'Edit price',
                            onPressed: _showEditServicesPricesDialog,
                          ),
                          if (sId.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              tooltip: 'Delete item',
                              onPressed: () async {
                                final jobRepo = Get.find<JobRepository>();
                                await jobRepo.removeServiceFromJob(jobId: _job.id, serviceId: sId);
                                await _loadJobDetails();
                                Get.snackbar('Removed', 'Removed "$desc" from Job Card', backgroundColor: AppColors.warning.withValues(alpha: 0.2));
                              },
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
    const primaryStages = ['New', 'In Progress', 'Ready for Delivery', 'Delivered', 'Completed'];
    final currentRank = _getStatusRank(_job.status);
    final isFinished = _job.status == 'Completed';
    final isCancelled = _job.status == 'Cancelled';

    // Strictly forward statuses that are not current and not the primary nextStatus
    final forwardStatuses = AppConstants.allJobStatuses.where((s) {
      if (s == _job.status || s == nextStatus) return false;
      if (isFinished || isCancelled) return false;
      if (s == 'Cancelled') {
        // Only allow cancel if not already Delivered or Completed
        return currentRank < _getStatusRank('Delivered');
      }
      return _getStatusRank(s) > currentRank;
    }).toList();

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

            // Visual Pipeline Stepper (Forward-Only Progression)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(primaryStages.length, (i) {
                  final stage = primaryStages[i];
                  final stageRank = _getStatusRank(stage);
                  final isDone = currentRank > stageRank;
                  final isCurrent = _job.status == stage;
                  final isFuture = stageRank > currentRank;

                  final color = isCurrent
                      ? AppColors.getJobStatusColor(stage)
                      : isDone
                          ? AppColors.success
                          : AppColors.textDarkMuted;

                  final canTap = isFuture && !_isProcessing && !isFinished && !isCancelled;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: isDone
                            ? '$stage (Completed - progression is forward only)'
                            : isCurrent
                                ? '$stage (Current Status)'
                                : 'Advance to $stage',
                        child: InkWell(
                          onTap: canTap ? () => _updateStatus(stage) : null,
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? color.withValues(alpha: 0.2)
                                  : isDone
                                      ? AppColors.success.withValues(alpha: 0.08)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? color
                                    : (isDone ? AppColors.success.withValues(alpha: 0.4) : color.withValues(alpha: 0.25)),
                                width: isCurrent ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : isCurrent
                                          ? Icons.play_circle_fill_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stage,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                    color: isCurrent
                                        ? Colors.white
                                        : isDone
                                            ? AppColors.success
                                            : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (i < primaryStages.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: currentRank >= _getStatusRank(primaryStages[i + 1])
                                ? AppColors.success
                                : AppColors.textDarkMuted.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 1-Click Fast Advance Button OR Finalized Banner
            if (nextStatus != null && !isFinished && !isCancelled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _updateStatus(nextStatus),
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.fast_forward_rounded, size: 18),
                  label: Text('Advance to Next Stage ➔ $nextStatus', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getJobStatusColor(nextStatus),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (isFinished) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Vehicle Detailing Completed & Delivered (Workflow Finalized)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Strictly Forward Jump Options (No previous stages allowed!)
            if (forwardStatuses.isNotEmpty)
              Row(
                children: [
                  const Text('Jump to Stage: ', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: forwardStatuses.map((st) {
                          final isCancel = st == 'Cancelled';
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isCancel ? AppColors.error : AppColors.getJobStatusColor(st),
                                side: BorderSide(
                                  color: isCancel
                                      ? AppColors.error.withValues(alpha: 0.5)
                                      : AppColors.getJobStatusColor(st).withValues(alpha: 0.5),
                                ),
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
              )
            else if (!isFinished && !isCancelled && nextStatus == null)
              const Text(
                'Workflow reached final stage. Previous stages are locked.',
                style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
  }

