import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/sale.dart';
import '../../core/services/print_service.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedMethod = 'All';

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();
    final sales = led.sales.where((s) {
      if (_selectedMethod != 'All' && s.paymentMethod != _selectedMethod) return false;
      if (q.isNotEmpty) {
        final matches = s.invoiceNumber.toLowerCase().contains(q) ||
            s.customerName.toLowerCase().contains(q) ||
            s.customerPhone.contains(q);
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
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sales History & Invoices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Manage all commercial sales, customer invoices, and thermal receipts', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export to CSV'),
                      onPressed: () async {
                        final path = await ExportService.exportSalesToCsv(sales);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sales exported successfully to: $path')),
                          );
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                      label: const Text('New Sale (F1)'),
                      onPressed: () => app.setNavIndex(1),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by Invoice #, Customer Name, or Phone...',
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
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(labelText: 'Payment Mode'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Payment Modes')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                      DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'Split', child: Text('Split Payment')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMethod = val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sales Table
            Expanded(
              child: Card(
                child: sales.isEmpty
                    ? const Center(child: Text('No sales match the search filter.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Invoice #')),
                              DataColumn(label: Text('Customer')),
                              DataColumn(label: Text('Date & Time')),
                              DataColumn(label: Text('Items')),
                              DataColumn(label: Text('Grand Total')),
                              DataColumn(label: Text('Paid Amount')),
                              DataColumn(label: Text('Due Balance')),
                              DataColumn(label: Text('Payment Mode')),
                              DataColumn(label: Text('Cashier')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: sales.map((sale) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      sale.invoiceNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                    ),
                                    onTap: () => _showSaleDetails(context, sale, app),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(sale.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (sale.customerPhone.isNotEmpty)
                                          Text(sale.customerPhone, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(AppFormatters.dateTime(sale.saleDate), style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('${sale.items.length} items')),
                                  DataCell(Text(AppFormatters.currency(sale.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(AppFormatters.currency(sale.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                                  DataCell(
                                    sale.dueAmount > 0
                                        ? Text(AppFormatters.currency(sale.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))
                                        : const Text('Paid in Full', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                      child: Text(sale.paymentMethod, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                    ),
                                  ),
                                  DataCell(Text(sale.cashierName.isNotEmpty ? sale.cashierName : 'Admin')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'View Details',
                                          icon: const Icon(Icons.visibility_outlined, size: 18),
                                          onPressed: () => _showSaleDetails(context, sale, app),
                                        ),
                                        IconButton(
                                          tooltip: 'Print A4 Invoice',
                                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppTheme.primaryBlue),
                                          onPressed: () => PrintService.printSaleInvoice(sale: sale, settings: app.settings),
                                        ),
                                        IconButton(
                                          tooltip: 'Print Thermal Receipt (80mm)',
                                          icon: const Icon(Icons.receipt_long_outlined, size: 18, color: AppTheme.successGreen),
                                          onPressed: () => PrintService.printThermalReceipt(sale: sale, settings: app.settings),
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

  void _showSaleDetails(BuildContext context, Sale sale, AppProvider app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice #${sale.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(AppFormatters.dateTime(sale.saleDate), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${sale.customerName} (${sale.customerPhone})', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Payment Method: ${sale.paymentMethod} • Cashier: ${sale.cashierName}'),
              if (sale.notes.isNotEmpty) Text('Notes: ${sale.notes}', style: const TextStyle(color: Colors.grey)),
              const Divider(height: 20),
              const Text('ITEMS SOLD:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          if (item.imei.isNotEmpty)
                            Text('IMEI: ${item.imei}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                        ],
                      ),
                      Text(
                        '${item.quantity} x ${AppFormatters.currency(item.unitPrice)} = ${AppFormatters.currency(item.total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(AppFormatters.currency(sale.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Paid Amount:'),
                  Text(AppFormatters.currency(sale.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ],
              ),
              if (sale.dueAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Balance:', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                    Text(AppFormatters.currency(sale.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Print Invoice'),
            onPressed: () {
              Navigator.pop(ctx);
              PrintService.printSaleInvoice(sale: sale, settings: app.settings);
            },
          ),
        ],
      ),
    );
  }
}
