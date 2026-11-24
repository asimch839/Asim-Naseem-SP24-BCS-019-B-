import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/staff_repository.dart';
import 'stock_adjustment_dialog.dart';

class StaffUsageLogDialog extends StatefulWidget {
  const StaffUsageLogDialog({super.key});

  @override
  State<StaffUsageLogDialog> createState() => _StaffUsageLogDialogState();
}

class _StaffUsageLogDialogState extends State<StaffUsageLogDialog> {
  final _inventoryRepo = InventoryRepository();
  final _staffRepo = StaffRepository();
  final TextEditingController _searchController = TextEditingController();

  List<StaffModel> _staffList = [];
  String _selectedStaffFilter = 'All Staff';
  String _dateFilter = 'All Time'; // All Time, Today, This Week, This Month

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      final staff = await _staffRepo.getStaffList();
      _staffList = staff;

      String? startDate;
      String? endDate;
      final now = DateTime.now();

      if (_dateFilter == 'Today') {
        startDate = DateTime(now.year, now.month, now.day).toIso8601String();
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      } else if (_dateFilter == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String();
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      } else if (_dateFilter == 'This Month') {
        startDate = DateTime(now.year, now.month, 1).toIso8601String();
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      }

      final list = await _inventoryRepo.getStaffUsageTransactions(
        staffName: _selectedStaffFilter != 'All Staff' ? _selectedStaffFilter : null,
        searchQuery: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _transactions = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openIssueStockDialog() async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StockAdjustmentDialog(isAdding: false),
    );
    if (res == true && mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = AuthService.to.currentBusiness.value?.currency ?? AppConstants.defaultCurrency;

    // Calculate quick metrics
    final totalIssuances = _transactions.length;
    double totalUnits = 0.0;
    double totalEstimatedCost = 0.0;
    final staffNames = <String>{};

    for (final tx in _transactions) {
      final change = (tx['quantity_change'] as num?)?.toDouble() ?? 0.0;
      final absQty = change.abs();
      totalUnits += absQty;
      final pPrice = (tx['purchase_price'] as num?)?.toDouble() ?? 0.0;
      totalEstimatedCost += (absQty * pPrice);
      final staffName = tx['user_name']?.toString() ?? '';
      if (staffName.isNotEmpty && staffName != 'Admin' && staffName != 'Manager') {
        staffNames.add(staffName);
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Staff Material Consumption & Issuance Log',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Daily record of chemicals, shampoo, microfibers taken by staff for detailing jobs',
                          style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openIssueStockDialog,
                    icon: const Icon(Icons.outbox_rounded, size: 16),
                    label: const Text('Issue Material to Staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDarkMuted),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 2. Summary KPI Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.backgroundDark,
              child: Row(
                children: [
                  _summaryKpi(
                    title: 'Total Issuances',
                    value: '$totalIssuances',
                    icon: Icons.checklist_rtl_rounded,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 12),
                  _summaryKpi(
                    title: 'Total Quantity Consumed',
                    value: totalUnits.toStringAsFixed(1),
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  _summaryKpi(
                    title: 'Active Staff Involved',
                    value: '${staffNames.length}',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 12),
                  _summaryKpi(
                    title: 'Estimated Material Cost',
                    value: Formatters.currency(totalEstimatedCost, symbol: currency),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),

            // 3. Search & Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search staff name, car reg #, item name...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadData();
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (_) => _loadData(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Staff Filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedStaffFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        prefixIcon: Icon(Icons.filter_alt_rounded, size: 16),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'All Staff', child: Text('All Staff Members')),
                        ..._staffList.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                        const DropdownMenuItem(value: 'Shop Lead', child: Text('Shop Lead')),
                        const DropdownMenuItem(value: 'General Staff', child: Text('General Staff')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStaffFilter = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Quick Date Chips
                  Wrap(
                    spacing: 6,
                    children: ['All Time', 'Today', 'This Week', 'This Month'].map((period) {
                      final isSelected = _dateFilter == period;
                      return ChoiceChip(
                        label: Text(period, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textDarkSecondary)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _dateFilter = period);
                            _loadData();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh Log',
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),

            // 4. Content List
            Expanded(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppLoadingIndicator(message: 'Loading material usage records...'),
                    )
                  : _transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: AppEmptyState(
                            icon: Icons.assignment_turned_in_outlined,
                            title: 'No Material Issuances Found',
                            description: 'No staff usage records match your current filters. Click "+ Issue Material to Staff" to record materials used on detailing cars.',
                            actionLabel: '+ Issue Material Now',
                            onAction: _openIssueStockDialog,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            final change = (tx['quantity_change'] as num?)?.toDouble() ?? 0.0;
                            final absChange = change.abs();
                            final prevQty = (tx['previous_quantity'] as num?)?.toDouble() ?? 0.0;
                            final newQty = (tx['new_quantity'] as num?)?.toDouble() ?? 0.0;
                            final itemName = tx['item_name']?.toString() ?? 'Stock Item';
                            final unit = tx['unit']?.toString() ?? 'unit';
                            final staffName = tx['user_name']?.toString() ?? 'Staff Member';
                            final jobInfo = tx['job_id']?.toString() ?? '';
                            final reason = tx['reason_notes']?.toString() ?? '';
                            final dtStr = tx['date_time']?.toString() ?? '';
                            final dateTime = DateTime.tryParse(dtStr) ?? DateTime.now();
                            final pPrice = (tx['purchase_price'] as num?)?.toDouble() ?? 0.0;
                            final costVal = absChange * pPrice;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Date, Badge, and Stock Deduction
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textDarkMuted),
                                          const SizedBox(width: 5),
                                          Text(
                                            DateFormat('dd MMM yyyy • hh:mm a').format(dateTime),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.warning.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Staff Issuance',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '-${absChange.toStringAsFixed(1)} $unit (Stock: ${prevQty.toStringAsFixed(1)} → ${newQty.toStringAsFixed(1)})',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18, color: AppColors.borderDark),

                                  // Main Row: Staff Member, Item Taken, Car / Job
                                  Row(
                                    children: [
                                      // Staff
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                              child: const Icon(Icons.person_rounded, size: 18, color: AppColors.primaryLight),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Staff Member (Taken By):', style: TextStyle(fontSize: 10, color: AppColors.textDarkMuted)),
                                                  Text(
                                                    staffName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Item
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                                              child: const Icon(Icons.cleaning_services_rounded, size: 18, color: AppColors.warning),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Item Consumed:', style: TextStyle(fontSize: 10, color: AppColors.textDarkMuted)),
                                                  Text(
                                                    '$itemName (${absChange.toStringAsFixed(1)} $unit)',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Car / Job
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppColors.info.withValues(alpha: 0.2),
                                              child: const Icon(Icons.directions_car_filled_rounded, size: 18, color: AppColors.info),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Used On Car / Job:', style: TextStyle(fontSize: 10, color: AppColors.textDarkMuted)),
                                                  Text(
                                                    jobInfo.isNotEmpty ? jobInfo : 'General Workshop',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Estimated Cost (if > 0)
                                      if (costVal > 0)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Estimated Cost:', style: TextStyle(fontSize: 10, color: AppColors.textDarkMuted)),
                                            Text(
                                              Formatters.currency(costVal, symbol: currency),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDarkSecondary),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),

                                  // Purpose / Notes
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceDark,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.notes_rounded, size: 14, color: AppColors.textDarkSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Purpose / Notes: $reason',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // 5. Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${totalIssuances} records • Total ${totalUnits.toStringAsFixed(1)} consumable units consumed',
                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryKpi({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary), overflow: TextOverflow.ellipsis),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

