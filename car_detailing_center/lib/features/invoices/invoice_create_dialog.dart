import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/job_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_payment_repository.dart';
import '../../data/repositories/job_repository.dart';

class InvoiceCreateDialog extends StatefulWidget {
  final JobModel? preselectedJob;
  const InvoiceCreateDialog({super.key, this.preselectedJob});

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
        _paidAmountController.text = job.paidAmount.toStringAsFixed(0);
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

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _grandTotal => (_subtotal - _discount).clamp(0.0, double.infinity);
  double get _paid => double.tryParse(_paidAmountController.text) ?? 0.0;
  double get _remaining => (_grandTotal - _paid).clamp(0.0, double.infinity);

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
                      child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit Price *'), keyboardType: TextInputType.number),
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

  void _saveAndPrintInvoice() async {
    if (_selectedCustomer == null) {
      Get.snackbar('Required', 'Please select a customer for this invoice', backgroundColor: AppColors.error.withValues(alpha: 0.2));
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
        vehicleId: _selectedVehicle?.id ?? '',
        jobId: widget.preselectedJob?.id,
        date: DateTime.now(),
        description: _items.map((i) => i.name).join(', '),
        items: invoiceItemsMaps,
        discount: _discount,
        notes: _notesController.text.trim(),
      );

      // Record immediate payment if entered
      if (_paid > 0) {
        await invoiceRepo.recordPayment(
          invoiceId: savedInvoiceId,
          customerId: _selectedCustomer!.id,
          vehicleId: _selectedVehicle?.id,
          amount: _paid,
          paymentDate: DateTime.now(),
          paymentMethod: _paymentMethod,
          referenceNumber: 'Invoice Payment',
        );
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

      Get.back(result: true);
      Get.snackbar(
        'Invoice Saved',
        'Tax Invoice saved to SQLite and sent to printer',
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
                            DropdownButtonFormField<CustomerModel>(
                              value: _selectedCustomer,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Customer *', prefixIcon: Icon(Icons.person_rounded)),
                              items: _customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.fullName} (${c.phone})', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) => _onCustomerChanged(val),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<VehicleModel>(
                              value: _selectedVehicle,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Vehicle', prefixIcon: Icon(Icons.directions_car_rounded)),
                              items: _customerVehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.displayName} (${v.plateNumber})', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) => setState(() => _selectedVehicle = val),
                            ),
                          ] else ...[
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<VehicleModel>(
                                    value: _selectedVehicle,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Vehicle', prefixIcon: Icon(Icons.directions_car_rounded)),
                                    items: _customerVehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.displayName} (${v.plateNumber})', overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setState(() => _selectedVehicle = val),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Line Items Table Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Services & Products Billed',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Line Item'),
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
                                    child: Center(child: Text('No items added. Click "Add Line Item" to start.')),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _items.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
                                      return ListTile(
                                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        subtitle: Text('Qty: ${item.quantity.toStringAsFixed(1)} × ${Formatters.currency(item.unitPrice, symbol: currency)}', overflow: TextOverflow.ellipsis),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(Formatters.currency(item.total, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                              onPressed: () => setState(() => _items.removeAt(index)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Pricing & Payments Section
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
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _paidAmountController,
                                        decoration: const InputDecoration(labelText: 'Paid Amount (Advance)'),
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
                                  const SizedBox(height: 4),
                                  _buildSummaryLine('Paid', Formatters.currency(_paid, symbol: currency)),
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
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _paidAmountController,
                                              decoration: const InputDecoration(labelText: 'Paid Amount (Advance)'),
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
                                      const SizedBox(height: 4),
                                      _buildSummaryLine('Paid', Formatters.currency(_paid, symbol: currency)),
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
                                    : const Text('Save & Print Invoice (PDF)'),
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
