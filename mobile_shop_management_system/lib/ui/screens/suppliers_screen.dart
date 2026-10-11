import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/app_provider.dart';
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
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LedgerProvider>().loadAll();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

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

    // Overall summary statistics across all suppliers
    double grandTotalPurchases = 0.0;
    double grandTotalPaid = 0.0;
    double grandTotalDue = 0.0;

    for (var s in led.suppliers) {
      final sPurchases = led.purchases.where((p) => p.supplierId == s.id).toList();
      final sumP = sPurchases.fold(0.0, (acc, p) => acc + p.totalAmount);
      final sumPaid = sPurchases.fold(0.0, (acc, p) => acc + p.paidAmount);
      final extraPaid = led.payments
          .where((p) => p.entityId == s.id && p.type == 'supplier_due_payment')
          .fold(0.0, (acc, p) => acc + p.amount);

      final effPurchases = sPurchases.isNotEmpty
          ? (sumP > s.totalPurchases ? sumP : s.totalPurchases)
          : s.totalPurchases;
      final effPaid = sPurchases.isNotEmpty ? (sumPaid + extraPaid) : s.paidAmount;
      final effDue = (effPurchases - effPaid).clamp(0.0, double.infinity);

      grandTotalPurchases += effPurchases;
      grandTotalPaid += effPaid;
      grandTotalDue += effDue;
    }

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

            // Top Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Vendors',
                    value: '${led.suppliers.length}',
                    icon: Icons.store_rounded,
                    color: AppTheme.primaryBlue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Purchases Bill',
                    value: AppFormatters.currency(grandTotalPurchases),
                    icon: Icons.shopping_bag_outlined,
                    color: AppTheme.primaryBlue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Paid to Vendors',
                    value: AppFormatters.currency(grandTotalPaid),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.successGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Outstanding Payable Dues',
                    value: AppFormatters.currency(grandTotalDue),
                    icon: Icons.warning_amber_rounded,
                    color: grandTotalDue > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                    isDark: isDark,
                  ),
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
                    : Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            controller: _horizontalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
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
                                  // Compute dynamic balance for this supplier
                                  final supPurchases = led.purchases.where((p) => p.supplierId == sup.id).toList();
                                  final sumPurchases = supPurchases.fold(0.0, (s, p) => s + p.totalAmount);
                                  final sumDirectPaid = supPurchases.fold(0.0, (s, p) => s + p.paidAmount);
                                  final extraPaid = led.payments
                                      .where((p) => p.entityId == sup.id && p.type == 'supplier_due_payment')
                                      .fold(0.0, (s, p) => s + p.amount);

                                  final double totalPurchases = supPurchases.isNotEmpty
                                      ? (sumPurchases > sup.totalPurchases ? sumPurchases : sup.totalPurchases)
                                      : sup.totalPurchases;
                                  final double paidAmount = supPurchases.isNotEmpty
                                      ? (sumDirectPaid + extraPaid)
                                      : sup.paidAmount;
                                  final double dueAmount = (totalPurchases - paidAmount).clamp(0.0, double.infinity);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(sup.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                                          ],
                                        ),
                                        onTap: () => _showSupplierLedger(context, sup, totalPurchases, paidAmount, dueAmount, led),
                                      ),
                                      DataCell(Text(sup.name)),
                                      DataCell(Text(AppFormatters.formatPhone(sup.phone))),
                                      DataCell(Text(sup.address.isNotEmpty ? sup.address : '-')),
                                      DataCell(Text(AppFormatters.currency(totalPurchases), style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(AppFormatters.currency(paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                                      DataCell(
                                        dueAmount > 0
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.dangerRed.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  AppFormatters.currency(dueAmount),
                                                  style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              )
                                            : (totalPurchases > 0
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.successGreen.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'Fully Cleared (Rs. 0)',
                                                      style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  )
                                                : Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF334155).withOpacity(0.3) : const Color(0xFFE2E8F0),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'No Dues (Rs. 0)',
                                                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  )),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (dueAmount > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.warningOrange,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    textStyle: const TextStyle(fontSize: 11),
                                                  ),
                                                  onPressed: () => _showPaySupplierDialog(context, sup, dueAmount, led),
                                                  child: const Text('Pay Due'),
                                                ),
                                              ),
                                            IconButton(
                                              tooltip: 'Record Purchase from ${sup.company}',
                                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18, color: AppTheme.primaryBlue),
                                              onPressed: () {
                                                context.read<AppProvider>().setNavIndex(3);
                                              },
                                            ),
                                            IconButton(
                                              tooltip: 'Edit Supplier & Balance',
                                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                                              onPressed: () => _showEditSupplierDialog(context, sup, totalPurchases, dueAmount, led),
                                            ),
                                            IconButton(
                                              tooltip: 'View Purchases Ledger',
                                              icon: const Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryBlue),
                                              onPressed: () => _showSupplierLedger(context, sup, totalPurchases, paidAmount, dueAmount, led),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplierLedger(
    BuildContext context,
    Supplier sup,
    double totalPurchases,
    double paidAmount,
    double dueAmount,
    LedgerProvider led,
  ) {
    final supPurchases = led.purchases.where((p) => p.supplierId == sup.id).toList();
    final supPayments = led.payments
        .where((p) => p.entityId == sup.id && p.type == 'supplier_due_payment')
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text('${sup.company} - Purchase Ledger', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact Person: ${sup.name} • Phone: ${sup.phone}'),
                if (sup.address.isNotEmpty) Text('Address: ${sup.address}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Consignments', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(AppFormatters.currency(totalPurchases), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Paid to Supplier', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(AppFormatters.currency(paidAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 14)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Payable Due Balance', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.currency(dueAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dueAmount > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('PURCHASE INVOICES & CONSIGNMENTS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                if (supPurchases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: cardBorder)),
                    child: const Text('No purchase consignment invoices recorded for this supplier yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                else
                  ...supPurchases.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: cardBorder)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invoice #${p.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                              Text('Date: ${AppFormatters.date(p.purchaseDate)} • Mode: ${p.paymentMethod}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppFormatters.currency(p.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                p.dueAmount > 0 ? 'Due: ${AppFormatters.currency(p.dueAmount)}' : 'Paid in Full',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.dueAmount > 0 ? AppTheme.dangerRed : AppTheme.successGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                if (supPayments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('DIRECT DUE PAYMENTS RECORDED:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  ...supPayments.map((pay) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: cardBorder)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment #${pay.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successGreen)),
                              Text('Date: ${AppFormatters.date(pay.paymentDate)} • Mode: ${pay.paymentMethod}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Text(AppFormatters.currency(pay.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (dueAmount > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange),
              onPressed: () {
                Navigator.pop(ctx);
                _showPaySupplierDialog(context, sup, dueAmount, led);
              },
              child: const Text('Pay Supplier Due'),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
            label: const Text('+ New Purchase'),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppProvider>().setNavIndex(3);
            },
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    Supplier sup,
    double currentPurchases,
    double currentDue,
    LedgerProvider led,
  ) {
    final companyCtrl = TextEditingController(text: sup.company);
    final nameCtrl = TextEditingController(text: sup.name);
    final phoneCtrl = TextEditingController(text: sup.phone);
    final addrCtrl = TextEditingController(text: sup.address);
    final emailCtrl = TextEditingController(text: sup.email);
    final purchasesCtrl = TextEditingController(text: currentPurchases.toStringAsFixed(0));
    final dueCtrl = TextEditingController(text: currentDue.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: sup.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text('Edit ${sup.company} & Balance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Business Name *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Person Name *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Market / Plaza Address')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: purchasesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Purchases Amount (Rs.)',
                          prefixText: 'Rs. ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: dueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Payable Due Balance (Rs.)',
                          prefixText: 'Rs. ',
                        ),
                      ),
                    ),
                  ],
                ),
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
              if (companyCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name and phone are required.')));
                return;
              }

              final newPurchases = double.tryParse(purchasesCtrl.text) ?? currentPurchases;
              final newDue = double.tryParse(dueCtrl.text) ?? currentDue;
              final newPaid = (newPurchases - newDue).clamp(0.0, double.infinity);

              final updated = sup.copyWith(
                name: nameCtrl.text.trim(),
                company: companyCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
                totalPurchases: newPurchases,
                dueAmount: newDue,
                paidAmount: newPaid,
              );

              await led.updateSupplier(updated);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Supplier "${updated.company}" updated successfully!')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showPaySupplierDialog(BuildContext context, Supplier sup, double dueAmount, LedgerProvider led) {
    final amtCtrl = TextEditingController(text: dueAmount.toStringAsFixed(0));
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
              Text('Outstanding Due: ${AppFormatters.currency(dueAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
              const SizedBox(height: 12),
              TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Paying Now (Rs.) *')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: method,
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

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment of ${AppFormatters.currency(amt)} to ${sup.company} recorded!')),
                );
              }
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
    final openingDueCtrl = TextEditingController(text: '0');
    final prevPurchasesCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.domain_add_rounded, color: AppTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Text('Add Wholesale Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Business Name *', hintText: 'e.g. Infinix Official, Vivo Wholesale')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Person Name *'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Market / Plaza Address (e.g. Hall Road Lahore, Vehari)')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: openingDueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Opening Payable Due (Rs.)',
                          hintText: '0',
                          prefixText: 'Rs. ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: prevPurchasesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Past Purchases (Rs.)',
                          hintText: '0',
                          prefixText: 'Rs. ',
                        ),
                      ),
                    ),
                  ],
                ),
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
              if (companyCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name and phone number are required.')));
                return;
              }

              final openingDue = double.tryParse(openingDueCtrl.text) ?? 0.0;
              final pastPurchases = double.tryParse(prevPurchasesCtrl.text) ?? 0.0;
              final totalPurchases = pastPurchases > 0 ? pastPurchases : openingDue;

              final s = Supplier(
                id: 'SUP-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : companyCtrl.text.trim(),
                company: companyCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
                totalPurchases: totalPurchases,
                paidAmount: 0.0,
                dueAmount: openingDue,
              );

              await led.addSupplier(s);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Supplier "${s.company}" added successfully!')),
                );
              }
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }
}
