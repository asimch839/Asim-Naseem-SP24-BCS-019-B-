import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/vendor_model.dart';
import '../../data/repositories/vendor_repository.dart';
import '../expenses/garage_expense_screen.dart';
import 'vendor_form_dialog.dart';
import 'vendor_detail_dialog.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _vendorRepo = Get.find<VendorRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<VendorModel> _vendors = [];
  Map<String, double> _vendorSpends = {};
  Map<String, dynamic> _metrics = {};

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _vendorRepo.getVendorMetrics();
      final list = await _vendorRepo.getVendors(
        searchQuery: _searchQuery,
      );

      // Preload spend amounts for displayed vendors
      final spends = <String, double>{};
      for (final v in list) {
        final spend = await _vendorRepo.getVendorTotalSpend(v.name, company: v.company);
        spends[v.id] = spend;
      }

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _vendors = list;
          _vendorSpends = spends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openVendorForm([VendorModel? existing]) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => VendorFormDialog(existing: existing),
    );
    if (res == true) {
      _fetchData();
    }
  }

  void _openVendorDetail(VendorModel vendor) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => VendorDetailDialog(vendor: vendor),
    );
    if (res == true || res == null) {
      _fetchData();
    }
  }

  void _deleteVendor(VendorModel vendor) {
    Get.defaultDialog(
      title: 'Delete Vendor',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: 'Are you sure you want to delete ${vendor.name} (${vendor.company ?? "Vendor"})?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back();
        await _vendorRepo.deleteVendor(vendor.id);
        _fetchData();
        Get.snackbar(
          'Deleted',
          'Vendor removed',
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          colorText: AppColors.error,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      '$label copied to clipboard',
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      colorText: AppColors.primaryLight,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;
    final totalVendors = _metrics['total_vendors'] ?? _vendors.length;
    final totalSpend = (_metrics['total_spend'] as num?)?.toDouble() ?? 0.0;

    return AppScaffold(
      currentRoute: AppRoutes.vendors,
      currentSubItem: 'Vendors',
      title: 'Vendor Directory',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVendorForm(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Vendor'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          children: [
            // 1. Clean KPI Overview Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 550;
                final totalVendorsCard = _kpiCard(
                  title: 'Total Vendors',
                  value: '$totalVendors',
                  icon: Icons.storefront_rounded,
                  color: AppColors.primaryLight,
                );
                final totalSpendCard = _kpiCard(
                  title: 'Total Invoiced Spend',
                  value: Formatters.currency(totalSpend, symbol: currency),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.info,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      totalVendorsCard,
                      const SizedBox(height: 10),
                      totalSpendCard,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: totalVendorsCard),
                    const SizedBox(width: 16),
                    Expanded(child: totalSpendCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. Search & Action Bar
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: isMobile ? 'Search vendors...' : 'Search by Person Name, Shop Name, Phone, or Description...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: isMobile,
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _fetchData();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _fetchData,
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openVendorForm(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Vendor'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Vendors List
            Expanded(
              child: _isLoading
                  ? const AppLoadingIndicator(message: 'Loading vendors...')
                  : _vendors.isEmpty
                      ? AppEmptyState(
                          icon: Icons.storefront_rounded,
                          title: 'No Vendors Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No vendor matched your search criteria.'
                              : 'Register shop vendors with Person Name, Shop Name, and Phone.',
                          actionLabel: 'Add First Vendor',
                          onAction: () => _openVendorForm(),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _vendors.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final vendor = _vendors[index];
                              final spend = _vendorSpends[vendor.id] ?? 0.0;

                              if (isMobile) {
                                return InkWell(
                                  onTap: () => _openVendorDetail(vendor),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                              child: Text(
                                                vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    vendor.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (vendor.company != null && vendor.company!.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      vendor.company!,
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                                              onSelected: (val) async {
                                                if (val == 'expense') {
                                                  final res = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => GarageExpenseFormDialog(
                                                      prefillVendorName: vendor.name,
                                                      prefillVendorCompany: vendor.company,
                                                      prefillVendorPhone: vendor.phone,
                                                    ),
                                                  );
                                                  if (res == true) _fetchData();
                                                } else if (val == 'edit') {
                                                  _openVendorForm(vendor);
                                                } else if (val == 'delete') {
                                                  _deleteVendor(vendor);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'expense',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.add_shopping_cart_rounded, size: 18, color: AppColors.primaryLight),
                                                      SizedBox(width: 8),
                                                      Text('Log Expense'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_rounded, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                                      SizedBox(width: 8),
                                                      Text('Delete', style: TextStyle(color: AppColors.error)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: () => _copyToClipboard(vendor.phone, 'Phone number'),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.phone_rounded, size: 13, color: AppColors.textDarkMuted),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    vendor.phone,
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.copy_rounded, size: 11, color: AppColors.textDarkMuted),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('Spend: ', style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                                                Text(
                                                  Formatters.currency(spend, symbol: currency),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.info),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (vendor.notes != null && vendor.notes!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            vendor.notes!.trim(),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return InkWell(
                                onTap: () => _openVendorDetail(vendor),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Vendor Avatar
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                        child: Text(
                                          vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryLight),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Vendor Details (Person Name, Shop Name, Phone, Description)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Person Name & Shop Name
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    vendor.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (vendor.company != null && vendor.company!.isNotEmpty) ...[
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.storefront_rounded, size: 13, color: AppColors.primaryLight),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          vendor.company!,
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Phone Number
                                            InkWell(
                                              onTap: () => _copyToClipboard(vendor.phone, 'Phone number'),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.phone_rounded, size: 14, color: AppColors.textDarkMuted),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    vendor.phone,
                                                    style: const TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.copy_rounded, size: 12, color: AppColors.textDarkMuted),
                                                ],
                                              ),
                                            ),

                                            // Description (if present)
                                            if (vendor.notes != null && vendor.notes!.trim().isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.description_outlined, size: 13, color: AppColors.textDarkMuted),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      vendor.notes!.trim(),
                                                      style: const TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Total Spend
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Total Spend', style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            Formatters.currency(spend, symbol: currency),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.info),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),

                                      // Action Buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 19),
                                            tooltip: 'Log Expense for this Vendor',
                                            color: AppColors.primaryLight,
                                            onPressed: () async {
                                              final res = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => GarageExpenseFormDialog(
                                                  prefillVendorName: vendor.name,
                                                  prefillVendorCompany: vendor.company,
                                                  prefillVendorPhone: vendor.phone,
                                                ),
                                              );
                                              if (res == true) _fetchData();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, size: 19),
                                            tooltip: 'Edit Vendor',
                                            onPressed: () => _openVendorForm(vendor),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 19),
                                            tooltip: 'Delete Vendor',
                                            color: AppColors.error,
                                            onPressed: () => _deleteVendor(vendor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 22,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
