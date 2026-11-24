import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class StockHistoryDialog extends StatelessWidget {
  final InventoryItemModel item;
  const StockHistoryDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final inventoryRepo = InventoryRepository();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceDark,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Transaction History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDarkMuted),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: inventoryRepo.getStockTransactions(item.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppLoadingIndicator(message: 'Loading stock history...'),
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppEmptyState(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'No History Recorded',
                        description: 'Quantity changes, additions, and service consumptions will appear here.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderDark),
                    itemBuilder: (context, index) {
                      final tx = list[index];
                      final change = (tx['quantity_change'] as num?)?.toDouble() ?? 0.0;
                      final isPositive = change >= 0;
                      final prevQty = (tx['previous_quantity'] as num?)?.toDouble() ?? 0.0;
                      final newQty = (tx['new_quantity'] as num?)?.toDouble() ?? 0.0;
                      final txType = tx['transaction_type'] as String? ?? 'Adjustment';
                      final reason = tx['reason_notes'] as String? ?? '';
                      final userName = tx['user_name'] as String? ?? 'Admin';
                      final jobId = tx['job_id'] as String? ?? '';
                      final vendorRef = tx['vendor_reference'] as String?;
                      final dateTime = DateTime.tryParse(tx['date_time']?.toString() ?? '') ?? DateTime.now();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                          child: Icon(
                            isPositive ? Icons.add_rounded : Icons.remove_rounded,
                            color: isPositive ? AppColors.success : AppColors.error,
                            size: 20,
                          ),
                        ),
                        title: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            Text(
                              '${isPositive ? "+" : ""}${change.toStringAsFixed(1)} ${item.unit} ($txType)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive ? AppColors.success : AppColors.error,
                              ),
                            ),
                            Text(
                              'New: ${newQty.toStringAsFixed(1)} (Prev: ${prevQty.toStringAsFixed(1)})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isPositive && jobId.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, bottom: 2),
                                child: Text('🚗 Vehicle / Job: $jobId', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
                              ),
                            if (reason.isNotEmpty) Text('Purpose / Notes: $reason', style: const TextStyle(fontSize: 12, color: AppColors.textDarkPrimary)),
                            if (vendorRef != null && vendorRef.isNotEmpty)
                              Text('Vendor Ref: $vendorRef', style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${Formatters.dateTime(dateTime)} • ${isPositive ? "Logged by" : "Taken by Staff"}: $userName',
                                style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
}
