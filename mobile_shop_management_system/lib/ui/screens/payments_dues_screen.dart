import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/payment_record.dart';
import '../../core/services/print_service.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class PaymentsDuesScreen extends StatefulWidget {
  const PaymentsDuesScreen({super.key});

  @override
  State<PaymentsDuesScreen> createState() => _PaymentsDuesScreenState();
}

class _PaymentsDuesScreenState extends State<PaymentsDuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customerDues = led.customers.where((c) => c.totalDue > 0).toList();
    final supplierDues = led.suppliers.where((s) => s.dueAmount > 0).toList();

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
                    const Text('Dues Ledgers & Payment Settlements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Track outstanding customer credits, supplier payables, and print payment vouchers', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export Dues CSV'),
                      onPressed: () async {
                        final path = await ExportService.exportCustomerDuesToCsv(led.customers);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Customer dues exported to: $path')),
                          );
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                      label: const Text('Receive Payment (F6)'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                      onPressed: () => AppDialogs.showReceivePaymentDialog(context),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary Totals Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL CUSTOMER DUES (RECEIVABLE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                            SizedBox(height: 2),
                            Text('Credit given to customers', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                          ],
                        ),
                        Text(AppFormatters.currency(led.totalCustomerDues), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF991B1B))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL SUPPLIER DUES (PAYABLE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                            SizedBox(height: 2),
                            Text('Pending wholesale consignments', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                          ],
                        ),
                        Text(AppFormatters.currency(led.totalSupplierDues), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tabs Header
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: AppTheme.primaryBlue,
              tabs: [
                Tab(text: 'Customer Dues Ledger (${customerDues.length})'),
                Tab(text: 'Supplier Dues Ledger (${supplierDues.length})'),
                Tab(text: 'Payment Receipts History (${led.payments.length})'),
              ],
            ),

            const SizedBox(height: 12),

            // Tabs Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Customer Dues
                  _buildCustomerDuesTable(context, customerDues, led, isDark),

                  // Tab 2: Supplier Dues
                  _buildSupplierDuesTable(context, supplierDues, led, isDark),

                  // Tab 3: Receipts
                  _buildReceiptsHistory(context, led.payments, app, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDuesTable(BuildContext context, List<dynamic> customers, LedgerProvider led, bool isDark) {
    return Card(
      child: customers.isEmpty
          ? const Center(child: Text('All clear! No customers currently have outstanding dues.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Customer Name')),
                    DataColumn(label: Text('Phone Number')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('Total Purchases')),
                    DataColumn(label: Text('Total Paid')),
                    DataColumn(label: Text('Outstanding Due')),
                    DataColumn(label: Text('Quick Settle')),
                  ],
                  rows: customers.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(AppFormatters.formatPhone(c.phone))),
                        DataCell(Text(c.address.isNotEmpty ? c.address : '-')),
                        DataCell(Text(AppFormatters.currency(c.totalPurchases))),
                        DataCell(Text(AppFormatters.currency(c.totalPaid), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                        DataCell(Text(AppFormatters.currency(c.totalDue), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 13.5))),
                        DataCell(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.payments_rounded, size: 14),
                            label: const Text('Receive Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => AppDialogs.showReceivePaymentDialog(context, preselectedCustomer: c),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildSupplierDuesTable(BuildContext context, List<dynamic> suppliers, LedgerProvider led, bool isDark) {
    return Card(
      child: suppliers.isEmpty
          ? const Center(child: Text('All supplier bills are cleared in full.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Supplier Company')),
                    DataColumn(label: Text('Contact Person')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Total Consignments')),
                    DataColumn(label: Text('Paid Amount')),
                    DataColumn(label: Text('Payable Due')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: suppliers.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s.company, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.name)),
                        DataCell(Text(AppFormatters.formatPhone(s.phone))),
                        DataCell(Text(AppFormatters.currency(s.totalPurchases))),
                        DataCell(Text(AppFormatters.currency(s.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                        DataCell(Text(AppFormatters.currency(s.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 13.5))),
                        DataCell(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 14),
                            label: const Text('Pay Supplier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _showPaySupplierDialog(context, s, led),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildReceiptsHistory(BuildContext context, List<PaymentRecord> payments, AppProvider app, bool isDark) {
    return Card(
      child: payments.isEmpty
          ? const Center(child: Text('No payment vouchers recorded yet.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Receipt #')),
                    DataColumn(label: Text('Date & Time')),
                    DataColumn(label: Text('Entity / Name')),
                    DataColumn(label: Text('Type of Payment')),
                    DataColumn(label: Text('Payment Method')),
                    DataColumn(label: Text('Amount Settled')),
                    DataColumn(label: Text('Collected / Handled By')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: payments.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                        DataCell(Text(AppFormatters.dateTime(p.paymentDate))),
                        DataCell(Text(p.entityName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(p.typeDisplayName)),
                        DataCell(Text(p.paymentMethod)),
                        DataCell(Text(AppFormatters.currency(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen))),
                        DataCell(Text(p.collectedBy.isNotEmpty ? p.collectedBy : 'Admin')),
                        DataCell(
                          IconButton(
                            tooltip: 'Print Payment Receipt',
                            icon: const Icon(Icons.print_rounded, size: 18, color: AppTheme.primaryBlue),
                            onPressed: () => PrintService.printPaymentReceipt(payment: p, settings: app.settings),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  void _showPaySupplierDialog(BuildContext context, dynamic sup, LedgerProvider led) {
    final amtCtrl = TextEditingController(text: sup.dueAmount.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String method = 'Bank Transfer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay Wholesale Supplier (${sup.company})'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Outstanding Payable: ${AppFormatters.currency(sup.dueAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
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
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Bank Ref # / Notes')),
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
}
