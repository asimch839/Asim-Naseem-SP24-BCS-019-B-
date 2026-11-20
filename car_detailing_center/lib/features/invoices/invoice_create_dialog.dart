import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/job_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_payment_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../inventory/inventory_form_dialog.dart';

class InvoiceCreateDialog extends StatefulWidget {
  final JobModel? preselectedJob;
  final InventoryItemModel? preselectedStockItem;
  final bool isDirectSale;
  const InvoiceCreateDialog({
    super.key,
    this.preselectedJob,
    this.preselectedStockItem,
    this.isDirectSale = false,
  });

  @override
  State<InvoiceCreateDialog> createState() => _InvoiceCreateDialogState();
}

class _InvoiceCreateDialogState extends State<InvoiceCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _paidAmountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = AppConstants.paymentCash;
  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;

  final List<InvoiceItem> _items = [];
  List<CustomerModel> _customers = [];
  List<VehicleModel> _customerVehicles = [];

  double _advancePaid = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final customerRepo = Get.find<CustomerRepository>();
      final customers = await customerRepo.getCustomers();

      CustomerModel? defaultWalkIn = customers.firstWhereOrNull(
        (c) => c.fullName.toLowerCase().contains('walk-in') || c.phone.toLowerCase().contains('walk-in'),
      );

      if (defaultWalkIn == null) {
        try {
          final newCust = CustomerModel(
            id: 'cust_walkin',
            businessId: 'local',
            fullName: 'Walk-in Retail Customer',
            phone: 'Walk-in',
            status: 'Active',
            createdAt: DateTime.now(),
          );
          await customerRepo.saveCustomer(newCust);
          customers.insert(0, newCust);
          defaultWalkIn = newCust;
        } catch (_) {}
      }

      _customers = customers;

      if (widget.preselectedJob != null) {
        final job = widget.preselectedJob!;
        final matchedCustomer = customers.firstWhereOrNull((c) => c.id == job.customerId);
        if (matchedCustomer != null) {
          _selectedCustomer = matchedCustomer;
          final vList = await customerRepo.getCustomerVehicles(matchedCustomer.id);
          _customerVehicles = vList;
          _selectedVehicle = vList.firstWhereOrNull((v) => v.id == job.vehicleId) ?? (vList.isNotEmpty ? vList.first : null);
        }

        // Populate items from job services & recorded work
        final jobRepo = Get.find<JobRepository>();
        final jobDetails = await jobRepo.getJobById(job.id);
        if (jobDetails != null) {
          final svcList = (jobDetails['services'] as List<dynamic>? ?? []);
          for (final s in svcList) {
            final desc = (s['description']?.toString() ?? '').trim();
            final amt = (s['amount'] as num?)?.toDouble() ?? 0.0;
            _items.add(InvoiceItem(
              name: desc.isNotEmpty ? desc : 'Detailing Service',
              type: desc.toLowerCase().contains('stock') || desc.toLowerCase().contains('chemical') || desc.toLowerCase().contains('bottle') || desc.toLowerCase().contains('liter') ? 'product' : 'service',
              quantity: 1.0,
              unitPrice: amt,
              total: amt,
            ));
          }
        }

        if (_items.isEmpty) {
          for (final s in job.services) {
            _items.add(InvoiceItem(
              name: s.serviceName.isNotEmpty ? s.serviceName : 'Detailing Service',
              type: 'service',
              quantity: 1.0,
              unitPrice: s.price,
              total: s.price,
            ));
          }
        }

        final jDiscount = (jobDetails?['discount'] as num?)?.toDouble() ?? job.discount;
        _discountController.text = jDiscount.toStringAsFixed(0);

        final jPaid = (jobDetails?['paid_amount'] as num?)?.toDouble() ?? job.paidAmount;
        _advancePaid = jPaid;

        _syncPaidAmount();
      } else {
        // Direct retail/counter sale: default to Walk-in customer so zero friction
        final custToSelect = defaultWalkIn ?? (customers.isNotEmpty ? customers.first : null);
        if (custToSelect != null) {
          _selectedCustomer = custToSelect;
          final vList = await customerRepo.getCustomerVehicles(custToSelect.id);
          _customerVehicles = vList;
          if (vList.isNotEmpty) _selectedVehicle = vList.first;
        }
      }

      if (widget.preselectedStockItem != null) {
        final p = widget.preselectedStockItem!;
        final price = p.sellingPrice > 0 ? p.sellingPrice : p.purchasePrice;
        _items.add(InvoiceItem(
          name: '${p.name}${p.brand != null && p.brand!.isNotEmpty ? ' (${p.brand})' : ''}',
          type: 'product',
          quantity: 1.0,
          unitPrice: price,
          total: price,
          inventoryItemId: p.id,
        ));
        _syncPaidAmount();
      } else if (widget.isDirectSale) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _items.isEmpty) {
            _addStockItemDialog();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCustomerChanged(CustomerModel? customer, {String? preselectedVehicleId}) async {
    setState(() {
      _selectedCustomer = customer;
      _selectedVehicle = null;
      _customerVehicles = [];
    });

    if (customer != null) {
      final customerRepo = Get.find<CustomerRepository>();
      final vList = await customerRepo.getCustomerVehicles(customer.id);
      if (mounted) {
        setState(() {
          _customerVehicles = vList;
          if (preselectedVehicleId != null) {
            _selectedVehicle = vList.firstWhereOrNull((v) => v.id == preselectedVehicleId);
          } else if (vList.isNotEmpty) {
            _selectedVehicle = vList.first;
          }
        });
      }
    }
  }

  Future<void> _quickAddCustomerDialog() async {
    final nameCtrl = TextEditingController(text: 'Walk-in Retail Customer');
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quick Register Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final custRepo = Get.find<CustomerRepository>();
              final newId = 'cust_${const Uuid().v4().substring(0, 8)}';
              final newCust = CustomerModel(
                id: newId,
                businessId: 'local',
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : 'Walk-in',
                status: 'Active',
                createdAt: DateTime.now(),
              );
              await custRepo.saveCustomer(newCust);
              final allCusts = await custRepo.getCustomers();
              if (mounted) {
                setState(() {
                  _customers = allCusts;
                  _selectedCustomer = allCusts.firstWhereOrNull((c) => c.id == newId) ?? newCust;
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _grandTotal => (_subtotal - _discount).clamp(0.0, double.infinity);
  double get _netPayableAfterAdvance => (_grandTotal - _advancePaid).clamp(0.0, double.infinity);
  double get _paid => double.tryParse(_paidAmountController.text) ?? 0.0;
  double get _totalSettled => _advancePaid + _paid;
  double get _remaining => (_grandTotal - _totalSettled).clamp(0.0, double.infinity);
  bool get _isFullyPaid => _grandTotal > 0 && _totalSettled >= _grandTotal;

  void _syncPaidAmount() {
    _paidAmountController.text = _netPayableAfterAdvance > 0 ? _netPayableAfterAdvance.toStringAsFixed(0) : '0';
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    String type = 'service';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Invoice Line Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item / Service Name *')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity *'), keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price (Unit Price) *'), keyboardType: TextInputType.number),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                if (nameCtrl.text.trim().isNotEmpty && price >= 0) {
                  setState(() {
                    _items.add(InvoiceItem(
                      name: nameCtrl.text.trim(),
                      type: type,
                      quantity: qty,
                      unitPrice: price,
                      total: qty * price,
                    ));
                    _syncPaidAmount();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  void _addStockItemDialog() async {
    final invRepo = InventoryRepository();
    final items = await invRepo.getItems(activeOnly: true);

    if (items.isEmpty) {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.inventory_2_outlined, color: AppColors.warning, size: 22),
              SizedBox(width: 8),
              Text('No Inventory Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'No inventory products registered yet.\n\nWould you like to register a new stock item now?',
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
          _addStockItemDialog();
        }
      }
      return;
    }

    InventoryItemModel selectedProduct = items.first;
    final qtyCtrl = TextEditingController(text: '1');
    final initialPrice = selectedProduct.sellingPrice > 0 ? selectedProduct.sellingPrice : selectedProduct.purchasePrice;
    final priceCtrl = TextEditingController(text: initialPrice.toStringAsFixed(0));

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final available = selectedProduct.currentQuantity;
            final buyPrice = selectedProduct.purchasePrice;
            final sellPrice = selectedProduct.sellingPrice > 0 ? selectedProduct.sellingPrice : buyPrice;

            final enteredQty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
            final enteredPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            final totalAmount = enteredQty * enteredPrice;
            final costAmount = enteredQty * buyPrice;
            final profitMargin = totalAmount - costAmount;
            final isProfit = profitMargin >= 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Sell Stock / Inventory Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select an item from garage inventory to sell and generate customer bill:'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InventoryItemModel>(
                      value: selectedProduct,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Stock Item *',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      items: items.map((item) {
                        final sPrice = item.sellingPrice > 0 ? item.sellingPrice : item.purchasePrice;
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            '${item.name} (${item.currentQuantity.toStringAsFixed(1)} ${item.unit} in stock - Sell: Rs. ${sPrice.toStringAsFixed(0)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() {
                            selectedProduct = val;
                            final p = val.sellingPrice > 0 ? val.sellingPrice : val.purchasePrice;
                            priceCtrl.text = p.toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Price Comparison Info Box: Purchase Price vs Selling Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Purchase Price (Cost):', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                              Text(
                                'Rs. ${buyPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 28, color: Theme.of(ctx).dividerColor),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Preset Selling Price (Retail):', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                              Text(
                                'Rs. ${sellPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity (${selectedProduct.unit}) *',
                              helperText: 'Available: ${available.toStringAsFixed(1)}',
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Selling Unit Price (Rs.) *',
                              helperText: 'Price billed to customer (editable)',
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                      ],
                    ),

                    // Live Total Bill & Profit Margin Indicator
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Item Bill: Rs. ${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Icon(
                                isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                size: 16,
                                color: isProfit ? AppColors.success : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isProfit
                                    ? 'Profit: +Rs. ${profitMargin.toStringAsFixed(0)}'
                                    : 'Loss: -Rs. ${(-profitMargin).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isProfit ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text('Add to Bill'),
                  onPressed: () {
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    if (qty <= 0) {
                      Get.snackbar('Invalid Quantity', 'Please enter a valid quantity', backgroundColor: AppColors.error.withValues(alpha: 0.2));
                      return;
                    }
                    setState(() {
                      _items.add(InvoiceItem(
                        name: '${selectedProduct.name}${selectedProduct.brand != null && selectedProduct.brand!.isNotEmpty ? ' (${selectedProduct.brand})' : ''}',
                        type: 'product',
                        quantity: qty,
                        unitPrice: price,
                        total: qty * price,
                        inventoryItemId: selectedProduct.id,
                      ));
                      _syncPaidAmount();
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveInvoice() async {
    if (_selectedCustomer == null) {
      Get.snackbar('Required', 'Please select or add a customer for this invoice', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }
    if (_items.isEmpty) {
      Get.snackbar('Required', 'Please add at least one line item to the invoice', backgroundColor: AppColors.error.withValues(alpha: 0.2));
      return;
    }

    setState(() => _isSaving = true);
    final invoiceRepo = Get.find<InvoicePaymentRepository>();

    try {
      final invoiceItemsMaps = _items.map((i) => {
        'description': i.name,
        'quantity': i.quantity,
        'unit_price': i.unitPrice,
        'total_price': i.total,
      }).toList();

      final savedInvoiceId = await invoiceRepo.saveInvoice(
        customerId: _selectedCustomer!.id,
        vehicleId: _selectedVehicle?.id,
        jobId: widget.preselectedJob?.id,
        date: DateTime.now(),
        description: _items.map((i) => i.name).join(', '),
        items: invoiceItemsMaps,
        discount: _discount,
        notes: _notesController.text.trim(),
      );

      // 1. If advance was already paid on the job, record it as an Advance Deposit payment on the invoice
      if (_advancePaid > 0) {
        await invoiceRepo.recordPayment(
          invoiceId: savedInvoiceId,
          customerId: _selectedCustomer!.id,
          vehicleId: _selectedVehicle?.id,
          amount: _advancePaid,
          paymentDate: widget.preselectedJob?.createdAt ?? DateTime.now(),
          paymentMethod: 'Advance Deposit',
          referenceNumber: 'Job Advance (${widget.preselectedJob?.jobNumber ?? 'Deposit'})',
          notes: 'Advance deposit deducted from job order',
        );
      }

      // 2. Record immediate payment collected now at counter
      final paymentToRecord = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;

      if (paymentToRecord > 0) {
        await invoiceRepo.recordPayment(
          invoiceId: savedInvoiceId,
          customerId: _selectedCustomer!.id,
          vehicleId: _selectedVehicle?.id,
          amount: paymentToRecord,
          paymentDate: DateTime.now(),
          paymentMethod: _paymentMethod,
          referenceNumber: 'Invoice Payment (On-Spot)',
          notes: (_advancePaid + paymentToRecord) >= _grandTotal
              ? 'Full bill settled upon invoice generation'
              : 'Partial payment recorded',
        );
      }

      // Automatically deduct stock for any inventory items sold on this invoice
      final invRepo = InventoryRepository();
      for (final itm in _items) {
        if (itm.inventoryItemId != null && itm.inventoryItemId!.isNotEmpty) {
          try {
            await invRepo.adjustStock(
              itemId: itm.inventoryItemId!,
              changeAmount: -itm.quantity,
              transactionType: 'Sale',
              reasonNotes: 'Retail sale on Invoice #$savedInvoiceId',
            );
          } catch (e) {
            debugPrint('Stock deduction error: $e');
          }
        }
      }

      // Update linked job status and total settled amount if present
      if (widget.preselectedJob != null) {
        final jobRepo = Get.find<JobRepository>();
        final totalJobSettled = _advancePaid + paymentToRecord;
        await jobRepo.updateJobAdvancePayment(jobId: widget.preselectedJob!.id, paidAmount: totalJobSettled);
        if (widget.preselectedJob!.status != 'Completed') {
          await jobRepo.updateJobStatus(widget.preselectedJob!.id, 'Delivered', actualDeliveryDate: DateTime.now());
        }
      }

      // Fetch saved invoice details to build printable/shareable model
      final details = await invoiceRepo.getInvoiceDetails(savedInvoiceId);
      InvoiceModel? savedModel;
      if (details != null) {
        savedModel = InvoiceModel.fromSqlite(details, _items);
      }

      final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
      final business = AuthService.to.currentBusiness.value;

      Get.back(result: true);

      final totalPaidRecorded = _advancePaid + paymentToRecord;
      final isFull = _grandTotal > 0 && totalPaidRecorded >= _grandTotal;

      Get.snackbar(
        isFull ? 'Invoice Saved & Bill Paid' : 'Invoice Saved',
        isFull
            ? 'Bill fully settled (${Formatters.currency(totalPaidRecorded, symbol: currency)}).'
            : 'Tax Invoice saved to SQLite.',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );

      // Prompt to share bill with customer
      if (savedModel != null) {
        final currentModel = savedModel;
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Invoice Saved', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${currentModel.invoiceNumber} has been saved for ${currentModel.customerName}.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: ${Formatters.currency(_grandTotal, symbol: currency)}'
                  '${isFull ? ' (Paid & Settled)' : ''}',
                  style: const TextStyle(color: AppColors.textDarkSecondary),
                ),
                if (currentModel.customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 14, color: AppColors.textDarkSecondary),
                      const SizedBox(width: 4),
                      Text(
                        currentModel.customerPhone,
                        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Would you like to share the bill with the customer on WhatsApp?',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
              if (business != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    PdfService.printInvoice(business: business, invoice: currentModel);
                  },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Print'),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Get.back();
                  await _shareInvoicePdf(currentModel);
                },
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share WhatsApp'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate invoice: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static Future<void> _shareInvoicePdf(InvoiceModel fullInvoice) async {
    final business = AuthService.to.currentBusiness.value;
    if (business == null) return;

    try {
      final pdfBytes = await PdfService.buildInvoiceBytes(business: business, invoice: fullInvoice);

      final tempDir = await getTemporaryDirectory();
      final baseName = 'Invoice_${fullInvoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = File('${tempDir.path}/$baseName.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Only 1 item sent: the official Invoice PDF
      if (Platform.isWindows) {
        await WindowsClipboardService.copyFileToClipboard(pdfFile.path);
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$baseName.pdf');
      }

      // Try opening WhatsApp with client's phone number
      var phone = fullInvoice.customerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (phone.startsWith('03') && phone.length == 11) {
        phone = '92${phone.substring(1)}';
      }
      final whatsappUri = Uri.parse(phone.isNotEmpty ? 'whatsapp://send?phone=$phone' : 'whatsapp://send');
      final webWhatsappUri = Uri.parse(phone.isNotEmpty ? 'https://web.whatsapp.com/send?phone=$phone' : 'https://web.whatsapp.com');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri);
      }

      Get.snackbar(
        'Invoice PDF Copied!',
        'Single Tax Invoice PDF copied. Open client chat & press Ctrl + V to send!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.25),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366)),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to share invoice: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    final height = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: height * 0.9,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 620;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                (widget.isDirectSale || widget.preselectedStockItem != null)
                                    ? Icons.point_of_sale_rounded
                                    : Icons.receipt_long_rounded,
                                color: (widget.isDirectSale || widget.preselectedStockItem != null)
                                    ? AppColors.success
                                    : AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (widget.isDirectSale || widget.preselectedStockItem != null)
                                      ? 'Sell Stock / Counter Bill (Retail POS)'
                                      : 'Create Official Tax Invoice',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Customer & Vehicle Selection
                          if (isNarrow) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<CustomerModel>(
                                    value: _selectedCustomer,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Customer *', prefixIcon: Icon(Icons.person_rounded)),
                                    items: _customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.fullName} (${c.phone})', overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => _onCustomerChanged(val),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.person_add_rounded, size: 20),
                                  tooltip: 'Quick Register Customer / Walk-in',
                                  onPressed: _quickAddCustomerDialog,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<VehicleModel>(
                              value: _selectedVehicle,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Vehicle (Optional for Counter Sales)', prefixIcon: Icon(Icons.directions_car_rounded)),
                              items: _customerVehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.displayName} (${v.plateNumber})', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) => setState(() => _selectedVehicle = val),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<CustomerModel>(
                                          value: _selectedCustomer,
                                          isExpanded: true,
                                          decoration: const InputDecoration(labelText: 'Customer *', prefixIcon: Icon(Icons.person_rounded)),
                                          items: _customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.fullName} (${c.phone})', overflow: TextOverflow.ellipsis))).toList(),
                                          onChanged: (val) => _onCustomerChanged(val),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.person_add_rounded, size: 20),
                                        tooltip: 'Quick Register Customer / Walk-in',
                                        onPressed: _quickAddCustomerDialog,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<VehicleModel>(
                                    value: _selectedVehicle,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Vehicle (Optional for Counter Sales)', prefixIcon: Icon(Icons.directions_car_rounded)),
                                    items: _customerVehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.displayName} (${v.plateNumber})', overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setState(() => _selectedVehicle = val),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Line Items Table Header
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const Text(
                                'Services & Products Billed',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: _addStockItemDialog,
                                    icon: const Icon(Icons.inventory_2_rounded, size: 15),
                                    label: const Text('Sell Stock', style: TextStyle(fontSize: 12)),
                                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _addItem,
                                    icon: const Icon(Icons.add_rounded, size: 15),
                                    label: const Text('Add Custom Item', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Items List Box
                          Container(
                            constraints: BoxConstraints(maxHeight: isNarrow ? 180 : 220),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _items.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: Text('No items added. Click "Sell Stock / Inventory" or "Add Custom Item" to start.')),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _items.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
                                      final isProduct = item.inventoryItemId != null;
                                      return ListTile(
                                        leading: Icon(
                                          isProduct ? Icons.inventory_2_outlined : Icons.handyman_outlined,
                                          color: isProduct ? AppColors.success : AppColors.primary,
                                          size: 20,
                                        ),
                                        title: Row(
                                          children: [
                                            Flexible(
                                              child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                            ),
                                            if (isProduct) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Stock Product', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text('Qty: ${item.quantity.toStringAsFixed(1)} × Selling: ${Formatters.currency(item.unitPrice, symbol: currency)}', overflow: TextOverflow.ellipsis),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(Formatters.currency(item.total, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                              onPressed: () => setState(() {
                                                _items.removeAt(index);
                                                _syncPaidAmount();
                                             }),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Pricing & Payments Section
                          if (_advancePaid > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Job Advance Deducted: -${Formatters.currency(_advancePaid, symbol: currency)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Customer already paid ${Formatters.currency(_advancePaid, symbol: currency)} advance in Job Card. Net payable to collect now: ${Formatters.currency(_netPayableAfterAdvance, symbol: currency)}',
                                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (isNarrow) ...[
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _discountController,
                                        decoration: const InputDecoration(labelText: 'Discount Amount'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() => _syncPaidAmount()),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _paidAmountController,
                                        decoration: InputDecoration(
                                          labelText: _advancePaid > 0 ? 'Paid Now (Settlement)' : 'Paid Amount',
                                          suffixIcon: _isFullyPaid
                                              ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                                              : null,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: _paymentMethod,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Payment Method'),
                                  items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentMethod = val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSummaryLine('Subtotal', Formatters.currency(_subtotal, symbol: currency)),
                                  const SizedBox(height: 4),
                                  _buildSummaryLine('Discount', '-${Formatters.currency(_discount, symbol: currency)}'),
                                  const Divider(),
                                  _buildSummaryLine('Grand Total', Formatters.currency(_grandTotal, symbol: currency), isBold: true),
                                  if (_advancePaid > 0) ...[
                                    const SizedBox(height: 4),
                                    _buildSummaryLine(
                                      'Advance Paid (Job)',
                                      '-${Formatters.currency(_advancePaid, symbol: currency)}',
                                      isBold: true,
                                      color: AppColors.primaryLight,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildSummaryLine(
                                      'Net Payable',
                                      Formatters.currency(_netPayableAfterAdvance, symbol: currency),
                                      isBold: true,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  _buildSummaryLine(
                                    _advancePaid > 0 ? 'Paid Now' : 'Paid',
                                    Formatters.currency(_paid, symbol: currency),
                                    isBold: _isFullyPaid,
                                    color: _isFullyPaid ? AppColors.success : null,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildSummaryLine(
                                    'Remaining Due',
                                    Formatters.currency(_remaining, symbol: currency),
                                    isBold: true,
                                    color: _remaining > 0 ? AppColors.error : AppColors.success,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _discountController,
                                              decoration: const InputDecoration(labelText: 'Discount Amount'),
                                              keyboardType: TextInputType.number,
                                              onChanged: (_) => setState(() => _syncPaidAmount()),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _paidAmountController,
                                              decoration: InputDecoration(
                                                labelText: _advancePaid > 0 ? 'Paid Now (Settlement)' : 'Paid Amount',
                                                suffixIcon: _isFullyPaid
                                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                                                    : null,
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        value: _paymentMethod,
                                        isExpanded: true,
                                        decoration: const InputDecoration(labelText: 'Payment Method'),
                                        items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _paymentMethod = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  width: 260,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSummaryLine('Subtotal', Formatters.currency(_subtotal, symbol: currency)),
                                      const SizedBox(height: 4),
                                      _buildSummaryLine('Discount', '-${Formatters.currency(_discount, symbol: currency)}'),
                                      const Divider(),
                                      _buildSummaryLine('Grand Total', Formatters.currency(_grandTotal, symbol: currency), isBold: true),
                                      if (_advancePaid > 0) ...[
                                        const SizedBox(height: 4),
                                        _buildSummaryLine(
                                          'Advance Paid (Job)',
                                          '-${Formatters.currency(_advancePaid, symbol: currency)}',
                                          isBold: true,
                                          color: AppColors.primaryLight,
                                        ),
                                        const SizedBox(height: 4),
                                        _buildSummaryLine(
                                          'Net Payable',
                                          Formatters.currency(_netPayableAfterAdvance, symbol: currency),
                                          isBold: true,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      _buildSummaryLine(
                                        _advancePaid > 0 ? 'Paid Now' : 'Paid',
                                        Formatters.currency(_paid, symbol: currency),
                                        isBold: _isFullyPaid,
                                        color: _isFullyPaid ? AppColors.success : null,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildSummaryLine(
                                        'Remaining Due',
                                        Formatters.currency(_remaining, symbol: currency),
                                        isBold: true,
                                        color: _remaining > 0 ? AppColors.error : AppColors.success,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),

                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveInvoice,
                                icon: const Icon(Icons.check_circle_outline_rounded),
                                label: _isSaving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSummaryLine(String title, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13, color: color)),
      ],
    );
  }
}
