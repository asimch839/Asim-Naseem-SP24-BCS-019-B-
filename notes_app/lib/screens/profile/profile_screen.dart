import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'User';
  String _email = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  void _loadUser() {
    final user = context.read<AuthProvider>().currentUser;
    setState(() {
      _email = user?.email ?? '';
      _name = _email.isNotEmpty ? _email.split('@').first : 'User';
    });
  }

  Future<void> _logout() async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Sign Out?',
      message: 'You will be returned to the login screen.',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      icon: Icons.logout_rounded,
      confirmColor: AppColors.error,
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              isDark ? AppColors.darkBackground : Colors.white,
                          width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(_name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(_email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            // Menu sections
            _buildSection(context, 'Account', [
              _MenuItem(
                  Icons.person_outline_rounded,
                  'Edit Profile',
                  () => AppSnackbar.show(context, 'Coming soon!',
                      type: SnackbarType.info)),
              _MenuItem(Icons.notifications_outlined, 'Notifications',
                  () => Navigator.pushNamed(context, AppRoutes.reminders)),
              _MenuItem(Icons.category_rounded, 'Categories',
                  () => Navigator.pushNamed(context, AppRoutes.categories)),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Data', [
              _MenuItem(Icons.archive_outlined, 'Archive',
                  () => Navigator.pushNamed(context, AppRoutes.archive)),
              _MenuItem(Icons.delete_outline_rounded, 'Trash',
                  () => Navigator.pushNamed(context, AppRoutes.trash)),
              _MenuItem(Icons.calendar_month_rounded, 'Calendar',
                  () => Navigator.pushNamed(context, AppRoutes.calendar)),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'App', [
              _MenuItem(Icons.settings_rounded, 'Settings',
                  () => Navigator.pushNamed(context, AppRoutes.settings)),
              _MenuItem(
                  Icons.help_outline_rounded,
                  'Help & Support',
                  () => AppSnackbar.show(context, 'Coming soon!',
                      type: SnackbarType.info)),
              _MenuItem(
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  () => AppSnackbar.show(context, 'Coming soon!',
                      type: SnackbarType.info)),
              _MenuItem(Icons.info_outline_rounded,
                  'About ${AppConstants.appName}', () => _showAbout(context)),
            ]),
            const SizedBox(height: 16),
            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Sign Out',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 12),
            Text('${AppConstants.appName} v${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<_MenuItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading:
                        Icon(e.value.icon, size: 20, color: AppColors.primary),
                    title: Text(e.value.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: e.value.onTap,
                    dense: true,
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: 52,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese:
          '© 2025 ${AppConstants.appName}. All rights reserved.',
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.onTap);
}
