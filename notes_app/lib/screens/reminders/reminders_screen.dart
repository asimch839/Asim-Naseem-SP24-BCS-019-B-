import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/helpers/date_helper.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/common/empty_state_widget.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders 🔔'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ReminderProvider>(
        builder: (_, prov, __) {
          if (prov.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.reminders.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'No Reminders',
              subtitle: 'Set reminders on notes to see them here',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: prov.reminders.length,
            itemBuilder: (_, i) =>
                _ReminderCard(reminder: prov.reminders[i], isDark: isDark),
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool isDark;

  const _ReminderCard({required this.reminder, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = reminder.dateTime.isAfter(DateTime.now());
    final color = isUpcoming ? AppColors.primary : AppColors.lightTextHint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUpcoming
              ? color.withOpacity(0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUpcoming ? Icons.alarm_rounded : Icons.alarm_off_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note ID: ${reminder.noteId.substring(0, 8)}...',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  DateHelper.formatDateTime(reminder.dateTime),
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isUpcoming ? 'Upcoming' : 'Past',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
