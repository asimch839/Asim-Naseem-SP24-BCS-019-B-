class BusinessModel {
  final String id;
  final String name;
  final String ownerId;
  final String phone;
  final String? whatsapp;
  final String email;
  final String address;
  final String? logoUrl;
  final String currency;
  final double taxRate;
  final String jobPrefix;
  final String invoicePrefix;
  final String inspectionPrefix;
  final String timezone;
  final double globalLowStockThreshold;
  final String? termsAndConditions;
  final List<String> inspectionSections;
  final List<String> checklistItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.phone,
    this.whatsapp,
    required this.email,
    required this.address,
    this.logoUrl,
    this.currency = 'Rs.',
    this.timezone = 'Asia/Karachi (PKT +05:00)',
    this.taxRate = 0.0,
    this.jobPrefix = 'JOB-',
    this.invoicePrefix = 'INV-',
    this.inspectionPrefix = 'INSP-',
    this.globalLowStockThreshold = 5.0,
    this.termsAndConditions,
    List<String>? inspectionSections,
    List<String>? checklistItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : inspectionSections = inspectionSections ??
            const [
              'Exterior',
              'Interior',
              'Tires',
              'Engine',
              'Wind Screen / Glass',
              'Body',
              'Paint',
              'Suspension',
              'Electronics',
              'Body Parts',
              'Drive',
            ],
        checklistItems = checklistItems ??
            const [
              'Spare Wheel & Jack',
              'Toolkit & Rod',
              'Floor Mats (Front & Rear)',
              'Audio / Media Player & Remote',
              'Perfume / Freshener',
              'Original Documents / Tax Token',
              'Cigarette Lighter',
              'Personal Valuables & Belongings',
            ],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'logoUrl': logoUrl,
      'currency': currency,
      'timezone': timezone,
      'taxRate': taxRate,
      'jobPrefix': jobPrefix,
      'invoicePrefix': invoicePrefix,
      'inspectionPrefix': inspectionPrefix,
      'globalLowStockThreshold': globalLowStockThreshold,
      'termsAndConditions': termsAndConditions,
      'inspectionSections': inspectionSections,
      'checklistItems': checklistItems,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map, String docId) {
    return BusinessModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'],
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      logoUrl: map['logoUrl'],
      currency: map['currency'] ?? 'Rs.',
      timezone: map['timezone'] ?? 'Asia/Karachi (PKT +05:00)',
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      jobPrefix: map['jobPrefix'] ?? 'JOB-',
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      inspectionPrefix: map['inspectionPrefix'] ?? 'INSP-',
      globalLowStockThreshold: (map['globalLowStockThreshold'] as num?)?.toDouble() ?? 5.0,
      termsAndConditions: map['termsAndConditions'],
      inspectionSections: map['inspectionSections'] != null
          ? List<String>.from(map['inspectionSections'])
          : null,
      checklistItems: map['checklistItems'] != null
          ? List<String>.from(map['checklistItems'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BusinessModel copyWith({
    String? name,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? logoUrl,
    String? currency,
    String? timezone,
    double? taxRate,
    String? jobPrefix,
    String? invoicePrefix,
    String? inspectionPrefix,
    double? globalLowStockThreshold,
    String? termsAndConditions,
    List<String>? inspectionSections,
    List<String>? checklistItems,
  }) {
    return BusinessModel(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      taxRate: taxRate ?? this.taxRate,
      jobPrefix: jobPrefix ?? this.jobPrefix,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      inspectionPrefix: inspectionPrefix ?? this.inspectionPrefix,
      globalLowStockThreshold: globalLowStockThreshold ?? this.globalLowStockThreshold,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      inspectionSections: inspectionSections ?? this.inspectionSections,
      checklistItems: checklistItems ?? this.checklistItems,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
