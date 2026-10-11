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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LedgerProvider>().loadAll();
        context.read<InventoryProvider>().loadInventory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final led = context.watch<LedgerProvider>();
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

  Future<Supplier?> _showQuickAddSupplierDialog(BuildContext context, LedgerProvider led) async {
    final companyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    return await showDialog<Supplier>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.business_rounded, color: AppTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Text('Quick Add Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(labelText: 'Company / Shop Name *'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (companyCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter Company Name and Phone Number.')),
                );
                return;
              }
              final newSupplier = Supplier(
                id: 'SUP-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : companyCtrl.text.trim(),
                company: companyCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              await led.addSupplier(newSupplier);
              if (ctx.mounted) {
                Navigator.pop(ctx, newSupplier);
              }
            },
            child: const Text('Add Supplier'),
          ),
        ],
      ),
    );
  }

  void _showNewPurchaseDialog(BuildContext context) {
    final led = context.read<LedgerProvider>();
    final inv = context.read<InventoryProvider>();
    final app = context.read<AppProvider>();

    Supplier? selectedSupplier = led.suppliers.isNotEmpty ? led.suppliers.first : null;
    Product? selectedProduct = inv.products.isNotEmpty ? inv.products.first : null;

    final invoiceNumCtrl = TextEditingController(
      text: 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final notesCtrl = TextEditingController();
    final paidCtrl = TextEditingController(text: '0');
    String paymentMethod = 'Bank Transfer';

    // Active Line Item controllers
    bool isNewProductMode = inv.products.isEmpty;
    final newProdNameCtrl = TextEditingController();
    final newProdBrandCtrl = TextEditingController();
    ProductType newProdType = ProductType.phone;
    String newProdCategory = 'Smartphones';
    final newProdSalePriceCtrl = TextEditingController(text: '0');

    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(
      text: selectedProduct != null ? selectedProduct.purchasePrice.toStringAsFixed(0) : '0',
    );
    final imeiListCtrl = TextEditingController();

    // Multi-item list
    final List<PurchaseItem> itemsList = [];
    final List<Product> newlyAddedProductsToSave = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
          final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

          final currentQty = int.tryParse(qtyCtrl.text) ?? 1;
          final currentCost = double.tryParse(costCtrl.text) ?? 0.0;
          final currentLineTotal = currentQty * currentCost;

          // If itemsList has items, total bill is sum of itemsList; otherwise current line total
          final double totalBill = itemsList.isNotEmpty
              ? itemsList.fold(0.0, (sum, i) => sum + i.total)
              : currentLineTotal;

          final paid = double.tryParse(paidCtrl.text) ?? 0.0;
          final due = (totalBill - paid).clamp(0.0, double.infinity);

          final bool isCurrentProductPhone = isNewProductMode
              ? (newProdType == ProductType.phone)
              : (selectedProduct?.type == ProductType.phone);

          final enteredImeis = imeiListCtrl.text
              .split(RegExp(r'[\n,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Record Supplier Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Restock items, add new consignments & update supplier ledger',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  tooltip: 'Close',
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 680,
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              child: SizedBox(
                width: 680,
                child: Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // --- 1. Supplier & Invoice Row ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text('SUPPLIER & INVOICE DETAILS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  final newSup = await _showQuickAddSupplierDialog(context, led);
                                  if (newSup != null) {
                                    setState(() {
                                      selectedSupplier = newSup;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_circle_outline, size: 14, color: AppTheme.primaryBlue),
                                      SizedBox(width: 4),
                                      Text('+ Add New Supplier', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (led.suppliers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('No suppliers found. Click "+ Add New Supplier" to create one first.', style: TextStyle(fontSize: 12)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                    onPressed: () async {
                                      final newSup = await _showQuickAddSupplierDialog(context, led);
                                      if (newSup != null) {
                                        setState(() => selectedSupplier = newSup);
                                      }
                                    },
                                    child: const Text('Add Supplier', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: selectedSupplier?.id,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Select Supplier *', prefixIcon: Icon(Icons.business_outlined, size: 18)),
                              items: led.suppliers.map((s) {
                                return DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.name} (${s.company})', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id != null) {
                                  setState(() => selectedSupplier = led.suppliers.firstWhere((s) => s.id == id));
                                }
                              },
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: invoiceNumCtrl,
                                  decoration: const InputDecoration(labelText: 'Supplier Invoice # *', prefixIcon: Icon(Icons.receipt_outlined, size: 18)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: paymentMethod,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payments_outlined, size: 18)),
                                  items: const [
                                    DropdownMenuItem(value: 'Cash', child: Text('Cash', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa', overflow: TextOverflow.ellipsis)),
                                  ],
                                  onChanged: (v) => setState(() => paymentMethod = v!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- 2. Item Entry Section ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text('PRODUCT / ITEM TO PURCHASE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Toggle between Restock Existing vs Add New Product
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isNewProductMode = false;
                                          if (selectedProduct != null) {
                                            costCtrl.text = selectedProduct!.purchasePrice.toStringAsFixed(0);
                                          }
                                        });
                                      },
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: !isNewProductMode ? AppTheme.primaryBlue : Colors.transparent,
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                        ),
                                        child: Text(
                                          'Restock Existing',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !isNewProductMode ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700])),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isNewProductMode = true;
                                        });
                                      },
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isNewProductMode ? AppTheme.primaryBlue : Colors.transparent,
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                                        ),
                                        child: Text(
                                          '+ New Product',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isNewProductMode ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700])),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (!isNewProductMode) ...[
                            if (inv.products.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('No products exist yet in inventory. Switch to "+ New Product" above to create your product.', style: TextStyle(fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => isNewProductMode = true),
                                      child: const Text('Switch to New Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: selectedProduct?.id,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Select Product to Restock *', prefixIcon: Icon(Icons.inventory_2_outlined, size: 18)),
                                items: inv.products.map((p) {
                                  return DropdownMenuItem(
                                    value: p.id,
                                    child: Text('${p.name} (${p.category}) • Stock: ${p.stockQuantity} pcs', overflow: TextOverflow.ellipsis),
                                  );
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
                          ] else ...[
                            // New Product Form fields
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: newProdNameCtrl,
                                    decoration: const InputDecoration(labelText: 'Product Name *', hintText: 'e.g. Infinix Hot 40 Pro', prefixIcon: Icon(Icons.shopping_bag_outlined, size: 18)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<ProductType>(
                                    initialValue: newProdType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Type *'),
                                    items: ProductType.values.map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.displayName, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (t) => setState(() => newProdType = t!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: newProdBrandCtrl,
                                    decoration: const InputDecoration(labelText: 'Brand *', hintText: 'e.g. Infinix, Samsung, Apple'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: newProdCategory,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Category *'),
                                    items: const [
                                      DropdownMenuItem(value: 'Smartphones', child: Text('Smartphones', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Chargers', child: Text('Chargers', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Cables', child: Text('Cables', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Earphones', child: Text('Earphones / Earbuds', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Power Banks', child: Text('Power Banks', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Screen Protectors', child: Text('Screen Protectors', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Back Covers', child: Text('Back Covers', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'LCD / OLED Screens', child: Text('LCD / Screens', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Batteries', child: Text('Batteries', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'Other', child: Text('Other', overflow: TextOverflow.ellipsis)),
                                    ],
                                    onChanged: (c) => setState(() => newProdCategory = c!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: newProdSalePriceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Target Sale Price (Rs.) *'),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Quantity *', prefixIcon: Icon(Icons.numbers_outlined, size: 18)),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: costCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Purchase Unit Price (Rs.) *', prefixIcon: Icon(Icons.price_change_outlined, size: 18)),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Line Subtotal', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(AppFormatters.currency(currentLineTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // If phone, IMEI input field
                          if (isCurrentProductPhone) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Phone IMEIs (${enteredImeis.length} / $currentQty entered)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: enteredImeis.length == currentQty ? AppTheme.successGreen : (enteredImeis.isEmpty ? Colors.grey : AppTheme.warningOrange),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                                  label: Text('Generate $currentQty Dummy IMEIs', style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    final dummy = List.generate(
                                      currentQty,
                                      (i) => '35${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}${i.toString().padLeft(2, '0')}',
                                    ).join('\n');
                                    imeiListCtrl.text = dummy;
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            TextField(
                              controller: imeiListCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Enter 15-digit IMEIs separated by line breaks or commas\ne.g. 358941092837461',
                                hintStyle: TextStyle(fontSize: 11.5),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],

                          const SizedBox(height: 10),
                          // Add Item to Invoice button
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                              label: const Text('+ Add Item to Invoice List'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: () {
                                if (isNewProductMode) {
                                  if (newProdNameCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Product Name.')));
                                    return;
                                  }
                                } else {
                                  if (selectedProduct == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product to restock.')));
                                    return;
                                  }
                                }

                                if (currentQty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be at least 1.')));
                                  return;
                                }
                                if (currentCost <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit cost must be greater than 0.')));
                                  return;
                                }

                                String prodId = '';
                                String prodName = '';
                                String prodTypeStr = '';

                                if (isNewProductMode) {
                                  prodId = 'PRD-${DateTime.now().millisecondsSinceEpoch}-${itemsList.length}';
                                  prodName = newProdNameCtrl.text.trim();
                                  prodTypeStr = newProdType.name;

                                  final newProd = Product(
                                    id: prodId,
                                    name: prodName,
                                    type: newProdType,
                                    category: newProdCategory,
                                    brand: newProdBrandCtrl.text.trim().isNotEmpty ? newProdBrandCtrl.text.trim() : 'General',
                                    sku: 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                    purchasePrice: currentCost,
                                    salePrice: double.tryParse(newProdSalePriceCtrl.text) ?? (currentCost * 1.15),
                                    stockQuantity: 0,
                                  );
                                  newlyAddedProductsToSave.add(newProd);
                                } else {
                                  prodId = selectedProduct!.id;
                                  prodName = selectedProduct!.name;
                                  prodTypeStr = selectedProduct!.type.name;
                                }

                                final lineItem = PurchaseItem(
                                  id: 'PI-${DateTime.now().millisecondsSinceEpoch}-${itemsList.length}',
                                  productId: prodId,
                                  productName: prodName,
                                  productType: prodTypeStr,
                                  quantity: currentQty,
                                  purchasePrice: currentCost,
                                  total: currentLineTotal,
                                  imeiList: enteredImeis,
                                );

                                setState(() {
                                  itemsList.add(lineItem);
                                  // Clear active line
                                  qtyCtrl.text = '1';
                                  imeiListCtrl.clear();
                                  newProdNameCtrl.clear();
                                  newProdBrandCtrl.clear();
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added "$prodName" to purchase invoice list!'), duration: const Duration(seconds: 1)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Table of Items in Invoice (if any added) ---
                    if (itemsList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ITEMS IN THIS INVOICE (${itemsList.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                                Text('Total Items: ${itemsList.fold(0, (s, i) => s + i.quantity)} pcs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: itemsList.length,
                              separatorBuilder: (context, index) => Divider(color: cardBorder, height: 10),
                              itemBuilder: (context, idx) {
                                final it = itemsList[idx];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(
                                            '${it.quantity} pcs @ ${AppFormatters.currency(it.purchasePrice)} = ${AppFormatters.currency(it.total)}${it.imeiList.isNotEmpty ? " • ${it.imeiList.length} IMEIs" : ""}',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          itemsList.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // --- 3. Financial Summary Card (FIXES THE SCREENSHOT BUG!) ---
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CALCULATED TOTAL BILL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        AppFormatters.currency(totalBill),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ActionChip(
                                    label: const Text('Paid Full', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      setState(() {
                                        paidCtrl.text = totalBill.toStringAsFixed(0);
                                      });
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('Unpaid (Rs. 0)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      setState(() {
                                        paidCtrl.text = '0';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: paidCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount Paid Now (Rs.)',
                                    prefixText: 'Rs. ',
                                    prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: due > 0 ? AppTheme.dangerRed.withValues(alpha: 0.1) : AppTheme.successGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: due > 0 ? AppTheme.dangerRed.withValues(alpha: 0.3) : AppTheme.successGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'SUPPLIER DUE PAYABLE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: due > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          due > 0 ? AppFormatters.currency(due) : 'Rs. 0 (Fully Cleared)',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: due > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- 4. Notes / Remarks Field ---
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Notes / Invoice Remarks (Optional)',
                        prefixIcon: Icon(Icons.notes_rounded, size: 18),
                      ),
                    ),
                      ],
                    ),
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
                  if (selectedSupplier == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select or add a supplier first.')),
                    );
                    return;
                  }

                  // If itemsList is empty, build item from current active inputs
                  List<PurchaseItem> finalItems = List.from(itemsList);
                  List<Product> productsToInsert = List.from(newlyAddedProductsToSave);

                  if (finalItems.isEmpty) {
                    if (isNewProductMode) {
                      if (newProdNameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter Product Name.')),
                        );
                        return;
                      }
                    } else {
                      if (selectedProduct == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a product to restock or create a new product.')),
                        );
                        return;
                      }
                    }

                    if (currentQty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quantity must be at least 1.')),
                      );
                      return;
                    }
                    if (currentCost <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchase Unit Price must be greater than 0.')),
                      );
                      return;
                    }

                    String pId = '';
                    String pName = '';
                    String pType = '';

                    if (isNewProductMode) {
                      pId = 'PRD-${DateTime.now().millisecondsSinceEpoch}';
                      pName = newProdNameCtrl.text.trim();
                      pType = newProdType.name;

                      final newProd = Product(
                        id: pId,
                        name: pName,
                        type: newProdType,
                        category: newProdCategory,
                        brand: newProdBrandCtrl.text.trim().isNotEmpty ? newProdBrandCtrl.text.trim() : 'General',
                        sku: 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        purchasePrice: currentCost,
                        salePrice: double.tryParse(newProdSalePriceCtrl.text) ?? (currentCost * 1.15),
                        stockQuantity: 0,
                      );
                      productsToInsert.add(newProd);
                    } else {
                      pId = selectedProduct!.id;
                      pName = selectedProduct!.name;
                      pType = selectedProduct!.type.name;
                    }

                    final singleItem = PurchaseItem(
                      id: 'PI-${DateTime.now().millisecondsSinceEpoch}',
                      productId: pId,
                      productName: pName,
                      productType: pType,
                      quantity: currentQty,
                      purchasePrice: currentCost,
                      total: currentLineTotal,
                      imeiList: enteredImeis,
                    );
                    finalItems.add(singleItem);
                  }

                  // Insert any new products
                  for (var np in productsToInsert) {
                    await inv.addProduct(np);
                  }

                  final calculatedTotal = finalItems.fold(0.0, (s, i) => s + i.total);
                  final finalPaid = double.tryParse(paidCtrl.text) ?? 0.0;
                  final finalDue = (calculatedTotal - finalPaid).clamp(0.0, double.infinity);

                  final purchase = Purchase(
                    id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
                    invoiceNumber: invoiceNumCtrl.text.trim().isNotEmpty
                        ? invoiceNumCtrl.text.trim()
                        : 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    supplierId: selectedSupplier!.id,
                    supplierName: selectedSupplier!.name,
                    purchaseDate: DateTime.now(),
                    totalAmount: calculatedTotal,
                    paidAmount: finalPaid,
                    dueAmount: finalDue,
                    paymentMethod: paymentMethod,
                    notes: notesCtrl.text.trim(),
                    items: finalItems,
                  );

                  await led.addPurchase(purchase);
                  await inv.loadInventory();
                  await app.refreshAlerts();

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Purchase #${purchase.invoiceNumber} recorded and stock updated!')),
                    );
                  }
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
            Expanded(
              child: Text(
                'Purchase Invoice #${pur.invoiceNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SizedBox(
            width: 560,
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Supplier: ${pur.supplierName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Date: ${AppFormatters.date(pur.purchaseDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: pur.dueAmount > 0 ? AppTheme.dangerRed.withOpacity(0.12) : AppTheme.successGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pur.dueAmount > 0 ? 'Due: ${AppFormatters.currency(pur.dueAmount)}' : 'Fully Cleared',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: pur.dueAmount > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.payment_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Payment Mode: ${pur.paymentMethod}', style: const TextStyle(fontSize: 12)),
                          if (pur.notes.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Notes: ${pur.notes}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('ITEMS PURCHASED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                ...pur.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${item.quantity} x ${AppFormatters.currency(item.purchasePrice)} = ${AppFormatters.currency(item.total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        if (item.imeiList.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: item.imeiList.map((im) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('IMEI: $im', style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryBlue, fontFamily: 'monospace')),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Divider(color: cardBorder),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bill:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(AppFormatters.currency(pur.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paid Amount:'),
                    Text(AppFormatters.currency(pur.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (pur.dueAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payable Due:', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                      Text(AppFormatters.currency(pur.dueAmount), style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
