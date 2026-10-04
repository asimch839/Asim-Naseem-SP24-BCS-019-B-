import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/product.dart';
import '../../core/models/stock_movement.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    const Text('Inventory & Stock Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Monitor real-time stock levels, adjust inventory, and audit stock history', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_box_rounded, size: 16),
                  label: const Text('+ Add New Product'),
                  onPressed: () => _showAddProductDialog(context),
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
                Tab(text: 'All Products (${inv.products.length})'),
                Tab(text: 'Low Stock Alerts (${inv.products.where((p) => p.isLowStock).length})'),
                Tab(text: 'Out of Stock (${inv.products.where((p) => p.isOutOfStock).length})'),
                Tab(text: 'Stock Movement Audit History (${inv.movements.length})'),
              ],
            ),

            const SizedBox(height: 12),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All Products
                  _buildProductsTable(context, inv.products, isDark, inv, app),

                  // Tab 2: Low Stock
                  _buildProductsTable(context, inv.products.where((p) => p.isLowStock).toList(), isDark, inv, app),

                  // Tab 3: Out of Stock
                  _buildProductsTable(context, inv.products.where((p) => p.isOutOfStock).toList(), isDark, inv, app),

                  // Tab 4: Stock Movement Audit History
                  _buildMovementsTable(context, inv.movements, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(
    BuildContext context,
    List<Product> products,
    bool isDark,
    InventoryProvider inv,
    AppProvider app,
  ) {
    return Card(
      child: products.isEmpty
          ? const Center(child: Text('No products in this category.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product Name')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('SKU / Barcode')),
                    DataColumn(label: Text('Cost Price')),
                    DataColumn(label: Text('Sale Price')),
                    DataColumn(label: Text('Current Stock')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: products.map((prod) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(prod.brand, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        DataCell(Text(prod.type.displayName)),
                        DataCell(Text(prod.category)),
                        DataCell(Text(prod.sku)),
                        DataCell(Text(AppFormatters.currency(prod.purchasePrice))),
                        DataCell(Text(AppFormatters.currency(prod.salePrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Text(
                            '${prod.stockQuantity} pcs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: prod.isOutOfStock ? AppTheme.dangerRed : (prod.isLowStock ? AppTheme.warningOrange : null),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: prod.isOutOfStock
                                  ? AppTheme.dangerRed.withOpacity(0.12)
                                  : (prod.isLowStock ? AppTheme.warningOrange.withOpacity(0.12) : AppTheme.successGreen.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prod.isOutOfStock ? 'Out of Stock' : (prod.isLowStock ? 'Low Stock' : 'In Stock'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: prod.isOutOfStock ? AppTheme.dangerRed : (prod.isLowStock ? AppTheme.warningOrange : AppTheme.successGreen),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Adjust Stock (+ / -)',
                                icon: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryBlue),
                                onPressed: () => _showAdjustStockDialog(context, prod, inv, app),
                              ),
                              IconButton(
                                tooltip: 'Edit Product',
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showEditProductDialog(context, prod, inv),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                onPressed: () async {
                                  final ok = await AppDialogs.confirm(
                                    context,
                                    title: 'Delete Product',
                                    message: 'Are you sure you want to permanently delete "${prod.name}"?',
                                  );
                                  if (ok) {
                                    await inv.deleteProduct(prod.id);
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
    );
  }

  Widget _buildMovementsTable(BuildContext context, List<StockMovement> movements, bool isDark) {
    return Card(
      child: movements.isEmpty
          ? const Center(child: Text('No stock movement logs recorded.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date & Time')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Movement Type')),
                    DataColumn(label: Text('Qty Changed')),
                    DataColumn(label: Text('Before -> After')),
                    DataColumn(label: Text('Reference / Reason')),
                    DataColumn(label: Text('Performed By')),
                  ],
                  rows: movements.map((m) {
                    final isPositive = m.quantity > 0 &&
                        (m.movementType == 'purchase' || m.movementType == 'sale_return' || m.movementType == 'adjustment_add');

                    return DataRow(
                      cells: [
                        DataCell(Text(AppFormatters.dateTime(m.date), style: const TextStyle(fontSize: 12))),
                        DataCell(Text(m.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(m.typeDisplayName)),
                        DataCell(
                          Text(
                            '${isPositive ? "+" : "-"}${m.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                            ),
                          ),
                        ),
                        DataCell(Text('${m.previousStock} -> ${m.newStock} pcs')),
                        DataCell(Text(m.reason.isNotEmpty ? m.reason : m.referenceId)),
                        DataCell(Text(m.performedBy.isNotEmpty ? m.performedBy : 'Staff')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  void _showAdjustStockDialog(
    BuildContext context,
    Product prod,
    InventoryProvider inv,
    AppProvider app,
  ) {
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    String adjustmentType = 'add'; // 'add', 'remove', 'damaged'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Stock Adjustment (${prod.name})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Stock: ${prod.stockQuantity} pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: adjustmentType,
                    decoration: const InputDecoration(labelText: 'Adjustment Type'),
                    items: const [
                      DropdownMenuItem(value: 'add', child: Text('Add Stock (+) - Count Correction / Found')),
                      DropdownMenuItem(value: 'remove', child: Text('Deduct Stock (-) - Loss / Correction')),
                      DropdownMenuItem(value: 'damaged', child: Text('Damaged / Broken Stock (-)')),
                    ],
                    onChanged: (v) => setState(() => adjustmentType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity to Adjust'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Reason for Adjustment *', hintText: 'e.g. Physical inventory count verified'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty <= 0) return;

                  final delta = adjustmentType == 'add' ? qty : -qty;
                  final reason = reasonCtrl.text.trim().isNotEmpty
                      ? reasonCtrl.text.trim()
                      : (adjustmentType == 'damaged' ? 'Damaged stock deduction' : 'Manual stock adjustment');

                  await inv.adjustStock(
                    productId: prod.id,
                    delta: delta,
                    reason: reason,
                    performedBy: app.currentUser.name,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stock adjusted for ${prod.name}! New stock: ${prod.stockQuantity + delta}')),
                  );
                },
                child: const Text('Save Adjustment'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final skuCtrl = TextEditingController(text: 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final barcodeCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final minStockCtrl = TextEditingController(text: '3');
    final descCtrl = TextEditingController();

    ProductType selectedType = ProductType.accessory;
    String selectedCategory = 'Chargers';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ProductType>(
                            value: selectedType,
                            decoration: const InputDecoration(labelText: 'Product Type *'),
                            items: ProductType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                            onChanged: (v) => setState(() => selectedType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: const InputDecoration(labelText: 'Category *'),
                            items: const [
                              DropdownMenuItem(value: 'Smartphones', child: Text('Smartphones')),
                              DropdownMenuItem(value: 'Chargers', child: Text('Chargers')),
                              DropdownMenuItem(value: 'Cables', child: Text('Cables')),
                              DropdownMenuItem(value: 'Earphones', child: Text('Earphones')),
                              DropdownMenuItem(value: 'Power Banks', child: Text('Power Banks')),
                              DropdownMenuItem(value: 'Screen Protectors', child: Text('Screen Protectors')),
                              DropdownMenuItem(value: 'Back Covers', child: Text('Back Covers')),
                              DropdownMenuItem(value: 'LCD / OLED Screens', child: Text('LCD / OLED Screens')),
                              DropdownMenuItem(value: 'Batteries', child: Text('Batteries')),
                              DropdownMenuItem(value: 'Charging Ports & Flex', child: Text('Charging Ports & Flex')),
                              DropdownMenuItem(value: 'Repair Tools', child: Text('Repair Tools')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => selectedCategory = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU Code *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (Rs.) *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale Price (Rs.) *'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: minStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Stock Alert Threshold'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Specifications')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || brandCtrl.text.isEmpty) return;

                  final prod = Product(
                    id: 'PRD-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    type: selectedType,
                    category: selectedCategory,
                    brand: brandCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                    sku: skuCtrl.text.trim(),
                    barcode: barcodeCtrl.text.trim(),
                    purchasePrice: double.tryParse(costCtrl.text) ?? 0.0,
                    salePrice: double.tryParse(priceCtrl.text) ?? 0.0,
                    stockQuantity: int.tryParse(stockCtrl.text) ?? 0,
                    minStockAlert: int.tryParse(minStockCtrl.text) ?? 3,
                    description: descCtrl.text.trim(),
                  );

                  await ctx.read<InventoryProvider>().addProduct(prod);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product prod, InventoryProvider inv) {
    final nameCtrl = TextEditingController(text: prod.name);
    final costCtrl = TextEditingController(text: prod.purchasePrice.toStringAsFixed(0));
    final priceCtrl = TextEditingController(text: prod.salePrice.toStringAsFixed(0));
    final minStockCtrl = TextEditingController(text: prod.minStockAlert.toString());
    final barcodeCtrl = TextEditingController(text: prod.barcode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit "${prod.name}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 10),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (Rs.)')),
              const SizedBox(height: 10),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale Price (Rs.)')),
              const SizedBox(height: 10),
              TextField(controller: minStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Stock Alert Threshold')),
              const SizedBox(height: 10),
              TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = prod.copyWith(
                name: nameCtrl.text.trim(),
                purchasePrice: double.tryParse(costCtrl.text) ?? prod.purchasePrice,
                salePrice: double.tryParse(priceCtrl.text) ?? prod.salePrice,
                minStockAlert: int.tryParse(minStockCtrl.text) ?? prod.minStockAlert,
                barcode: barcodeCtrl.text.trim(),
              );
              await inv.updateProduct(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
