import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../data/database/app_database.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() {
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final searchHits = <Map<String, dynamic>>[];
    final param = '%$trimmed%';

    try {
      final db = await AppDatabase.instance.database;

      // 1. Search Customers
      final customers = await db.rawQuery('''
        SELECT id, name, phone, address FROM customers
        WHERE is_deleted = 0 AND (LOWER(name) LIKE ? OR phone LIKE ? OR LOWER(address) LIKE ?)
        LIMIT 5
      ''', [param, param, param]);

      for (var c in customers) {
        searchHits.add({
          'type': 'Customer',
          'title': c['name'] as String,
          'subtitle': 'Phone: ${c['phone']} ${c['address'] != null ? "• ${c['address']}" : ""}',
          'icon': Icons.person_rounded,
          'route': AppRoutes.customers,
          'id': c['id'],
        });
      }

      // 2. Search Vehicles
      final vehicles = await db.rawQuery('''
        SELECT id, vehicle_name, registration_number, model_year, color FROM vehicles
        WHERE is_deleted = 0 AND (LOWER(vehicle_name) LIKE ? OR LOWER(registration_number) LIKE ?)
        LIMIT 5
      ''', [param, param]);

      for (var v in vehicles) {
        searchHits.add({
          'type': 'Vehicle',
          'title': '${v['vehicle_name']} (${v['registration_number']})',
          'subtitle': 'Year: ${v['model_year']} • Color: ${v['color']}',
          'icon': Icons.directions_car_rounded,
          'route': AppRoutes.vehicles,
          'id': v['id'],
        });
      }

      // 3. Search Jobs
      final jobs = await db.rawQuery('''
        SELECT id, job_number, status, grand_total, receiving_date FROM jobs
        WHERE LOWER(job_number) LIKE ? OR LOWER(status) LIKE ?
        LIMIT 5
      ''', [param, param]);

      for (var j in jobs) {
        searchHits.add({
          'type': 'Job',
          'title': 'Job #${j['job_number']} (${j['status']})',
          'subtitle': 'Total: Rs. ${j['grand_total']} • Received: ${j['receiving_date']?.toString().split('T').first}',
          'icon': Icons.build_circle_rounded,
          'route': AppRoutes.dashboard,
          'id': j['id'],
        });
      }

      // 4. Search Invoices
      final invoices = await db.rawQuery('''
        SELECT id, invoice_number, grand_total, remaining_amount, status FROM invoices
        WHERE is_deleted = 0 AND (LOWER(invoice_number) LIKE ? OR LOWER(status) LIKE ?)
        LIMIT 5
      ''', [param, param]);

      for (var inv in invoices) {
        searchHits.add({
          'type': 'Invoice',
          'title': 'Invoice #${inv['invoice_number']} - ${inv['status']}',
          'subtitle': 'Total: Rs. ${inv['grand_total']} • Balance Due: Rs. ${inv['remaining_amount']}',
          'icon': Icons.receipt_long_rounded,
          'route': AppRoutes.invoices,
          'id': inv['id'],
        });
      }

      // 5. Search Inventory
      final items = await db.rawQuery('''
        SELECT id, item_name, brand, current_quantity, unit FROM inventory_items
        WHERE is_deleted = 0 AND (LOWER(item_name) LIKE ? OR LOWER(brand) LIKE ?)
        LIMIT 5
      ''', [param, param]);

      for (var it in items) {
        searchHits.add({
          'type': 'Inventory',
          'title': it['item_name'] as String,
          'subtitle': 'Brand: ${it['brand']} • Stock: ${it['current_quantity']} ${it['unit']}',
          'icon': Icons.inventory_2_rounded,
          'route': AppRoutes.inventory,
          'id': it['id'],
        });
      }

      // 6. Search Vendors
      final vendors = await db.rawQuery('''
        SELECT id, name, company, phone, category FROM vendors
        WHERE is_deleted = 0 AND (LOWER(name) LIKE ? OR LOWER(company) LIKE ? OR phone LIKE ?)
        LIMIT 5
      ''', [param, param, param]);

      for (var vn in vendors) {
        final comp = vn['company'] != null && (vn['company'] as String).isNotEmpty ? ' (${vn['company']})' : '';
        searchHits.add({
          'type': 'Vendor',
          'title': '${vn['name']}$comp',
          'subtitle': 'Category: ${vn['category']} • Phone: ${vn['phone']}',
          'icon': Icons.storefront_rounded,
          'route': AppRoutes.vendors,
          'id': vn['id'],
        });
      }
    } catch (e) {
      debugPrint('SQLite Global Search error: $e');
    }

    if (mounted) {
      setState(() {
        _results.clear();
        _results.addAll(searchHits);
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).cardTheme.color,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Input Header
              Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search Plate, Customer, Phone, Job #, Invoice #...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              const Divider(),

              // Search Results List
              Expanded(
                child: _queryController.text.trim().isEmpty
                    ? const Center(
                        child: Text(
                          'Type something to start cross-module search...',
                          style: TextStyle(color: AppColors.textDarkSecondary),
                        ),
                      )
                    : _results.isEmpty && !_isSearching
                        ? const Center(
                            child: Text(
                              'No matching records found across all modules.',
                              style: TextStyle(color: AppColors.textDarkSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                                ),
                                title: Text(
                                  item['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  item['subtitle'] as String,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkBorder,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                child: Text(item['type'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Get.toNamed(item['route'] as String);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
