import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/models/product.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class AccessoriesScreen extends StatefulWidget {
  const AccessoriesScreen({super.key});

  @override
  State<AccessoriesScreen> createState() => _AccessoriesScreenState();
}

class _AccessoriesScreenState extends State<AccessoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedSubtype = 'All'; // 'All', 'Accessories', 'Repair Parts'

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = _searchCtrl.text.trim().toLowerCase();

    final items = inv.products.where((p) {
      if (p.type == ProductType.phone) return false;
      if (_selectedSubtype == 'Accessories' && p.type != ProductType.accessory) return false;
      if (_selectedSubtype == 'Repair Parts' && p.type != ProductType.part) return false;

      if (q.isNotEmpty) {
        final matches = p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q);
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
                    const Text('Accessories & Repair Parts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Manage chargers, cables, batteries, displays, and repair replacement parts', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('+ Add Accessory / Part'),
                  onPressed: () => _showAddDialog(context),
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
                      hintText: 'Search by accessory name, category, SKU, or barcode...',
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
                    value: _selectedSubtype,
                    decoration: const InputDecoration(labelText: 'Classification'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Accessories & Parts')),
                      DropdownMenuItem(value: 'Accessories', child: Text('Accessories Only')),
                      DropdownMenuItem(value: 'Repair Parts', child: Text('Repair Lab Parts Only')),
                    ],
                    onChanged: (v) => setState(() => _selectedSubtype = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Items Table
            Expanded(
              child: Card(
                child: items.isEmpty
                    ? const Center(child: Text('No accessories or repair parts match your search.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Item Name')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('SKU / Barcode')),
                              DataColumn(label: Text('Purchase Cost')),
                              DataColumn(label: Text('Retail Price')),
                              DataColumn(label: Text('Profit Margin')),
                              DataColumn(label: Text('Stock')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: items.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(item.brand, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.type == ProductType.part ? const Color(0xFFEDE9FE) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.type.displayName,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: item.type == ProductType.part ? AppTheme.purpleRepair : AppTheme.successGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(item.category)),
                                  DataCell(Text(item.sku)),
                                  DataCell(Text(AppFormatters.currency(item.purchasePrice))),
                                  DataCell(Text(AppFormatters.currency(item.salePrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(AppFormatters.currency(item.profitMargin), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600))),
                                  DataCell(
                                    Text(
                                      '${item.stockQuantity} pcs',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: item.isOutOfStock ? AppTheme.dangerRed : (item.isLowStock ? AppTheme.warningOrange : null),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      item.isOutOfStock ? 'Out of Stock' : (item.isLowStock ? 'Low Stock' : 'In Stock'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: item.isOutOfStock ? AppTheme.dangerRed : (item.isLowStock ? AppTheme.warningOrange : AppTheme.successGreen),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Adjust Stock',
                                          icon: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryBlue),
                                          onPressed: () => _showQuickAdjustDialog(context, item, inv),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete Item',
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                          onPressed: () async {
                                            final ok = await AppDialogs.confirm(
                                              context,
                                              title: 'Delete Item',
                                              message: 'Delete "${item.name}" from inventory?',
                                            );
                                            if (ok) {
                                              await inv.deleteProduct(item.id);
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

  void _showQuickAdjustDialog(BuildContext context, Product item, InventoryProvider inv) {
    final qtyCtrl = TextEditingController(text: '5');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quick Restock (${item.name})'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${item.stockQuantity} pcs', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity to Add (+)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final q = int.tryParse(qtyCtrl.text) ?? 0;
              if (q > 0) {
                await inv.adjustStock(
                  productId: item.id,
                  delta: q,
                  reason: 'Quick accessory restock',
                  performedBy: 'Staff',
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final skuCtrl = TextEditingController(text: 'ACC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    final minStockCtrl = TextEditingController(text: '3');
    ProductType type = ProductType.accessory;
    String category = 'Chargers';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Accessory / Repair Part', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ProductType>(
                            value: type,
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: const [
                              DropdownMenuItem(value: ProductType.accessory, child: Text('Accessory')),
                              DropdownMenuItem(value: ProductType.part, child: Text('Repair Lab Part')),
                            ],
                            onChanged: (v) => setState(() => type = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: const [
                              DropdownMenuItem(value: 'Chargers', child: Text('Chargers')),
                              DropdownMenuItem(value: 'Cables', child: Text('Cables')),
                              DropdownMenuItem(value: 'Earphones', child: Text('Earphones')),
                              DropdownMenuItem(value: 'Power Banks', child: Text('Power Banks')),
                              DropdownMenuItem(value: 'Screen Protectors', child: Text('Screen Protectors')),
                              DropdownMenuItem(value: 'Back Covers', child: Text('Back Covers')),
                              DropdownMenuItem(value: 'LCD / OLED Screens', child: Text('LCD / OLED Screens')),
                              DropdownMenuItem(value: 'Batteries', child: Text('Batteries')),
                              DropdownMenuItem(value: 'Charging Ports & Flex', child: Text('Charging Ports & Flex')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => category = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name *')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU Code *'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (Rs.) *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale Price (Rs.) *'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Quantity'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: minStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Stock Alert Threshold'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || brandCtrl.text.isEmpty) return;

                  final p = Product(
                    id: 'PRD-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    type: type,
                    category: category,
                    brand: brandCtrl.text.trim(),
                    sku: skuCtrl.text.trim(),
                    purchasePrice: double.tryParse(costCtrl.text) ?? 0.0,
                    salePrice: double.tryParse(priceCtrl.text) ?? 0.0,
                    stockQuantity: int.tryParse(stockCtrl.text) ?? 0,
                    minStockAlert: int.tryParse(minStockCtrl.text) ?? 3,
                  );

                  await ctx.read<InventoryProvider>().addProduct(p);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Item'),
              ),
            ],
          );
        },
      ),
    );
  }
}
