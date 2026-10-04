import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/pos_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/product.dart';
import '../../core/models/phone_item.dart';
import '../../core/models/customer.dart';
import '../../core/services/print_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_dialogs.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final inv = context.watch<InventoryProvider>();
    final led = context.watch<LedgerProvider>();
    final app = context.watch<AppProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _searchCtrl.text.trim().toLowerCase();

    // Filtered products for catalog
    final filteredCatalog = inv.products.where((p) {
      if (_selectedCategory != 'All' && p.category != _selectedCategory) return false;
      if (query.isNotEmpty) {
        final matches = p.name.toLowerCase().contains(query) ||
            p.brand.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            p.barcode.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          // Left: Product Catalog & Fast Search
          Expanded(
            flex: 6,
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Barcode Scan Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search product name, SKU, barcode, or IMEI...',
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
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: const Text('Scan / IMEI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkNavy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showImeiScanDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Categories Filter Ribbon
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: inv.categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product Grid
                  Expanded(
                    child: filteredCatalog.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                                const SizedBox(height: 10),
                                const Text('No products match your search/category.'),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filteredCatalog.length,
                            itemBuilder: (context, idx) {
                              final product = filteredCatalog[idx];
                              return _buildProductCard(context, product, inv, pos, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Active Sale Cart / Register
          Container(
            width: 460,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Cart Header: Customer Selection & Held Sales
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: pos.selectedCustomer?.id,
                            hint: const Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 18, color: AppTheme.primaryBlue),
                                SizedBox(width: 8),
                                Text('Walk-in Customer (Select / Create)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Walk-in Customer'),
                              ),
                              ...led.customers.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text('${c.name} (${c.phone}) ${c.totalDue > 0 ? "• Due: ${AppFormatters.currency(c.totalDue)}" : ""}'),
                                );
                              }),
                            ],
                            onChanged: (id) {
                              if (id == null) {
                                pos.setCustomer(null);
                              } else {
                                final cust = led.customers.firstWhere((c) => c.id == id);
                                pos.setCustomer(cust);
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add New Customer (F3)',
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppTheme.primaryBlue),
                        onPressed: () async {
                          final newCust = await AppDialogs.showNewCustomerDialog(context);
                          if (newCust != null) {
                            pos.setCustomer(newCust);
                          }
                        },
                      ),
                      if (pos.heldSales.isNotEmpty)
                        Badge(
                          label: Text('${pos.heldSales.length}'),
                          child: IconButton(
                            tooltip: 'Resume Held Sales',
                            icon: const Icon(Icons.pause_circle_outline_rounded, size: 22, color: AppTheme.warningOrange),
                            onPressed: () => _showResumeHeldSalesDialog(context, pos),
                          ),
                        ),
                    ],
                  ),
                ),

                // Cart Item List
                Expanded(
                  child: pos.cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                              const SizedBox(height: 10),
                              const Text('Cart is empty. Click items on the left to add.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          itemCount: pos.cartItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final item = pos.cartItems[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        if (item.imei.isNotEmpty)
                                          Text('IMEI: ${item.imei}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                                        Text('${AppFormatters.currency(item.unitPrice)} each', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),

                                  // Quantity controls (if not phone)
                                  if (item.productType != 'phone') ...[
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => pos.updateQuantity(item.id, -1),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => pos.updateQuantity(item.id, 1),
                                    ),
                                  ] else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('1 pc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                    ),

                                  const SizedBox(width: 8),

                                  // Line Total
                                  SizedBox(
                                    width: 75,
                                    child: Text(
                                      AppFormatters.currency(item.total),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                    onPressed: () => pos.removeFromCart(item.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Cart Summary & Checkout Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Subtotal & Discount Rows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(AppFormatters.currency(pos.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          SizedBox(
                            width: 110,
                            height: 32,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: 'Rs. ',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              style: const TextStyle(fontSize: 12),
                              onChanged: (val) {
                                final d = double.tryParse(val) ?? 0.0;
                                pos.setCartDiscount(d);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(AppFormatters.currency(pos.grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Payment Method Dropdown
                      Row(
                        children: [
                          const Text('Payment Mode: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: pos.paymentMethod,
                              isDense: true,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                                DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                                DropdownMenuItem(value: 'Card', child: Text('Card / POS Machine')),
                                DropdownMenuItem(value: 'Due', child: Text('Customer Due (Full Credit)')),
                                DropdownMenuItem(value: 'Split', child: Text('Multiple / Split Payment')),
                              ],
                              onChanged: (m) {
                                if (m != null) {
                                  pos.setPaymentMethod(m);
                                  if (m == 'Split') {
                                    _showSplitPaymentDialog(context, pos);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      if (pos.remainingDue > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Due Balance Remaining:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                            Text(AppFormatters.currency(pos.remainingDue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Checkout & Hold Action Buttons
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: pos.cartItems.isEmpty ? null : () => _showHoldSaleDialog(context, pos),
                            child: const Text('Hold Sale'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.print_rounded, size: 18),
                              label: const Text('Complete & Print (Enter)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: pos.cartItems.isEmpty || pos.isProcessing
                                  ? null
                                  : () => _handleCheckout(context, pos, app),
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
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    InventoryProvider inv,
    PosProvider pos,
    bool isDark,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (product.type == ProductType.phone) {
            _showPhoneImeiPicker(context, product, inv, pos);
          } else {
            pos.addToCartProduct(product);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: product.type == ProductType.phone
                          ? const Color(0xFFE0F2FE)
                          : (product.type == ProductType.part ? const Color(0xFFEDE9FE) : const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      product.type == ProductType.phone
                          ? Icons.phone_android_rounded
                          : (product.type == ProductType.part ? Icons.memory_rounded : Icons.cable_rounded),
                      size: 18,
                      color: product.type == ProductType.phone
                          ? AppTheme.primaryBlue
                          : (product.type == ProductType.part ? AppTheme.purpleRepair : AppTheme.successGreen),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.brand,
                          style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppFormatters.currency(product.salePrice),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryBlue),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.isOutOfStock
                          ? AppTheme.dangerRed.withOpacity(0.1)
                          : (product.isLowStock ? AppTheme.warningOrange.withOpacity(0.1) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.stockQuantity} in stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: product.isOutOfStock ? AppTheme.dangerRed : (product.isLowStock ? AppTheme.warningOrange : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhoneImeiPicker(
    BuildContext context,
    Product product,
    InventoryProvider inv,
    PosProvider pos,
  ) {
    final availablePhones = inv.phones
        .where((ph) => ph.productId == product.id && ph.status == 'In Stock')
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select In-Stock Phone Unit (${product.name})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: availablePhones.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No units in stock with assigned IMEI.')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePhones.length,
                  itemBuilder: (c, idx) {
                    final ph = availablePhones[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: const Icon(Icons.phone_android_rounded, color: AppTheme.primaryBlue),
                        title: Text('${ph.model} (${ph.color}) - ${ph.ptaStatus}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('IMEI 1: ${ph.imei1}\nCondition: ${ph.condition} • Warranty: ${ph.warrantyPeriod}', style: const TextStyle(fontSize: 11)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            pos.addToCartPhone(ph);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Add to Cart'),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showImeiScanDialog(BuildContext context) {
    final imeiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Scan Barcode or Enter IMEI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: imeiCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Barcode or 15-Digit IMEI',
              hintText: 'e.g. 358941092837461',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final term = imeiCtrl.text.trim();
              if (term.isEmpty) return;
              final inv = ctx.read<InventoryProvider>();
              final pos = ctx.read<PosProvider>();

              // Check Phone Items by IMEI
              final phone = await inv.findByImei(term);
              if (phone != null) {
                if (phone.status != 'In Stock') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone with IMEI $term is already marked as "${phone.status}".')),
                  );
                } else {
                  pos.addToCartPhone(phone);
                  Navigator.pop(ctx);
                  return;
                }
              }

              // Check by Barcode or SKU
              final prod = inv.products.where((p) => p.barcode == term || p.sku == term).firstOrNull;
              if (prod != null) {
                pos.addToCartProduct(prod);
                Navigator.pop(ctx);
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No item found with barcode / IMEI "$term".')),
              );
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _showSplitPaymentDialog(BuildContext context, PosProvider pos) {
    final cashCtrl = TextEditingController(text: (pos.grandTotal * 0.6).toStringAsFixed(0));
    final jazzCtrl = TextEditingController(text: (pos.grandTotal * 0.4).toStringAsFixed(0));
    final easyCtrl = TextEditingController(text: '0');
    final bankCtrl = TextEditingController(text: '0');
    final dueCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final c = double.tryParse(cashCtrl.text) ?? 0.0;
          final j = double.tryParse(jazzCtrl.text) ?? 0.0;
          final e = double.tryParse(easyCtrl.text) ?? 0.0;
          final b = double.tryParse(bankCtrl.text) ?? 0.0;
          final d = double.tryParse(dueCtrl.text) ?? 0.0;
          final totalPaying = c + j + e + b;
          final diff = pos.grandTotal - (totalPaying + d);

          return AlertDialog(
            title: const Text('Multiple / Split Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total Bill: ${AppFormatters.currency(pos.grandTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(controller: cashCtrl, decoration: const InputDecoration(labelText: 'Cash Paid (Rs.)'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextField(controller: jazzCtrl, decoration: const InputDecoration(labelText: 'JazzCash Paid (Rs.)'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextField(controller: easyCtrl, decoration: const InputDecoration(labelText: 'Easypaisa Paid (Rs.)'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank Transfer (Rs.)'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextField(controller: dueCtrl, decoration: const InputDecoration(labelText: 'Customer Due (Remaining to pay later)'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),
                  if (diff.abs() > 1)
                    Text('Difference: Rs. ${diff.abs().toStringAsFixed(0)} ${diff > 0 ? "Underpaid" : "Overpaid"}', style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold))
                  else
                    const Text('Payments match total bill exactly!', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final split = <String, double>{};
                  if (c > 0) split['Cash'] = c;
                  if (j > 0) split['JazzCash'] = j;
                  if (e > 0) split['Easypaisa'] = e;
                  if (b > 0) split['Bank Transfer'] = b;
                  if (d > 0) split['Due'] = d;
                  pos.setSplitPayments(split);
                  Navigator.pop(ctx);
                },
                child: const Text('Confirm Split'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHoldSaleDialog(BuildContext context, PosProvider pos) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hold Current Sale'),
        content: SizedBox(
          width: 350,
          child: TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Note / Customer Reference'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              pos.holdCurrentSale(noteCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Hold Sale'),
          ),
        ],
      ),
    );
  }

  void _showResumeHeldSalesDialog(BuildContext context, PosProvider pos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resume Held Sales'),
        content: SizedBox(
          width: 450,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pos.heldSales.length,
            itemBuilder: (c, idx) {
              final h = pos.heldSales[idx];
              return ListTile(
                title: Text('${h.customer?.name ?? "Walk-in"} • ${h.items.length} items'),
                subtitle: Text('Held: ${AppFormatters.time(h.heldAt)} ${h.note.isNotEmpty ? "• Note: ${h.note}" : ""}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    pos.resumeSale(h);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Resume'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, PosProvider pos, AppProvider app) async {
    try {
      final sale = await pos.checkout(
        settings: app.settings,
        cashierId: app.currentUser.id,
        cashierName: app.currentUser.name,
      );

      // Refresh inventory & ledger
      context.read<InventoryProvider>().loadInventory();
      context.read<LedgerProvider>().loadAll();
      app.refreshAlerts();

      // Show Print Dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24),
                SizedBox(width: 8),
                Text('Sale Completed Successfully!'),
              ],
            ),
            content: Text('Invoice #${sale.invoiceNumber} recorded for ${AppFormatters.currency(sale.grandTotal)}. Choose receipt format:'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_rounded, size: 16),
                label: const Text('Thermal Receipt (80mm)'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await PrintService.printThermalReceipt(sale: sale, settings: app.settings);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Print A4 Invoice'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await PrintService.printSaleInvoice(sale: sale, settings: app.settings);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }
  }
}
