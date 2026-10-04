import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/models/supplier.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();

    final suppliers = led.suppliers.where((s) {
      if (q.isNotEmpty) {
        final matches = s.name.toLowerCase().contains(q) ||
            s.company.toLowerCase().contains(q) ||
            s.phone.contains(q) ||
            s.address.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Suppliers & Wholesale Accounts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Manage wholesale vendors, purchase billing, and supplier payable balances', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.domain_add_rounded, size: 16),
                  label: const Text('+ Add Supplier'),
                  onPressed: () => _showAddSupplierDialog(context, led),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by Supplier Company, Contact Person, Phone, or City...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Suppliers Table
            Expanded(
              child: Card(
                child: suppliers.isEmpty
                    ? const Center(child: Text('No suppliers found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Company / Business')),
                              DataColumn(label: Text('Contact Person')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Address / Market')),
                              DataColumn(label: Text('Total Purchases')),
                              DataColumn(label: Text('Paid Amount')),
                              DataColumn(label: Text('Payable Due')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: suppliers.map((sup) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(sup.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    onTap: () => _showSupplierLedger(context, sup, led),
                                  ),
                                  DataCell(Text(sup.name)),
                                  DataCell(Text(AppFormatters.formatPhone(sup.phone))),
                                  DataCell(Text(sup.address)),
                                  DataCell(Text(AppFormatters.currency(sup.totalPurchases), style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(AppFormatters.currency(sup.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                                  DataCell(
                                    sup.dueAmount > 0
                                        ? Text(AppFormatters.currency(sup.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))
                                        : const Text('Fully Paid', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sup.dueAmount > 0)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.warningOrange,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 11),
                                            ),
                                            onPressed: () => _showPaySupplierDialog(context, sup, led),
                                            child: const Text('Pay Due'),
                                          ),
                                        IconButton(
                                          tooltip: 'View Purchases Ledger',
                                          icon: const Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryBlue),
                                          onPressed: () => _showSupplierLedger(context, sup, led),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                          onPressed: () async {
                                            final ok = await AppDialogs.confirm(
                                              context,
                                              title: 'Delete Supplier',
                                              message: 'Delete supplier "${sup.company}"?',
                                            );
                                            if (ok) {
                                              await led.deleteSupplier(sup.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupplierLedger(BuildContext context, Supplier sup, LedgerProvider led) {
    final supPurchases = led.purchases.where((p) => p.supplierId == sup.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${sup.company} - Purchase Ledger', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Person: ${sup.name} • Phone: ${sup.phone}'),
              Text('Address: ${sup.address}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Consignments', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(AppFormatters.currency(sup.totalPurchases), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Paid to Supplier', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(AppFormatters.currency(sup.paidAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 13.5)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Payable Due Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(AppFormatters.currency(sup.dueAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 13.5)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              const Text('INVOICES FROM SUPPLIER:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              if (supPurchases.isEmpty)
                const Text('No purchase consignments on file.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ...supPurchases.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Invoice #${p.invoiceNumber} - ${AppFormatters.currency(p.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Date: ${AppFormatters.date(p.purchaseDate)} • Paid: ${AppFormatters.currency(p.paidAmount)} • Due: ${AppFormatters.currency(p.dueAmount)}'),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (sup.dueAmount > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange),
              onPressed: () {
                Navigator.pop(ctx);
                _showPaySupplierDialog(context, sup, led);
              },
              child: const Text('Pay Supplier Due'),
            ),
        ],
      ),
    );
  }

  void _showPaySupplierDialog(BuildContext context, Supplier sup, LedgerProvider led) {
    final amtCtrl = TextEditingController(text: sup.dueAmount.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String method = 'Bank Transfer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay Due to ${sup.company}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Outstanding Due: ${AppFormatters.currency(sup.dueAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
              const SizedBox(height: 12),
              TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Paying Now (Rs.) *')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                  DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                ],
                onChanged: (v) => method = v!,
              ),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Bank Reference #')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0.0;
              if (amt <= 0) return;

              await led.paySupplierDue(
                supplier: sup,
                amount: amt,
                paymentMethod: method,
                notes: notesCtrl.text.trim(),
                collectedBy: 'Muhammad Asim',
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment of ${AppFormatters.currency(amt)} to ${sup.company} recorded!')),
              );
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, LedgerProvider led) {
    final companyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Wholesale Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Business Name *')),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Person Name *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number *')),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Market / Plaza Address (e.g. Hall Road Lahore)')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Remarks')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (companyCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;

              final s = Supplier(
                id: 'SUP-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                company: companyCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );

              await led.addSupplier(s);
              Navigator.pop(ctx);
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }
}
