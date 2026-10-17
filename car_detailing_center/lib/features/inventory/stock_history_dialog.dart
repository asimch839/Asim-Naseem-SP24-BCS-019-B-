import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(child: Text('Quantity Change History: ${item.name}', maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 480,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: inventoryRepo.getStockTransactions(item.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingIndicator(message: 'Loading stock history...');
            }

            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return const AppEmptyState(
                icon: Icons.history_toggle_off_rounded,
                title: 'No History Recorded',
                description: 'Quantity changes, additions, and service consumptions will appear here.',
              );
            }

            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = list[index];
                final change = (tx['quantity_change'] as num?)?.toDouble() ?? 0.0;
                final isPositive = change >= 0;
                final prevQty = (tx['previous_quantity'] as num?)?.toDouble() ?? 0.0;
                final newQty = (tx['new_quantity'] as num?)?.toDouble() ?? 0.0;
                final txType = tx['transaction_type'] as String? ?? 'Adjustment';
                final reason = tx['reason_notes'] as String? ?? '';
                final userName = tx['user_name'] as String? ?? 'Admin';
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
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (reason.isNotEmpty) Text('Reason: $reason', style: const TextStyle(fontSize: 13)),
                      if (vendorRef != null && vendorRef.isNotEmpty)
                        Text('Vendor Ref: $vendorRef', style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                      Text(
                        '${Formatters.dateTime(dateTime)} • Logged by: $userName',
                        style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Close')),
      ],
    );
  }
}
