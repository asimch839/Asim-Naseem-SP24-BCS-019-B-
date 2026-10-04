import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/models/customer.dart';
import '../../core/models/repair_job.dart';
import '../../core/services/print_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class AppDialogs {
  // Confirmation Dialog
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    Color confirmColor = AppTheme.dangerRed,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // New Customer Dialog
  static Future<Customer?> showNewCustomerDialog(BuildContext context, {String? initialPhone}) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: initialPhone ?? '');
    final altPhoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    return await showDialog<Customer>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Add New Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Customer Full Name *', prefixIcon: Icon(Icons.person_outline, size: 18)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Customer name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Mobile Number (e.g. 0300-1234567) *', prefixIcon: Icon(Icons.phone_outlined, size: 18)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: altPhoneCtrl,
                          decoration: const InputDecoration(labelText: 'Alternate Phone / WhatsApp', prefixIcon: Icon(Icons.phone_iphone_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(labelText: 'Shop / Residence Address', prefixIcon: Icon(Icons.location_on_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'Customer Notes / Remarks', prefixIcon: Icon(Icons.note_alt_outlined, size: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final led = ctx.read<LedgerProvider>();
                      final existing = await led.findCustomerByPhone(phoneCtrl.text.trim());
                      if (existing != null) {
                        final useExisting = await showDialog<bool>(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            title: const Text('Customer Already Exists'),
                            content: Text('A customer with number "${phoneCtrl.text.trim()}" already exists as "${existing.name}". Would you like to use this existing customer record?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Use Existing')),
                            ],
                          ),
                        );
                        if (useExisting == true) {
                          Navigator.pop(ctx, existing);
                          return;
                        }
                      }

                      final newCust = Customer(
                        id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        alternatePhone: altPhoneCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                      await led.addCustomer(newCust);
                      Navigator.pop(ctx, newCust);
                    }
                  },
                  child: const Text('Save Customer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // New Repair Job Dialog
  static Future<void> showNewRepairDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final imeiCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final conditionCtrl = TextEditingController(text: 'Good / Minor Scratches');
    final problemCtrl = TextEditingController();
    final accessoriesCtrl = TextEditingController(text: 'Device Only');
    final pinCtrl = TextEditingController();
    final estCostCtrl = TextEditingController(text: '0');
    final advanceCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    bool obscurePin = true;
    String paymentMethod = 'Cash';
    String assignedTech = 'Tariq Mehmood';
    DateTime expectedDelivery = DateTime.now().add(const Duration(days: 1));

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final app = ctx.read<AppProvider>();
            final rep = ctx.read<RepairProvider>();
            final led = ctx.read<LedgerProvider>();

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.build_circle_rounded, color: AppTheme.purpleRepair),
                  SizedBox(width: 8),
                  Text('New Mobile Repair Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 650,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Section
                        const Text('CUSTOMER INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: phoneCtrl,
                                decoration: const InputDecoration(labelText: 'Customer Phone *'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                                onChanged: (phone) async {
                                  if (phone.length >= 7) {
                                    final found = await led.findCustomerByPhone(phone);
                                    if (found != null && nameCtrl.text.isEmpty) {
                                      setState(() {
                                        nameCtrl.text = found.name;
                                      });
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Customer Name *'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Device Section
                        const Text('DEVICE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: brandCtrl,
                                decoration: const InputDecoration(labelText: 'Brand (e.g. Samsung, Apple) *'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Brand is required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: modelCtrl,
                                decoration: const InputDecoration(labelText: 'Model (e.g. Galaxy A54, iPhone 11) *'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Model is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: imeiCtrl,
                                decoration: const InputDecoration(labelText: 'IMEI / Serial Number (Optional)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: colorCtrl,
                                decoration: const InputDecoration(labelText: 'Device Color'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: conditionCtrl,
                                decoration: const InputDecoration(labelText: 'Physical Condition'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: accessoriesCtrl,
                                decoration: const InputDecoration(labelText: 'Accessories Received'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Problem & Security
                        const Text('PROBLEM REPORTED & SECURITY PIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: problemCtrl,
                          decoration: const InputDecoration(labelText: 'Reported Problem / Customer Complaint *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Problem is required' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: pinCtrl,
                                obscureText: obscurePin,
                                decoration: InputDecoration(
                                  labelText: 'Device Lock PIN / Password',
                                  helperText: 'Confidential: Hidden by default for customer privacy',
                                  suffixIcon: IconButton(
                                    icon: Icon(obscurePin ? Icons.visibility_off : Icons.visibility, size: 18),
                                    onPressed: () => setState(() => obscurePin = !obscurePin),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: assignedTech,
                                decoration: const InputDecoration(labelText: 'Assign Technician'),
                                items: const [
                                  DropdownMenuItem(value: 'Tariq Mehmood', child: Text('Tariq Mehmood (Senior Tech)')),
                                  DropdownMenuItem(value: 'Hamza Ali', child: Text('Hamza Ali (Junior Tech)')),
                                  DropdownMenuItem(value: 'Muhammad Asim', child: Text('Muhammad Asim (Owner)')),
                                ],
                                onChanged: (v) => setState(() => assignedTech = v!),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Cost & Advance
                        const Text('COST ESTIMATE & ADVANCE DEPOSIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: estCostCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Estimated Cost (Rs.)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: advanceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Advance Received (Rs.)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: paymentMethod,
                                decoration: const InputDecoration(labelText: 'Advance Payment Mode'),
                                items: const [
                                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                  DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                                  DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                                ],
                                onChanged: (v) => setState(() => paymentMethod = v!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Save & Print Job Card'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final now = DateTime.now();
                      final jobId = '${app.settings.repairPrefix}${now.millisecondsSinceEpoch.toString().substring(7)}';

                      // Find or create customer
                      var cust = await led.findCustomerByPhone(phoneCtrl.text.trim());
                      if (cust == null) {
                        cust = Customer(
                          id: 'CUST-${now.millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                        await led.addCustomer(cust);
                      }

                      final est = double.tryParse(estCostCtrl.text) ?? 0.0;
                      final adv = double.tryParse(advanceCtrl.text) ?? 0.0;

                      final job = RepairJob(
                        id: 'REP-${now.millisecondsSinceEpoch}',
                        jobId: jobId,
                        customerId: cust.id,
                        customerName: cust.name,
                        customerPhone: cust.phone,
                        deviceBrand: brandCtrl.text.trim(),
                        deviceModel: modelCtrl.text.trim(),
                        imei: imeiCtrl.text.trim(),
                        color: colorCtrl.text.trim(),
                        deviceCondition: conditionCtrl.text.trim(),
                        reportedProblem: problemCtrl.text.trim(),
                        accessoriesReceived: accessoriesCtrl.text.trim(),
                        lockPinOrPassword: pinCtrl.text.trim(),
                        technicianNotes: notesCtrl.text.trim(),
                        estimatedCost: est,
                        advancePaid: adv,
                        finalTotal: est,
                        remainingDue: (est - adv).clamp(0.0, double.infinity),
                        paymentMethod: paymentMethod,
                        status: RepairStatus.received,
                        technicianName: assignedTech,
                        expectedDeliveryDate: expectedDelivery,
                        history: [
                          RepairStatusHistory(
                            id: 'RSH-${now.millisecondsSinceEpoch}',
                            repairId: 'REP-${now.millisecondsSinceEpoch}',
                            status: RepairStatus.received,
                            changedBy: app.currentUser.name,
                            notes: 'Device received at counter. Advance Rs. ${AppFormatters.currency(adv)} ($paymentMethod)',
                          ),
                        ],
                      );

                      await rep.createRepairJob(job);
                      Navigator.pop(ctx);

                      // Print Job Card directly!
                      await PrintService.printRepairJobCard(job: job, settings: app.settings);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Receive Payment Modal
  static Future<void> showReceivePaymentDialog(BuildContext context, {Customer? preselectedCustomer}) async {
    Customer? selectedCust = preselectedCustomer;
    final amountCtrl = TextEditingController(
      text: preselectedCustomer != null && preselectedCustomer.totalDue > 0
          ? preselectedCustomer.totalDue.toStringAsFixed(0)
          : '',
    );
    final notesCtrl = TextEditingController();
    String paymentMethod = 'Cash';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final led = ctx.watch<LedgerProvider>();
            final app = ctx.watch<AppProvider>();

            final customersWithDues = led.customers.where((c) => c.totalDue > 0).toList();
            if (selectedCust == null && customersWithDues.isNotEmpty) {
              selectedCust = customersWithDues.first;
              amountCtrl.text = selectedCust!.totalDue.toStringAsFixed(0);
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.payments_rounded, color: AppTheme.successGreen),
                  SizedBox(width: 8),
                  Text('Receive Customer Due Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCust?.id,
                      decoration: const InputDecoration(labelText: 'Select Customer With Due'),
                      items: customersWithDues.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.phone}) - Due: ${AppFormatters.currency(c.totalDue)}'),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() {
                            selectedCust = customersWithDues.firstWhere((c) => c.id == id);
                            amountCtrl.text = selectedCust!.totalDue.toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedCust != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Total Due Balance:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                            Text(AppFormatters.currency(selectedCust!.totalDue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 14)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount Paying Now (Rs.) *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                        DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                      ],
                      onChanged: (v) => setState(() => paymentMethod = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes / Reference / Bank Ref'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Record & Print Receipt'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                  onPressed: () async {
                    if (selectedCust == null) return;
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amt <= 0) return;

                    final payment = await led.receiveCustomerDue(
                      customer: selectedCust!,
                      amount: amt,
                      paymentMethod: paymentMethod,
                      notes: notesCtrl.text.trim(),
                      collectedBy: app.currentUser.name,
                    );

                    Navigator.pop(ctx);
                    await PrintService.printPaymentReceipt(payment: payment, settings: app.settings);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
