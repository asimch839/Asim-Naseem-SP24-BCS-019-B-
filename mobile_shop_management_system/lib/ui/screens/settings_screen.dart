import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/sample_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _shopNameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _altPhoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _ntnCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _invPrefixCtrl;
  late TextEditingController _repPrefixCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _termsCtrl;
  late TextEditingController _adminUsernameCtrl;
  late TextEditingController _adminPasswordCtrl;

  String _receiptFormat = 'a4';
  bool _isDark = false;
  bool _autoBackup = true;
  bool _initialized = false;
  bool _obscureAdminPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = context.read<AppProvider>().settings;
      _shopNameCtrl = TextEditingController(text: s.shopName);
      _taglineCtrl = TextEditingController(text: s.tagline);
      _addressCtrl = TextEditingController(text: s.address);
      _phoneCtrl = TextEditingController(text: s.phone);
      _altPhoneCtrl = TextEditingController(text: s.altPhone);
      _emailCtrl = TextEditingController(text: s.email);
      _ntnCtrl = TextEditingController(text: s.ntn);
      _currencyCtrl = TextEditingController(text: s.currency);
      _invPrefixCtrl = TextEditingController(text: s.invoicePrefix);
      _repPrefixCtrl = TextEditingController(text: s.repairPrefix);
      _footerCtrl = TextEditingController(text: s.invoiceFooter);
      _termsCtrl = TextEditingController(text: s.termsAndConditions);
      _adminUsernameCtrl = TextEditingController(text: s.adminUsername);
      _adminPasswordCtrl = TextEditingController(text: s.adminPassword);
      _receiptFormat = s.receiptFormat;
      _isDark = s.isDarkMode;
      _autoBackup = s.autoBackupEnabled;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _emailCtrl.dispose();
    _ntnCtrl.dispose();
    _currencyCtrl.dispose();
    _invPrefixCtrl.dispose();
    _repPrefixCtrl.dispose();
    _footerCtrl.dispose();
    _termsCtrl.dispose();
    _adminUsernameCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Business Branding & System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Configure shop identity, invoice templates, repair numbering, and system preferences', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save Settings'),
                  onPressed: () => _saveSettings(context, app),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Business Branding Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: AppTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('SHOP IDENTITY & CONTACT INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop / Business Name *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _taglineCtrl, decoration: const InputDecoration(labelText: 'Tagline / Slogan'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Shop Address (Printed on Invoices & Job Cards) *')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Primary Phone / WhatsApp *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _altPhoneCtrl, decoration: const InputDecoration(labelText: 'Landline / Alternate Phone'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Official Email Address'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _ntnCtrl, decoration: const InputDecoration(labelText: 'NTN / Tax Registration Number'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. Rs. / PKR)'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Invoice & Repair Templates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_rounded, color: AppTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('INVOICING, REPAIR PREFIX & RECEIPT FORMATS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _invPrefixCtrl, decoration: const InputDecoration(labelText: 'Sale Invoice Prefix (e.g. INV-)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _repPrefixCtrl, decoration: const InputDecoration(labelText: 'Repair Job ID Prefix (e.g. REP-)'))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _receiptFormat,
                            decoration: const InputDecoration(labelText: 'Default Receipt Template'),
                            items: const [
                              DropdownMenuItem(value: 'a4', child: Text('A4 Professional Tax Invoice')),
                              DropdownMenuItem(value: 'thermal80', child: Text('Thermal 80mm POS Receipt')),
                              DropdownMenuItem(value: 'thermal58', child: Text('Thermal 58mm POS Receipt')),
                            ],
                            onChanged: (v) => setState(() => _receiptFormat = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _footerCtrl, decoration: const InputDecoration(labelText: 'Invoice Footer Note (Thank you message)')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _termsCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Terms & Conditions (Printed on Invoices & Repair Job Cards)'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Admin Credentials Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security_rounded, color: AppTheme.primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text('ADMIN LOGIN CREDENTIALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.lock_reset_rounded, size: 16),
                          label: const Text('Update Credentials'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _updateCredentialsOnly(context, app),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _adminUsernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Admin Username *',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              hintText: 'Enter login username',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _adminPasswordCtrl,
                            obscureText: _obscureAdminPassword,
                            decoration: InputDecoration(
                              labelText: 'Admin Password *',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              hintText: 'Enter login password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscureAdminPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                tooltip: _obscureAdminPassword ? 'Show password' : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscureAdminPassword = !_obscureAdminPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These credentials are used to sign in to the software. You can change and update them at any time.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Appearance & System Preferences Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_rounded, color: AppTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('APPEARANCE & BACKUP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    SwitchListTile(
                      title: const Text('Dark Mode Theme'),
                      subtitle: const Text('Switch between modern dark slate and crisp daylight themes'),
                      value: _isDark,
                      onChanged: (v) {
                        setState(() => _isDark = v);
                        app.toggleDarkMode();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Automated Local Backup'),
                      subtitle: const Text('Creates safety backup snapshot before restore or database updates'),
                      value: _autoBackup,
                      onChanged: (v) => setState(() => _autoBackup = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCredentialsOnly(BuildContext context, AppProvider app) async {
    final username = _adminUsernameCtrl.text.trim();
    final password = _adminPasswordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin username and password cannot be empty!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updated = app.settings.copyWith(
      adminUsername: username,
      adminPassword: password,
    );

    await app.updateSettings(updated);

    try {
      final db = DatabaseHelper.instance;
      final users = await db.getAllUsers();
      final adminUser = users.firstWhere(
        (u) => u.role == UserRole.owner || u.role == UserRole.admin || u.username == app.settings.adminUsername,
        orElse: () => users.isNotEmpty ? users.first : SampleData.users.first,
      );
      final updatedAdminUser = AppUser(
        id: adminUser.id,
        name: adminUser.name,
        username: username,
        phone: adminUser.phone,
        role: adminUser.role,
        isActive: adminUser.isActive,
        createdAt: adminUser.createdAt,
      );
      await db.insertUser(updatedAdminUser);
      if (app.currentUser.id == adminUser.id) {
        app.switchUser(updatedAdminUser);
      }
    } catch (e) {
      debugPrint('Error syncing admin user: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin credentials updated successfully! You can now use these to sign in.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  Future<void> _saveSettings(BuildContext context, AppProvider app) async {
    final username = _adminUsernameCtrl.text.trim();
    final password = _adminPasswordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin username and password cannot be empty!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updated = app.settings.copyWith(
      shopName: _shopNameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      altPhone: _altPhoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      ntn: _ntnCtrl.text.trim(),
      currency: _currencyCtrl.text.trim(),
      invoicePrefix: _invPrefixCtrl.text.trim(),
      repairPrefix: _repPrefixCtrl.text.trim(),
      receiptFormat: _receiptFormat,
      invoiceFooter: _footerCtrl.text.trim(),
      termsAndConditions: _termsCtrl.text.trim(),
      adminUsername: username,
      adminPassword: password,
      isDarkMode: _isDark,
      autoBackupEnabled: _autoBackup,
    );

    await app.updateSettings(updated);

    try {
      final db = DatabaseHelper.instance;
      final users = await db.getAllUsers();
      final adminUser = users.firstWhere(
        (u) => u.role == UserRole.owner || u.role == UserRole.admin || u.username == app.settings.adminUsername,
        orElse: () => users.isNotEmpty ? users.first : SampleData.users.first,
      );
      final updatedAdminUser = AppUser(
        id: adminUser.id,
        name: adminUser.name,
        username: username,
        phone: adminUser.phone,
        role: adminUser.role,
        isActive: adminUser.isActive,
        createdAt: adminUser.createdAt,
      );
      await db.insertUser(updatedAdminUser);
      if (app.currentUser.id == adminUser.id) {
        app.switchUser(updatedAdminUser);
      }
    } catch (e) {
      debugPrint('Error syncing admin user: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop branding and system settings saved successfully!')),
      );
    }
  }
}
