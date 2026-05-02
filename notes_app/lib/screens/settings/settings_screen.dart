import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_snackbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings ⚙️'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Theme
          const _SectionHeader(title: 'Appearance'),
          _buildThemeCard(context, isDark),
          const SizedBox(height: 16),

          // Data
          const _SectionHeader(title: 'Data Management'),
          _buildCard(context, isDark, [
            _SettingItem(
              icon: Icons.backup_rounded,
              iconColor: AppColors.primary,
              title: 'Backup Notes',
              subtitle: 'Save notes to device storage',
              onTap: () => AppSnackbar.show(context, 'Backup coming soon!',
                  type: SnackbarType.info),
            ),
            _SettingItem(
              icon: Icons.restore_rounded,
              iconColor: AppColors.accent,
              title: 'Restore Notes',
              subtitle: 'Restore from backup',
              onTap: () => AppSnackbar.show(context, 'Restore coming soon!',
                  type: SnackbarType.info),
            ),
            _SettingItem(
              icon: Icons.upload_file_rounded,
              iconColor: AppColors.success,
              title: 'Export Notes',
              subtitle: 'Export as JSON or PDF',
              onTap: () => AppSnackbar.show(context, 'Export coming soon!',
                  type: SnackbarType.info),
            ),
            _SettingItem(
              icon: Icons.download_rounded,
              iconColor: AppColors.warning,
              title: 'Import Notes',
              subtitle: 'Import from file',
              onTap: () => AppSnackbar.show(context, 'Import coming soon!',
                  type: SnackbarType.info),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Notifications
          const _SectionHeader(title: 'Notifications'),
          _buildCard(context, isDark, [
            _SettingItem(
              icon: Icons.notifications_rounded,
              iconColor: AppColors.secondary,
              title: 'Reminder Notifications',
              subtitle: 'Enable note reminders',
              onTap: () => AppSnackbar.show(
                  context, 'Configure notifications in system settings',
                  type: SnackbarType.info),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Security
          const _SectionHeader(title: 'Security'),
          _buildCard(context, isDark, [
            _SettingItem(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.error,
              title: 'App Lock',
              subtitle: 'Use PIN or biometric to lock app',
              onTap: () => AppSnackbar.show(context, 'App lock coming soon!',
                  type: SnackbarType.info),
            ),
            _SettingItem(
              icon: Icons.language_rounded,
              iconColor: AppColors.primary,
              title: 'Language',
              subtitle: 'English (Default)',
              onTap: () => AppSnackbar.show(
                  context, 'Language settings coming soon!',
                  type: SnackbarType.info),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (_, prov, __) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.palette_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Theme Mode',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ThemeOption(
                    label: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    selected: prov.themeMode == ThemeMode.light,
                    onTap: () => prov.setTheme(ThemeMode.light),
                  ),
                  const SizedBox(width: 10),
                  _ThemeOption(
                    label: 'Dark',
                    icon: Icons.nightlight_round,
                    selected: prov.themeMode == ThemeMode.dark,
                    onTap: () => prov.setTheme(ThemeMode.dark),
                  ),
                  const SizedBox(width: 10),
                  _ThemeOption(
                    label: 'System',
                    icon: Icons.settings_suggest_rounded,
                    selected: prov.themeMode == ThemeMode.system,
                    onTap: () => prov.setTheme(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
      BuildContext context, bool isDark, List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: items.map((item) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 18),
                ),
                title: Text(item.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle:
                    Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: item.onTap,
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              if (!item.isLast)
                Divider(
                    height: 1,
                    indent: 60,
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20, color: selected ? Colors.white : AppColors.primary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });
}
