import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool compact;

  const PriorityBadge(
      {super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = _color(priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            priority,
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _color(String p) {
    switch (p) {
      case AppConstants.priorityUrgent:
        return AppColors.priorityUrgent;
      case AppConstants.priorityHigh:
        return AppColors.priorityHigh;
      case AppConstants.priorityMedium:
        return AppColors.priorityMedium;
      default:
        return AppColors.priorityLow;
    }
  }
}
