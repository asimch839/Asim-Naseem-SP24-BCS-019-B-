import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/app_theme.dart';

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
                    Text('Configure shop identity, invoice templates, repair numbering, and keyboard shortcuts', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
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
                    const Row(
                      children: [
                        Icon(Icons.security_rounded, color: AppTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('ADMIN LOGIN CREDENTIALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _adminUsernameCtrl, decoration: const InputDecoration(labelText: 'Admin Username'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _adminPasswordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Admin Password'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Appearance & Keyboard Shortcuts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.keyboard_rounded, color: AppTheme.primaryBlue, size: 20),
                              SizedBox(width: 8),
                              Text('WINDOWS KEYBOARD SHORTCUTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 20),
                          _shortcutItem('F1', 'New Sale / Open POS Screen'),
                          _shortcutItem('F2 or Ctrl+F', 'Universal Multi-Entity Search (IMEI, Customer, Job)'),
                          _shortcutItem('F3', 'Quick Add New Customer Modal'),
                          _shortcutItem('F4', 'New Mobile Repair Job Modal'),
                          _shortcutItem('F5', 'Refresh & Reload Entire Database'),
                          _shortcutItem('F6', 'Receive Customer Due Payment Modal'),
                          _shortcutItem('Esc', 'Close any Active Dialog or Modal'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shortcutItem(String keyName, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFCBD5E1))),
            child: Text(keyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.darkNavy)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _saveSettings(BuildContext context, AppProvider app) async {
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
      adminUsername: _adminUsernameCtrl.text.trim(),
      adminPassword: _adminPasswordCtrl.text.trim(),
      isDarkMode: _isDark,
      autoBackupEnabled: _autoBackup,
    );

    await app.updateSettings(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop branding and system settings saved successfully!')),
      );
    }
  }
}
