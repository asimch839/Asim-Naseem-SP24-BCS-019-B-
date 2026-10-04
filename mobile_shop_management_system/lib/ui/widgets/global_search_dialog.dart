import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/models/product.dart';
import '../../core/providers/repair_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final rep = context.watch<RepairProvider>();
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _query.trim().toLowerCase();

    // Results
    final matchedPhones = q.isEmpty
        ? []
        : inv.phones.where((ph) =>
            ph.imei1.contains(q) ||
            ph.imei2.contains(q) ||
            ph.brand.toLowerCase().contains(q) ||
            ph.model.toLowerCase().contains(q) ||
            ph.serialNumber.toLowerCase().contains(q)).toList();

    final matchedProducts = q.isEmpty
        ? []
        : inv.products.where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q)).toList();

    final matchedRepairs = q.isEmpty
        ? []
        : rep.repairs.where((r) =>
            r.jobId.toLowerCase().contains(q) ||
            r.customerName.toLowerCase().contains(q) ||
            r.customerPhone.contains(q) ||
            r.imei.contains(q) ||
            r.deviceModel.toLowerCase().contains(q)).toList();

    final matchedCustomers = q.isEmpty
        ? []
        : led.customers.where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.alternatePhone.contains(q)).toList();

    final totalResults = matchedPhones.length + matchedProducts.length + matchedRepairs.length + matchedCustomers.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 24, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Type IMEI, Phone Model, Customer Name, or Repair ID...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      onChanged: (val) => setState(() => _query = val),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Results List
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.manage_search_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                          const SizedBox(height: 12),
                          Text(
                            'Quick Finder for IMEI, Handsets, Repairs & Customers',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try entering "3589...", "iPhone", "Samsung", or "0300..."',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : totalResults == 0
                      ? Center(
                          child: Text(
                            'No matching records found for "$_query"',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: [
                            // Phones by IMEI
                            if (matchedPhones.isNotEmpty) ...[
                              _sectionHeader('MOBILE PHONES & IMEI RECORDS (${matchedPhones.length})', isDark),
                              ...matchedPhones.map((ph) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFE0F2FE),
                                      child: Icon(Icons.phone_android_rounded, color: AppTheme.primaryBlue, size: 20),
                                    ),
                                    title: Text('${ph.brand} ${ph.model} (${ph.color})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    subtitle: Text('IMEI: ${ph.imei1} | Status: ${ph.status} | PTA: ${ph.ptaStatus}\n${ph.status == "Sold" ? "Sold to: ${ph.customerName ?? 'Customer'} on Inv #${ph.saleInvoiceNumber ?? '-'}" : "In Shop Stock"}', style: const TextStyle(fontSize: 11.5)),
                                    trailing: Text(AppFormatters.currency(ph.salePrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.pop(context);
                                      app.setNavIndex(5); // Go to Mobile Phones Screen
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],

                            // Repair Jobs
                            if (matchedRepairs.isNotEmpty) ...[
                              _sectionHeader('REPAIR LAB JOBS (${matchedRepairs.length})', isDark),
                              ...matchedRepairs.map((r) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFFEE2E2),
                                      child: Icon(Icons.build_rounded, color: AppTheme.dangerRed, size: 18),
                                    ),
                                    title: Text('Job #${r.jobId} - ${r.deviceBrand} ${r.deviceModel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    subtitle: Text('Customer: ${r.customerName} (${r.customerPhone}) | Status: ${r.status.displayName}\nProblem: ${r.reportedProblem}', style: const TextStyle(fontSize: 11.5)),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(AppFormatters.currency(r.finalTotal > 0 ? r.finalTotal : r.estimatedCost), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (r.remainingDue > 0)
                                          Text('Due: ${AppFormatters.currency(r.remainingDue)}', style: const TextStyle(fontSize: 11, color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.pop(context);
                                      app.setNavIndex(7); // Go to Repair Lab
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],

                            // Products
                            if (matchedProducts.isNotEmpty) ...[
                              _sectionHeader('PRODUCTS & ACCESSORIES (${matchedProducts.length})', isDark),
                              ...matchedProducts.map((p) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFECFDF5),
                                      child: Icon(p.type == ProductType.phone ? Icons.smartphone_rounded : (p.type == ProductType.part ? Icons.memory_rounded : Icons.cable_rounded), color: AppTheme.successGreen, size: 20),
                                    ),
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    subtitle: Text('SKU: ${p.sku} | Barcode: ${p.barcode.isNotEmpty ? p.barcode : "-"} | Stock: ${p.stockQuantity} pcs', style: const TextStyle(fontSize: 11.5)),
                                    trailing: Text(AppFormatters.currency(p.salePrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      app.setNavIndex(4); // Inventory
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],

                            // Customers
                            if (matchedCustomers.isNotEmpty) ...[
                              _sectionHeader('CUSTOMERS (${matchedCustomers.length})', isDark),
                              ...matchedCustomers.map((c) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFEDE9FE),
                                      child: Icon(Icons.person_rounded, color: AppTheme.purpleRepair, size: 20),
                                    ),
                                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    subtitle: Text('Phone: ${c.phone} | Purchases: ${AppFormatters.currency(c.totalPurchases)} | Repairs: ${c.totalRepairs}', style: const TextStyle(fontSize: 11.5)),
                                    trailing: c.totalDue > 0
                                        ? Text('Due: ${AppFormatters.currency(c.totalDue)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed))
                                        : const Text('No Due', style: TextStyle(color: AppTheme.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      app.setNavIndex(8); // Customers
                                    },
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
