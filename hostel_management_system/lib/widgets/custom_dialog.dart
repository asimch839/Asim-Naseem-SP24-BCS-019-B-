import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import 'custom_button.dart';

class CustomDialog {
  /// Show general purpose modal dialog
  static Future<T?> show<T>({
    required String title,
    required Widget content,
    List<Widget>? actions,
    double width = 520,
  }) {
    return Get.dialog<T>(
      Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 16,
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width,
                maxHeight: screenSize.height * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppStyles.h3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          onPressed: () {
                            if (Get.isDialogOpen == true) Get.back();
                          },
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.divider, height: 20),
                    Flexible(child: SingleChildScrollView(primary: false, child: content)),
                    if (actions != null && actions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: actions,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  /// Show confirmation dialog (e.g. for delete or critical action)
  static Future<bool> showConfirm({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    ButtonType confirmButtonType = ButtonType.danger,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await Get.dialog<bool>(
      Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: screenSize.height * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: confirmButtonType == ButtonType.danger ? AppColors.dangerBg : AppColors.warningBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: confirmButtonType == ButtonType.danger ? AppColors.danger : AppColors.warning,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: AppStyles.h3, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        CustomButton(
                          text: cancelText,
                          type: ButtonType.secondary,
                          onPressed: () {
                            if (Get.isDialogOpen == true) Get.back(result: false);
                          },
                        ),
                        CustomButton(
                          text: confirmText,
                          type: confirmButtonType,
                          onPressed: () {
                            if (Get.isDialogOpen == true) Get.back(result: true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    return result ?? false;
  }
}
