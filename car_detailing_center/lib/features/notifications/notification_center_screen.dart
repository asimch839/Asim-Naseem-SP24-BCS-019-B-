import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import 'notification_controller.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationController.to;

    return AppScaffold(
      currentRoute: AppRoutes.notifications,
      title: 'Local Reminders & Alerts Center',
      actions: [
        IconButton(
          onPressed: () => controller.refreshReminders(),
          icon: const Icon(Icons.sync_rounded),
          tooltip: 'Refresh Reminders from SQLite',
        ),
        TextButton.icon(
          onPressed: () => controller.markAllAsRead(),
          icon: const Icon(Icons.done_all_rounded, size: 18),
          label: const Text('Mark All Read'),
        ),
        const SizedBox(width: 16),
      ],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const AppLoadingIndicator(message: 'Scanning local reminder triggers...');
          }

          final list = controller.notifications;

          if (list.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Pending Reminders',
              description: 'You are all caught up! Local system reminders for vehicle delivery due dates, low stock, unpaid invoices, and payroll due will appear here.',
            );
          }

          return Card(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = list[index];
                final id = n['id'] as String;
                final title = n['title'] as String? ?? 'Reminder';
                final message = n['message'] as String? ?? '';
                final type = n['type'] as String? ?? 'System';
                final isRead = (n['is_read'] as int? ?? 0) == 1;
                final route = n['target_route'] as String?;
                final createdAt = DateTime.tryParse(n['created_at']?.toString() ?? '') ?? DateTime.now();

                final color = _getNotificationColor(type);
                final icon = _getNotificationIcon(type);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  tileColor: isRead ? null : AppColors.primary.withValues(alpha: 0.05),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$message • ${Formatters.dateTime(createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined, size: 20),
                    tooltip: isRead ? 'Read' : 'Mark as Read',
                    onPressed: () => controller.markAsRead(id),
                  ),
                  onTap: () {
                    controller.markAsRead(id);
                    if (route != null && route.isNotEmpty) {
                      Get.toNamed(route);
                    }
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'low stock':
      case 'out of stock':
        return AppColors.warning;
      case 'delivery due':
        return AppColors.accent;
      case 'salary due':
        return AppColors.info;
      case 'payment overdue':
      case 'payment reminder':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'low stock':
      case 'out of stock':
        return Icons.inventory_2_rounded;
      case 'delivery due':
        return Icons.car_rental_rounded;
      case 'salary due':
        return Icons.payments_rounded;
      case 'payment overdue':
      case 'payment reminder':
        return Icons.pending_actions_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
