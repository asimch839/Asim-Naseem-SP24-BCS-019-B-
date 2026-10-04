import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/purchase.dart';
import '../../core/models/product.dart';
import '../../core/models/supplier.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();
    final purchases = led.purchases.where((p) {
      if (q.isNotEmpty) {
        final matches = p.invoiceNumber.toLowerCase().contains(q) ||
            p.supplierName.toLowerCase().contains(q);
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Supplier Purchases & Consignments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Record supplier invoices, restock items, and enter new phone IMEIs', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text('+ New Purchase Invoice'),
                  onPressed: () => _showNewPurchaseDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by Supplier Invoice # or Supplier Name...',
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

            // Purchases Table
            Expanded(
              child: Card(
                child: purchases.isEmpty
                    ? const Center(child: Text('No purchase records found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Invoice #')),
                              DataColumn(label: Text('Supplier')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Items Received')),
                              DataColumn(label: Text('Total Bill')),
                              DataColumn(label: Text('Paid Amount')),
                              DataColumn(label: Text('Supplier Due')),
                              DataColumn(label: Text('Payment Method')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: purchases.map((pur) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(pur.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                                  DataCell(Text(pur.supplierName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(AppFormatters.date(pur.purchaseDate))),
                                  DataCell(Text('${pur.items.length} items (${pur.items.fold(0, (s, i) => s + i.quantity)} pcs)')),
                                  DataCell(Text(AppFormatters.currency(pur.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(AppFormatters.currency(pur.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                                  DataCell(
                                    pur.dueAmount > 0
                                        ? Text(AppFormatters.currency(pur.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))
                                        : const Text('Fully Cleared', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  DataCell(Text(pur.paymentMethod)),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'View Purchase Details',
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      onPressed: () => _showPurchaseDetails(context, pur),
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

  void _showNewPurchaseDialog(BuildContext context) {
    final led = context.read<LedgerProvider>();
    final inv = context.read<InventoryProvider>();
    final app = context.read<AppProvider>();

    Supplier? selectedSupplier = led.suppliers.isNotEmpty ? led.suppliers.first : null;
    Product? selectedProduct = inv.products.isNotEmpty ? inv.products.first : null;

    final invoiceNumCtrl = TextEditingController(text: 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(text: selectedProduct?.purchasePrice.toStringAsFixed(0) ?? '0');
    final paidCtrl = TextEditingController(text: '0');
    final imeiListCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String paymentMethod = 'Bank Transfer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final qty = int.tryParse(qtyCtrl.text) ?? 1;
          final unitCost = double.tryParse(costCtrl.text) ?? 0.0;
          final totalBill = qty * unitCost;
          final paid = double.tryParse(paidCtrl.text) ?? 0.0;
          final due = (totalBill - paid).clamp(0.0, double.infinity);

          final isPhone = selectedProduct?.type == ProductType.phone;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.shopping_bag_rounded, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Record Supplier Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier Select
                    DropdownButtonFormField<String>(
                      value: selectedSupplier?.id,
                      decoration: const InputDecoration(labelText: 'Supplier *'),
                      items: led.suppliers.map((s) {
                        return DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.company})'));
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() => selectedSupplier = led.suppliers.firstWhere((s) => s.id == id));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: invoiceNumCtrl,
                            decoration: const InputDecoration(labelText: 'Supplier Invoice # *'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: const InputDecoration(labelText: 'Payment Method'),
                            items: const [
                              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                              DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                              DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                            ],
                            onChanged: (v) => setState(() => paymentMethod = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Product Select
                    DropdownButtonFormField<String>(
                      value: selectedProduct?.id,
                      decoration: const InputDecoration(labelText: 'Select Product to Restock *'),
                      items: inv.products.map((p) {
                        return DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.category}) - Cur Stock: ${p.stockQuantity}'));
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() {
                            selectedProduct = inv.products.firstWhere((p) => p.id == id);
                            costCtrl.text = selectedProduct!.purchasePrice.toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Quantity *'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Purchase Unit Price (Rs.) *'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),

                    if (isPhone) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: imeiListCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Enter Phone IMEIs ($qty needed, one per line or comma-separated)',
                          hintText: '358941092837461\n358941092837462',
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Calculated Total Bill:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(AppFormatters.currency(totalBill), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: paidCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Amount Paid Now (Rs.)'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Supplier Due Payable:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(AppFormatters.currency(due), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                                  ],
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
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedSupplier == null || selectedProduct == null) return;

                  // Parse IMEIs if phone
                  List<String> imeis = [];
                  if (isPhone && imeiListCtrl.text.isNotEmpty) {
                    imeis = imeiListCtrl.text
                        .split(RegExp(r'[\n,]'))
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                  }

                  final purchaseItem = PurchaseItem(
                    id: 'PI-${DateTime.now().millisecondsSinceEpoch}',
                    productId: selectedProduct!.id,
                    productName: selectedProduct!.name,
                    productType: selectedProduct!.type.name,
                    quantity: qty,
                    purchasePrice: unitCost,
                    total: totalBill,
                    imeiList: imeis,
                  );

                  final purchase = Purchase(
                    id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
                    invoiceNumber: invoiceNumCtrl.text.trim(),
                    supplierId: selectedSupplier!.id,
                    supplierName: selectedSupplier!.name,
                    purchaseDate: DateTime.now(),
                    totalAmount: totalBill,
                    paidAmount: paid,
                    dueAmount: due,
                    paymentMethod: paymentMethod,
                    notes: notesCtrl.text.trim(),
                    items: [purchaseItem],
                  );

                  await led.addPurchase(purchase);
                  await inv.loadInventory();
                  await app.refreshAlerts();

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchase #${purchase.invoiceNumber} recorded and stock updated!')),
                  );
                },
                child: const Text('Save Purchase'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPurchaseDetails(BuildContext context, Purchase pur) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Purchase Invoice #${pur.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier: ${pur.supplierName} • Date: ${AppFormatters.date(pur.purchaseDate)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Payment Method: ${pur.paymentMethod}'),
              const Divider(height: 16),
              const Text('ITEMS PURCHASED:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...pur.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${item.quantity} x ${AppFormatters.currency(item.purchasePrice)} = ${AppFormatters.currency(item.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (item.imeiList.isNotEmpty)
                        Text('IMEIs Received: ${item.imeiList.join(", ")}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bill:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(AppFormatters.currency(pur.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Paid Amount:'),
                  Text(AppFormatters.currency(pur.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ],
              ),
              if (pur.dueAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payable Due:', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                    Text(AppFormatters.currency(pur.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
