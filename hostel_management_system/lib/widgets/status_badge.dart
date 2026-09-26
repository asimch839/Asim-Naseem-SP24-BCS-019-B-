import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceSecondary;
    Color fg = AppColors.textSecondary;
    Color border = AppColors.border;

    switch (status.toLowerCase()) {
      case 'active':
      case 'available':
      case 'paid':
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = AppColors.success.withValues(alpha: 0.3);
        break;
      case 'partial':
      case 'pending':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        border = AppColors.warning.withValues(alpha: 0.3);
        break;
      case 'left':
      case 'full':
      case 'overdue':
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        border = AppColors.danger.withValues(alpha: 0.3);
        break;
      case 'maintenance':
      case 'occupied':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        border = AppColors.info.withValues(alpha: 0.3);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: AppStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
