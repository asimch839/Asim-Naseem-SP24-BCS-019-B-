import '../../core/constants/app_constants.dart';

class JobServiceItem {
  final String serviceId;
  final String serviceName;
  final double price;

  JobServiceItem({
    required this.serviceId,
    required this.serviceName,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
    };
  }

  factory JobServiceItem.fromMap(Map<String, dynamic> map) {
    return JobServiceItem(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JobStockUsageItem {
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;

  JobStockUsageItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory JobStockUsageItem.fromMap(Map<String, dynamic> map) {
    return JobStockUsageItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'unit',
    );
  }
}

class JobModel {
  final String id;
  final String jobNumber; // e.g. JOB-1001
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleId;
  final String vehicleRegNumber;
  final String vehicleDisplayName;
  final String? inspectionId;
  final List<JobServiceItem> services;
  final List<String> assignedStaffIds;
  final List<String> assignedStaffNames;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double paidAmount;
  final double remainingAmount;
  final List<String> beforePhotoUrls;
  final List<String> afterPhotoUrls;
  final bool stockUsageConfirmed;
  final List<JobStockUsageItem> stockUsage;
  final String? customerSignature;
  final String? serviceAdvisorSignature;
  final String? authorizedSignature;
  final String? notes;
  final String? invoiceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  JobModel({
    required this.id,
    required this.jobNumber,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleId,
    required this.vehicleRegNumber,
    required this.vehicleDisplayName,
    this.inspectionId,
    required this.services,
    this.assignedStaffIds = const [],
    this.assignedStaffNames = const [],
    this.status = AppConstants.jobStatusNew,
    this.startTime,
    this.endTime,
    double? subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    this.paidAmount = 0.0,
    required this.remainingAmount,
    this.beforePhotoUrls = const [],
    this.afterPhotoUrls = const [],
    this.stockUsageConfirmed = false,
    this.stockUsage = const [],
    this.customerSignature,
    this.serviceAdvisorSignature,
    this.authorizedSignature,
    this.notes,
    this.invoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : subtotal = subtotal ?? grandTotal,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isCompleted => status == AppConstants.jobStatusCompleted || status == AppConstants.jobStatusReadyForDelivery || status == AppConstants.jobStatusDelivered;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobNumber': jobNumber,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleId': vehicleId,
      'vehicleRegNumber': vehicleRegNumber,
      'vehicleDisplayName': vehicleDisplayName,
      'inspectionId': inspectionId,
      'services': services.map((s) => s.toMap()).toList(),
      'assignedStaffIds': assignedStaffIds,
      'assignedStaffNames': assignedStaffNames,
      'status': status,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'beforePhotoUrls': beforePhotoUrls,
      'afterPhotoUrls': afterPhotoUrls,
      'stockUsageConfirmed': stockUsageConfirmed,
      'stockUsage': stockUsage.map((u) => u.toMap()).toList(),
      'customerSignature': customerSignature,
      'serviceAdvisorSignature': serviceAdvisorSignature,
      'authorizedSignature': authorizedSignature,
      'notes': notes,
      'invoiceId': invoiceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String docId) {
    return JobModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      jobNumber: map['jobNumber'] ?? '',
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      vehicleRegNumber: map['vehicleRegNumber'] ?? '',
      vehicleDisplayName: map['vehicleDisplayName'] ?? '',
      inspectionId: map['inspectionId'],
      services: (map['services'] as List<dynamic>?)
              ?.map((s) => JobServiceItem.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      assignedStaffIds: List<String>.from(map['assignedStaffIds'] ?? []),
      assignedStaffNames: List<String>.from(map['assignedStaffNames'] ?? []),
      status: map['status'] ?? AppConstants.jobStatusNew,
      startTime: map['startTime'] != null ? DateTime.tryParse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.tryParse(map['endTime']) : null,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      beforePhotoUrls: List<String>.from(map['beforePhotoUrls'] ?? []),
      afterPhotoUrls: List<String>.from(map['afterPhotoUrls'] ?? []),
      stockUsageConfirmed: map['stockUsageConfirmed'] ?? false,
      stockUsage: (map['stockUsage'] as List<dynamic>?)
              ?.map((u) => JobStockUsageItem.fromMap(u as Map<String, dynamic>))
              .toList() ??
          [],
      customerSignature: map['customerSignature'] ?? map['customer_signature'],
      serviceAdvisorSignature: map['serviceAdvisorSignature'] ?? map['service_advisor_signature'],
      authorizedSignature: map['authorizedSignature'] ?? map['authorized_signature'],
      notes: map['notes'],
      invoiceId: map['invoiceId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  JobModel copyWith({
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? assignedStaffIds,
    List<String>? assignedStaffNames,
    List<JobServiceItem>? services,
    double? subtotal,
    double? discount,
    double? tax,
    double? grandTotal,
    double? paidAmount,
    double? remainingAmount,
    List<String>? beforePhotoUrls,
    List<String>? afterPhotoUrls,
    bool? stockUsageConfirmed,
    List<JobStockUsageItem>? stockUsage,
    String? notes,
    String? invoiceId,
    bool? isDeleted,
  }) {
    return JobModel(
      id: id,
      jobNumber: jobNumber,
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicleId: vehicleId,
      vehicleRegNumber: vehicleRegNumber,
      vehicleDisplayName: vehicleDisplayName,
      inspectionId: inspectionId,
      services: services ?? this.services,
      assignedStaffIds: assignedStaffIds ?? this.assignedStaffIds,
      assignedStaffNames: assignedStaffNames ?? this.assignedStaffNames,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      beforePhotoUrls: beforePhotoUrls ?? this.beforePhotoUrls,
      afterPhotoUrls: afterPhotoUrls ?? this.afterPhotoUrls,
      stockUsageConfirmed: stockUsageConfirmed ?? this.stockUsageConfirmed,
      stockUsage: stockUsage ?? this.stockUsage,
      notes: notes ?? this.notes,
      invoiceId: invoiceId ?? this.invoiceId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
