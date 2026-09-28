import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/interactive_scroll_view.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Desktop stability guard: Prevent login route from popping
      },
      child: Scaffold(
        backgroundColor: AppColors.sidebarBg,
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              return InteractiveBiDirectionalScrollView(
                minWidth: isSmall ? 0.0 : 460.0,
                minHeight: isSmall ? 0.0 : 580.0,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 16 : 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: EdgeInsets.all(isSmall ? 24 : 36),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App Logo & Header
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      AppStrings.logoSquareAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        padding: const EdgeInsets.all(16),
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Icon(Icons.apartment_rounded, size: 42, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Text(
                                  AppStrings.appName,
                                  style: AppStyles.h2.copyWith(fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  AppStrings.appTagline,
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error Banner
                              Obx(() {
                                if (controller.errorMessage.isEmpty) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          controller.errorMessage.value,
                                          style: AppStyles.bodySmall.copyWith(color: AppColors.danger),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // Username Field
                              CustomTextField(
                                label: 'Username',
                                hint: 'Enter your username',
                                controller: controller.usernameController,
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  if (controller.passwordController.text.trim().isNotEmpty) {
                                    controller.login();
                                  } else {
                                    FocusScope.of(context).nextFocus();
                                  }
                                },
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Password Field
                              Obx(() => CustomTextField(
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: controller.passwordController,
                                obscureText: !controller.isPasswordVisible.value,
                                prefixIcon: Icons.lock_outline,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => controller.login(),
                                suffix: IconButton(
                                  icon: Icon(
                                    controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: controller.togglePasswordVisibility,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter password';
                                  }
                                  return null;
                                },
                              )),
                              const SizedBox(height: 28),

                              // Login Button
                              Obx(() => CustomButton(
                                text: 'Sign In',
                                icon: Icons.login_rounded,
                                width: double.infinity,
                                height: 46,
                                isLoading: controller.isLoading.value,
                                onPressed: controller.login,
                              )),
                              // Offline notice & Software House Branding
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.code_rounded, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      AppStrings.developerBrandingShort,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
