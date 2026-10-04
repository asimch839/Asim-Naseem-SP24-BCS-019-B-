import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/customer.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _onlyWithDues = false;

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();

    final customers = led.customers.where((c) {
      if (_onlyWithDues && c.totalDue <= 0) return false;
      if (q.isNotEmpty) {
        final matches = c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.alternatePhone.contains(q) ||
            c.address.toLowerCase().contains(q);
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
                    const Text('Customer Ledger & Accounts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Manage customer records, purchase & repair histories, and outstanding dues', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('+ Add New Customer (F3)'),
                  onPressed: () => AppDialogs.showNewCustomerDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search & Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by Customer Name, Mobile Number, or Address...',
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
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Only Outstanding Dues'),
                  selected: _onlyWithDues,
                  onSelected: (v) => setState(() => _onlyWithDues = v),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Table
            Expanded(
              child: Card(
                child: customers.isEmpty
                    ? const Center(child: Text('No customers found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Customer Name')),
                              DataColumn(label: Text('Phone Number')),
                              DataColumn(label: Text('Alternate / WhatsApp')),
                              DataColumn(label: Text('Total Purchases')),
                              DataColumn(label: Text('Repairs Submitted')),
                              DataColumn(label: Text('Total Paid')),
                              DataColumn(label: Text('Customer Due')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: customers.map((c) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        if (c.address.isNotEmpty)
                                          Text(c.address, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ],
                                    ),
                                    onTap: () => _showCustomerDetails(context, c, led),
                                  ),
                                  DataCell(Text(AppFormatters.formatPhone(c.phone))),
                                  DataCell(Text(c.alternatePhone.isNotEmpty ? AppFormatters.formatPhone(c.alternatePhone) : '-')),
                                  DataCell(Text(AppFormatters.currency(c.totalPurchases), style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text('${c.totalRepairs} devices')),
                                  DataCell(Text(AppFormatters.currency(c.totalPaid), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                                  DataCell(
                                    c.totalDue > 0
                                        ? Text(AppFormatters.currency(c.totalDue), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))
                                        : const Text('No Due', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (c.totalDue > 0)
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.payments_rounded, size: 14),
                                            label: const Text('Receive Due'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.successGreen,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 11),
                                            ),
                                            onPressed: () => AppDialogs.showReceivePaymentDialog(context, preselectedCustomer: c),
                                          ),
                                        IconButton(
                                          tooltip: 'View Profile & Ledger History',
                                          icon: const Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryBlue),
                                          onPressed: () => _showCustomerDetails(context, c, led),
                                        ),
                                        IconButton(
                                          tooltip: 'Edit Customer',
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          onPressed: () => _showEditCustomerDialog(context, c, led),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                          onPressed: () async {
                                            final ok = await AppDialogs.confirm(
                                              context,
                                              title: 'Delete Customer',
                                              message: 'Delete customer "${c.name}"?',
                                            );
                                            if (ok) {
                                              await led.deleteCustomer(c.id);
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

  void _showCustomerDetails(BuildContext context, Customer c, LedgerProvider led) {
    final customerSales = led.sales.where((s) => s.customerId == c.id || s.customerPhone == c.phone).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('${c.name} - Ledger Profile', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Contact: ${c.phone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (c.alternatePhone.isNotEmpty) Text('Alt: ${c.alternatePhone}'),
                  ],
                ),
                if (c.address.isNotEmpty) Text('Address: ${c.address}'),
                if (c.notes.isNotEmpty) Text('Notes: ${c.notes}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Purchases', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(AppFormatters.currency(c.totalPurchases), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Total Paid', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(AppFormatters.currency(c.totalPaid), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 13.5)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Current Due', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(AppFormatters.currency(c.totalDue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 13.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                const Text('RECENT PURCHASES / INVOICES:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryBlue)),
                const SizedBox(height: 6),
                if (customerSales.isEmpty)
                  const Text('No sales records linked yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...customerSales.map((s) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Invoice #${s.invoiceNumber} - ${AppFormatters.currency(s.grandTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${AppFormatters.date(s.saleDate)} • Paid: ${AppFormatters.currency(s.paidAmount)} • Due: ${AppFormatters.currency(s.dueAmount)}'),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (c.totalDue > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
              onPressed: () {
                Navigator.pop(ctx);
                AppDialogs.showReceivePaymentDialog(context, preselectedCustomer: c);
              },
              child: const Text('Receive Due Payment'),
            ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer c, LedgerProvider led) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    final altCtrl = TextEditingController(text: c.alternatePhone);
    final addrCtrl = TextEditingController(text: c.address);
    final notesCtrl = TextEditingController(text: c.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Customer "${c.name}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Primary Phone Number')),
              const SizedBox(height: 10),
              TextField(controller: altCtrl, decoration: const InputDecoration(labelText: 'Alternate Phone / WhatsApp')),
              const SizedBox(height: 10),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Remarks')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = c.copyWith(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                alternatePhone: altCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              await led.updateCustomer(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
