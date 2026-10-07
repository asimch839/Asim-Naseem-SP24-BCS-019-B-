class BusinessSettings {
  final String shopName;
  final String tagline;
  final String address;
  final String phone;
  final String altPhone;
  final String email;
  final String ntn;
  final String currency;
  final String invoicePrefix;
  final String repairPrefix;
  final String purchasePrefix;
  final String receiptPrefix;
  final String invoiceFooter;
  final String termsAndConditions;
  final String receiptFormat; // 'thermal80', 'thermal58', 'a4'
  final bool isDarkMode;
  final bool autoBackupEnabled;
  final int defaultWarrantyDays;
  final String adminUsername;
  final String adminPassword;

  BusinessSettings({
    this.shopName = 'Al-Madina Mobile & Repairing Lab',
    this.tagline = 'Smartphones, Original Accessories & Expert Chip-Level Repair Lab',
    this.address = 'Shop #42, 1st Floor, Hafeez Centre, Main Boulevard, Gulberg III, Lahore',
    this.phone = '0300-1234567',
    this.altPhone = '042-35876543',
    this.email = 'info@almadinamobile.pk',
    this.ntn = '7891234-8',
    this.currency = 'Rs.',
    this.invoicePrefix = 'INV-',
    this.repairPrefix = 'REP-',
    this.purchasePrefix = 'PUR-',
    this.receiptPrefix = 'REC-',
    this.invoiceFooter = 'Thank you for choosing us! Please check goods and test warranty before leaving.',
    this.termsAndConditions =
        '1. Goods once sold cannot be returned without original receipt.\n2. Checking warranty on used devices is 3 days only.\n3. Lab Repair job warranty covers only repaired fault for 15 days.\n4. No warranty on display glass, water damage, or physical damage.',
    this.receiptFormat = 'a4',
    this.isDarkMode = false,
    this.autoBackupEnabled = true,
    this.defaultWarrantyDays = 365,
    this.adminUsername = 'admin',
    this.adminPassword = 'admin@123',
  });

  BusinessSettings copyWith({
    String? shopName,
    String? tagline,
    String? address,
    String? phone,
    String? altPhone,
    String? email,
    String? ntn,
    String? currency,
    String? invoicePrefix,
    String? repairPrefix,
    String? purchasePrefix,
    String? receiptPrefix,
    String? invoiceFooter,
    String? termsAndConditions,
    String? receiptFormat,
    bool? isDarkMode,
    bool? autoBackupEnabled,
    int? defaultWarrantyDays,
    String? adminUsername,
    String? adminPassword,
  }) {
    return BusinessSettings(
      shopName: shopName ?? this.shopName,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      ntn: ntn ?? this.ntn,
      currency: currency ?? this.currency,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      repairPrefix: repairPrefix ?? this.repairPrefix,
      purchasePrefix: purchasePrefix ?? this.purchasePrefix,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      receiptFormat: receiptFormat ?? this.receiptFormat,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      defaultWarrantyDays: defaultWarrantyDays ?? this.defaultWarrantyDays,
      adminUsername: adminUsername ?? this.adminUsername,
      adminPassword: adminPassword ?? this.adminPassword,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_name': shopName,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'alt_phone': altPhone,
      'email': email,
      'ntn': ntn,
      'currency': currency,
      'invoice_prefix': invoicePrefix,
      'repair_prefix': repairPrefix,
      'purchase_prefix': purchasePrefix,
      'receipt_prefix': receiptPrefix,
      'invoice_footer': invoiceFooter,
      'terms_and_conditions': termsAndConditions,
      'receipt_format': receiptFormat,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'auto_backup_enabled': autoBackupEnabled ? 1 : 0,
      'default_warranty_days': defaultWarrantyDays,
      'admin_username': adminUsername,
      'admin_password': adminPassword,
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      shopName: (map['shop_name'] as String?) ?? 'Al-Madina Mobile & Repairing Lab',
      tagline: (map['tagline'] as String?) ?? 'Smartphones, Original Accessories & Expert Chip-Level Repair Lab',
      address: (map['address'] as String?) ?? 'Shop #42, 1st Floor, Hafeez Centre, Main Boulevard, Gulberg III, Lahore',
      phone: (map['phone'] as String?) ?? '0300-1234567',
      altPhone: (map['alt_phone'] as String?) ?? '042-35876543',
      email: (map['email'] as String?) ?? 'info@almadinamobile.pk',
      ntn: (map['ntn'] as String?) ?? '7891234-8',
      currency: (map['currency'] as String?) ?? 'Rs.',
      invoicePrefix: (map['invoice_prefix'] as String?) ?? 'INV-',
      repairPrefix: (map['repair_prefix'] as String?) ?? 'REP-',
      purchasePrefix: (map['purchase_prefix'] as String?) ?? 'PUR-',
      receiptPrefix: (map['receipt_prefix'] as String?) ?? 'REC-',
      invoiceFooter: (map['invoice_footer'] as String?) ??
          'Thank you for choosing us! Please check goods and test warranty before leaving.',
      termsAndConditions: (map['terms_and_conditions'] as String?) ??
          '1. Goods once sold cannot be returned without original receipt.\n2. Checking warranty on used devices is 3 days only.\n3. Lab Repair job warranty covers only repaired fault for 15 days.\n4. No warranty on display glass, water damage, or physical damage.',
      receiptFormat: (map['receipt_format'] as String?) ?? 'a4',
      isDarkMode: (map['is_dark_mode'] as int?) == 1,
      autoBackupEnabled: (map['auto_backup_enabled'] as int?) == 1,
      defaultWarrantyDays: (map['default_warranty_days'] as num?)?.toInt() ?? 365,
      adminUsername: (map['admin_username'] as String?) ?? 'admin',
      adminPassword: (map['admin_password'] as String?) ?? 'admin@123',
    );
  }
}
