import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';

enum ButtonType { primary, secondary, outline, danger, success }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? customBgColor;
  final Color? customFgColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.width,
    this.height = 42,
    this.customBgColor,
    this.customFgColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.primary;
    Color fg = Colors.white;
    BorderSide border = BorderSide.none;

    switch (type) {
      case ButtonType.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case ButtonType.secondary:
        bg = AppColors.surfaceSecondary;
        fg = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.border);
        break;
      case ButtonType.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonType.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        break;
      case ButtonType.success:
        bg = AppColors.success;
        fg = Colors.white;
        break;
    }

    if (customBgColor != null) {
      bg = customBgColor!;
      fg = customFgColor ?? Colors.white;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width ?? (isLoading ? 140 : 0),
        minHeight: height,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: type == ButtonType.primary ? 1 : 0,
            side: border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Processing...',
                      style: AppStyles.button.copyWith(color: fg),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        style: AppStyles.button.copyWith(color: fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
