import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'inventory_form_dialog.dart';
import 'stock_adjustment_dialog.dart';
import 'stock_history_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _inventoryRepo = InventoryRepository();
  final _settingsRepo = SettingsRepository();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _stockFilter = 'All'; // All, low, out
  double _lowStockThreshold = AppConstants.defaultLowStockThreshold;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  void _loadThreshold() async {
    final t = await _settingsRepo.getLowStockThreshold();
    if (mounted) setState(() => _lowStockThreshold = t);
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    return AppScaffold(
      currentRoute: AppRoutes.inventory,
      title: 'Stock Details',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (_) => const InventoryFormDialog(),
          );
          if (res == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Stock Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Inventory KPI Header (Section 15: Total, Low, Out-of-Stock, Purchase Value)
            FutureBuilder<Map<String, dynamic>>(
              future: _inventoryRepo.getInventoryDashboard(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {};
                final totalItems = data['total_items'] ?? 0;
                final lowStock = data['low_stock'] ?? 0;
                final outOfStock = data['out_of_stock'] ?? 0;
                final purchaseVal = (data['stock_purchase_value'] as num?)?.toDouble() ?? 0.0;

                return Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        title: 'Total Stock Items',
                        value: '$totalItems',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _kpiCard(
                        title: 'Low Stock Items',
                        value: '$lowStock',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        subtitle: 'Threshold: ≤ ${_lowStockThreshold.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _kpiCard(
                        title: 'Out-of-Stock Items',
                        value: '$outOfStock',
                        icon: Icons.remove_circle_outline_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _kpiCard(
                        title: 'Stock Purchase Value',
                        value: Formatters.currency(purchaseVal, symbol: currency),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. Filter Bar & Search
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by item name, brand, description, or notes...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _stockFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Stock Items')),
                        DropdownMenuItem(value: 'low', child: Text('Low Stock Only')),
                        DropdownMenuItem(value: 'out', child: Text('Out of Stock Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _stockFilter = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. SQLite Stock Items List
            Expanded(
              child: FutureBuilder<List<InventoryItemModel>>(
                future: _inventoryRepo.getItems(searchQuery: _searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(message: 'Loading stock details...');
                  }

                  final allItems = snapshot.data ?? [];
                  final filtered = allItems.where((item) {
                    bool matchesFilter = true;
                    if (_stockFilter == 'low') {
                      matchesFilter = item.currentQuantity > 0 && item.currentQuantity <= _lowStockThreshold;
                    } else if (_stockFilter == 'out') {
                      matchesFilter = item.currentQuantity <= 0;
                    }
                    return matchesFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.inventory_2_rounded,
                      title: 'No Stock Items Found',
                      description: 'Add your garage inventory items to track real-time stock levels, usage, and purchase prices.',
                      actionLabel: 'Add Stock Item',
                      onAction: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) => const InventoryFormDialog(),
                        );
                        if (res == true && mounted) setState(() {});
                      },
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isOut = item.currentQuantity <= 0;
                        final isLow = item.currentQuantity > 0 && item.currentQuantity <= _lowStockThreshold;

                        Color statusColor = AppColors.success;
                        String statusLabel = 'In Stock';
                        if (isOut) {
                          statusColor = AppColors.error;
                          statusLabel = 'Out of Stock';
                        } else if (isLow) {
                          statusColor = AppColors.warning;
                          statusLabel = 'Low Stock';
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.15),
                            child: Icon(Icons.inventory_2_outlined, color: statusColor, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (item.brand != null && item.brand!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(item.brand!, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Quantity: ${item.currentQuantity.toStringAsFixed(1)} ${item.unit} • Purchase Price: ${Formatters.currency(item.purchasePrice, symbol: currency)} • Purchased: ${Formatters.date(item.purchaseDate)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                              ),
                              if (item.description != null && item.description!.isNotEmpty)
                                Text('Desc: ${item.description}', style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text('Notes: ${item.notes}', style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // + Add Quantity
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.success, size: 22),
                                tooltip: '+ Increase Quantity',
                                onPressed: () async {
                                  final res = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => StockAdjustmentDialog(item: item, isAdding: true),
                                  );
                                  if (res == true && mounted) setState(() {});
                                },
                              ),
                              // - Remove Quantity
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 22),
                                tooltip: '- Decrease Quantity',
                                onPressed: () async {
                                  final res = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => StockAdjustmentDialog(item: item, isAdding: false),
                                  );
                                  if (res == true && mounted) setState(() {});
                                },
                              ),
                              // History
                              IconButton(
                                icon: const Icon(Icons.history_rounded, size: 20),
                                tooltip: 'Quantity History',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => StockHistoryDialog(item: item),
                                  );
                                },
                              ),
                              // Edit
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Item',
                                onPressed: () async {
                                  final res = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => InventoryFormDialog(item: item),
                                  );
                                  if (res == true && mounted) setState(() {});
                                },
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  final confirm = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: const Text('Delete Stock Item'),
                                      content: Text('Are you sure you want to delete "${item.name}" from inventory?'),
                                      actions: [
                                        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                          onPressed: () => Get.back(result: true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _inventoryRepo.deleteItem(item.id);
                                    Get.snackbar('Deleted', '${item.name} removed from inventory');
                                    if (mounted) setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary), maxLines: 1),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), maxLines: 1),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
