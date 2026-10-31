import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
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

class InvoiceCreateDialog extends StatefulWidget {
  final JobModel? preselectedJob;
  final InventoryItemModel? preselectedStockItem;
  const InvoiceCreateDialog({super.key, this.preselectedJob, this.preselectedStockItem});

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

  bool _isLoading = true;
  bool _isSaving = false;
  bool _markAsFullyPaid = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final customerRepo = Get.find<CustomerRepository>();
    final customers = await customerRepo.getCustomers();

    if (mounted) {
      setState(() {
        _customers = customers;
        _isLoading = false;
      });

      if (widget.preselectedJob != null) {
        final job = widget.preselectedJob!;
        final matchedCustomer = customers.firstWhereOrNull((c) => c.id == job.customerId);
        if (matchedCustomer != null) {
          _onCustomerChanged(matchedCustomer, preselectedVehicleId: job.vehicleId);
        }

        // Populate items from job services
        for (final s in job.services) {
          _items.add(InvoiceItem(
            name: s.serviceName,
            type: 'service',
            quantity: 1.0,
            unitPrice: s.price,
            total: s.price,
          ));
        }
        _discountController.text = job.discount.toStringAsFixed(0);
        if (job.paidAmount > 0) {
          _paidAmountController.text = job.paidAmount.toStringAsFixed(0);
          _markAsFullyPaid = job.paidAmount >= _grandTotal;
        } else {
          _syncPaidAmount();
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
  double get _paid => _markAsFullyPaid
      ? _grandTotal
      : (double.tryParse(_paidAmountController.text) ?? 0.0);
  double get _remaining => (_grandTotal - _paid).clamp(0.0, double.infinity);

  void _syncPaidAmount() {
    if (_markAsFullyPaid) {
      _paidAmountController.text = _grandTotal > 0 ? _grandTotal.toStringAsFixed(0) : '0';
    }
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
      Get.snackbar('No Stock Found', 'No inventory items registered. Please add items in the Inventory screen first.', backgroundColor: AppColors.warning.withValues(alpha: 0.2));
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
                              const Text('Purchase Price (Khareed Cost):', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
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
                              const Text('Preset Selling Price (Farokht):', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
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

  void _saveAndPrintInvoice() async {
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

      // Record immediate payment: full bill if marked fully paid or entered amount
      final enteredPaid = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
      final paymentToRecord = _markAsFullyPaid ? _grandTotal : (enteredPaid > 0 ? enteredPaid : _paid);

      if (paymentToRecord > 0) {
        await invoiceRepo.recordPayment(
          invoiceId: savedInvoiceId,
          customerId: _selectedCustomer!.id,
          vehicleId: _selectedVehicle?.id,
          amount: paymentToRecord,
          paymentDate: DateTime.now(),
          paymentMethod: _paymentMethod,
          referenceNumber: 'Invoice Payment (On-Spot)',
          notes: _markAsFullyPaid ? 'Full bill settled upon invoice generation' : '',
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

      // Update linked job status if present
      if (widget.preselectedJob != null) {
        final jobRepo = Get.find<JobRepository>();
        await jobRepo.updateJobStatus(widget.preselectedJob!.id, 'Delivered', actualDeliveryDate: DateTime.now());
      }

      // Fetch saved invoice details to build printable model
      final details = await invoiceRepo.getInvoiceDetails(savedInvoiceId);
      if (details != null) {
        final savedModel = InvoiceModel.fromSqlite(details, _items);
        final business = AuthService.to.currentBusiness.value;
        if (business != null) {
          await PdfService.printInvoice(business: business, invoice: savedModel);
        }
      }

      final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
      Get.back(result: true);
      Get.snackbar(
        _markAsFullyPaid ? 'Invoice Saved & Bill Paid' : 'Invoice Saved',
        _markAsFullyPaid
            ? 'Bill fully settled (${Formatters.currency(paymentToRecord, symbol: currency)}) and PDF sent to printer.'
            : 'Tax Invoice saved to SQLite and sent to printer.',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate invoice: $e', backgroundColor: AppColors.error.withValues(alpha: 0.2));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                              const Expanded(
                                child: Text(
                                  'Create Official Tax Invoice',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          _buildPaymentSettlementCard(context, currency),
                          const SizedBox(height: 12),

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
                                          labelText: _markAsFullyPaid ? 'Paid Amount (Full Settle)' : 'Paid Amount (Advance / Partial)',
                                          suffixIcon: _markAsFullyPaid
                                              ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                                              : null,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final entered = double.tryParse(val.trim()) ?? 0.0;
                                          setState(() {
                                            _markAsFullyPaid = (_grandTotal > 0 && entered >= _grandTotal);
                                          });
                                        },
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
                                  const SizedBox(height: 4),
                                  _buildSummaryLine(
                                    'Paid',
                                    Formatters.currency(_paid, symbol: currency),
                                    isBold: _markAsFullyPaid,
                                    color: _markAsFullyPaid ? AppColors.success : null,
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
                                                labelText: _markAsFullyPaid ? 'Paid Amount (Full Settle)' : 'Paid Amount (Advance / Partial)',
                                                suffixIcon: _markAsFullyPaid
                                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                                                    : null,
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) {
                                                final entered = double.tryParse(val.trim()) ?? 0.0;
                                                setState(() {
                                                  _markAsFullyPaid = (_grandTotal > 0 && entered >= _grandTotal);
                                                });
                                              },
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
                                      const SizedBox(height: 4),
                                      _buildSummaryLine(
                                        'Paid',
                                        Formatters.currency(_paid, symbol: currency),
                                        isBold: _markAsFullyPaid,
                                        color: _markAsFullyPaid ? AppColors.success : null,
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
                                onPressed: _isSaving ? null : _saveAndPrintInvoice,
                                icon: const Icon(Icons.print_rounded),
                                label: _isSaving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(_markAsFullyPaid ? 'Save & Print Invoice (Paid & Settled)' : 'Save & Print Invoice (PDF)'),
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

  Widget _buildPaymentSettlementCard(BuildContext context, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _markAsFullyPaid
            ? AppColors.success.withValues(alpha: 0.12)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _markAsFullyPaid
              ? AppColors.success.withValues(alpha: 0.45)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _markAsFullyPaid,
            activeColor: AppColors.success,
            onChanged: (val) {
              setState(() {
                _markAsFullyPaid = val ?? true;
                _syncPaidAmount();
              });
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bill Paid in Full (Pura Bill Ada Kar Diya)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _markAsFullyPaid ? AppColors.success : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_markAsFullyPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Auto-Settled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _markAsFullyPaid
                      ? 'Save & Print par click kartay hi bill Paid ho jayega aur print nikal aye ga (baad me Pay button nahi dabana paray ga).'
                      : 'Partial payment / Udhar bill mode active.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          if (!_markAsFullyPaid && _grandTotal > 0)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: Text('Pay Full (${Formatters.currency(_grandTotal, symbol: currency)})'),
              onPressed: () {
                setState(() {
                  _markAsFullyPaid = true;
                  _syncPaidAmount();
                });
              },
            ),
        ],
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
