import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBgColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 200 || MediaQuery.of(context).size.width < 768;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 10 : 16),
            decoration: AppStyles.cardDecoration,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: iconBgColor ?? iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: isMobile ? 18 : 22),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 10.5 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 1 : 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppStyles.h2.copyWith(
                            fontSize: isMobile ? 15 : 19,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: isMobile ? 1 : 2),
                        Text(
                          subtitle!,
                          style: AppStyles.caption.copyWith(
                            fontSize: isMobile ? 9.5 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        );
      },
    );
  }
}
