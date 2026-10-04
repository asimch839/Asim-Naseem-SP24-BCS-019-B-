import 'dart:convert';

enum RepairStatus {
  received,
  inspection,
  waitingForApproval,
  approved,
  inProgress,
  waitingForParts,
  waitingForCustomer,
  completed,
  readyForDelivery,
  delivered,
  cancelled,
  unrepairable;

  String get displayName {
    switch (this) {
      case RepairStatus.received:
        return 'Received';
      case RepairStatus.inspection:
        return 'Inspection';
      case RepairStatus.waitingForApproval:
        return 'Waiting for Approval';
      case RepairStatus.approved:
        return 'Approved';
      case RepairStatus.inProgress:
        return 'In Progress';
      case RepairStatus.waitingForParts:
        return 'Waiting for Parts';
      case RepairStatus.waitingForCustomer:
        return 'Waiting for Customer';
      case RepairStatus.completed:
        return 'Completed';
      case RepairStatus.readyForDelivery:
        return 'Ready for Delivery';
      case RepairStatus.delivered:
        return 'Delivered';
      case RepairStatus.cancelled:
        return 'Cancelled';
      case RepairStatus.unrepairable:
        return 'Unrepairable';
    }
  }

  bool get isTerminal =>
      this == RepairStatus.delivered ||
      this == RepairStatus.cancelled ||
      this == RepairStatus.unrepairable;
}

class RepairPart {
  final String id;
  final String productId;
  final String partName;
  final int quantity;
  final double costPrice;
  final double sellingPrice;

  RepairPart({
    required this.id,
    required this.productId,
    required this.partName,
    this.quantity = 1,
    required this.costPrice,
    required this.sellingPrice,
  });

  double get totalSellingPrice => sellingPrice * quantity;
  double get totalCostPrice => costPrice * quantity;
  double get profit => totalSellingPrice - totalCostPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'part_name': partName,
      'quantity': quantity,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
    };
  }

  factory RepairPart.fromMap(Map<String, dynamic> map) {
    return RepairPart(
      id: map['id'] as String,
      productId: (map['product_id'] as String?) ?? '',
      partName: (map['part_name'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RepairStatusHistory {
  final String id;
  final String repairId;
  final RepairStatus status;
  final String changedBy;
  final DateTime timestamp;
  final String notes;

  RepairStatusHistory({
    required this.id,
    required this.repairId,
    required this.status,
    required this.changedBy,
    DateTime? timestamp,
    this.notes = '',
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'repair_id': repairId,
      'status': status.name,
      'changed_by': changedBy,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory RepairStatusHistory.fromMap(Map<String, dynamic> map) {
    return RepairStatusHistory(
      id: map['id'] as String,
      repairId: (map['repair_id'] as String?) ?? '',
      status: RepairStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RepairStatus.received,
      ),
      changedBy: (map['changed_by'] as String?) ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

class RepairJob {
  final String id;
  final String jobId; // e.g. 'REP-1001'
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAltPhone;
  final String customerAddress;
  final String deviceBrand;
  final String deviceModel;
  final String imei;
  final String serialNumber;
  final String color;
  final String deviceCondition;
  final String reportedProblem;
  final String technicianNotes;
  final String accessoriesReceived;
  final String lockPinOrPassword;
  final double estimatedCost;
  final double advancePaid;
  final double laborCharges;
  final double otherCharges;
  final double discount;
  final double finalTotal;
  final double remainingDue;
  final String paymentMethod;
  final RepairStatus status;
  final String technicianId;
  final String technicianName;
  final DateTime expectedDeliveryDate;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<RepairPart> partsUsed;
  final List<RepairStatusHistory> history;

  RepairJob({
    required this.id,
    required this.jobId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAltPhone = '',
    this.customerAddress = '',
    required this.deviceBrand,
    required this.deviceModel,
    this.imei = '',
    this.serialNumber = '',
    this.color = '',
    this.deviceCondition = 'Good / Minor Scratches',
    required this.reportedProblem,
    this.technicianNotes = '',
    this.accessoriesReceived = 'Device Only',
    this.lockPinOrPassword = '',
    this.estimatedCost = 0.0,
    this.advancePaid = 0.0,
    this.laborCharges = 0.0,
    this.otherCharges = 0.0,
    this.discount = 0.0,
    required this.finalTotal,
    required this.remainingDue,
    this.paymentMethod = 'Cash',
    this.status = RepairStatus.received,
    this.technicianId = '',
    this.technicianName = 'Unassigned',
    required this.expectedDeliveryDate,
    DateTime? createdAt,
    this.deliveredAt,
    this.partsUsed = const [],
    this.history = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get partsTotalSelling => partsUsed.fold(0.0, (s, p) => s + p.totalSellingPrice);
  double get partsTotalCost => partsUsed.fold(0.0, (s, p) => s + p.totalCostPrice);
  double get calculatedTotal => (laborCharges + partsTotalSelling + otherCharges) - discount;
  double get calculatedDue => calculatedTotal - advancePaid;
  double get netProfit => (finalTotal - discount) - partsTotalCost;

  RepairJob copyWith({
    String? id,
    String? jobId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAltPhone,
    String? customerAddress,
    String? deviceBrand,
    String? deviceModel,
    String? imei,
    String? serialNumber,
    String? color,
    String? deviceCondition,
    String? reportedProblem,
    String? technicianNotes,
    String? accessoriesReceived,
    String? lockPinOrPassword,
    double? estimatedCost,
    double? advancePaid,
    double? laborCharges,
    double? otherCharges,
    double? discount,
    double? finalTotal,
    double? remainingDue,
    String? paymentMethod,
    RepairStatus? status,
    String? technicianId,
    String? technicianName,
    DateTime? expectedDeliveryDate,
    DateTime? createdAt,
    DateTime? deliveredAt,
    List<RepairPart>? partsUsed,
    List<RepairStatusHistory>? history,
  }) {
    return RepairJob(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAltPhone: customerAltPhone ?? this.customerAltPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      imei: imei ?? this.imei,
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      deviceCondition: deviceCondition ?? this.deviceCondition,
      reportedProblem: reportedProblem ?? this.reportedProblem,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      accessoriesReceived: accessoriesReceived ?? this.accessoriesReceived,
      lockPinOrPassword: lockPinOrPassword ?? this.lockPinOrPassword,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      advancePaid: advancePaid ?? this.advancePaid,
      laborCharges: laborCharges ?? this.laborCharges,
      otherCharges: otherCharges ?? this.otherCharges,
      discount: discount ?? this.discount,
      finalTotal: finalTotal ?? this.finalTotal,
      remainingDue: remainingDue ?? this.remainingDue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      partsUsed: partsUsed ?? this.partsUsed,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_alt_phone': customerAltPhone,
      'customer_address': customerAddress,
      'device_brand': deviceBrand,
      'device_model': deviceModel,
      'imei': imei,
      'serial_number': serialNumber,
      'color': color,
      'device_condition': deviceCondition,
      'reported_problem': reportedProblem,
      'technician_notes': technicianNotes,
      'accessories_received': accessoriesReceived,
      'lock_pin_or_password': lockPinOrPassword,
      'estimated_cost': estimatedCost,
      'advance_paid': advancePaid,
      'labor_charges': laborCharges,
      'other_charges': otherCharges,
      'discount': discount,
      'final_total': finalTotal,
      'remaining_due': remainingDue,
      'payment_method': paymentMethod,
      'status': status.name,
      'technician_id': technicianId,
      'technician_name': technicianName,
      'expected_delivery_date': expectedDeliveryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'parts_used_json': jsonEncode(partsUsed.map((p) => p.toMap()).toList()),
      'history_json': jsonEncode(history.map((h) => h.toMap()).toList()),
    };
  }

  factory RepairJob.fromMap(Map<String, dynamic> map) {
    List<RepairPart> parts = [];
    if (map['parts_used_json'] != null) {
      try {
        final decoded = jsonDecode(map['parts_used_json'].toString()) as List;
        parts = decoded.map((e) => RepairPart.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    List<RepairStatusHistory> hist = [];
    if (map['history_json'] != null) {
      try {
        final decoded = jsonDecode(map['history_json'].toString()) as List;
        hist = decoded.map((e) => RepairStatusHistory.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return RepairJob(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      customerId: (map['customer_id'] as String?) ?? '',
      customerName: (map['customer_name'] as String?) ?? '',
      customerPhone: (map['customer_phone'] as String?) ?? '',
      customerAltPhone: (map['customer_alt_phone'] as String?) ?? '',
      customerAddress: (map['customer_address'] as String?) ?? '',
      deviceBrand: (map['device_brand'] as String?) ?? '',
      deviceModel: (map['device_model'] as String?) ?? '',
      imei: (map['imei'] as String?) ?? '',
      serialNumber: (map['serial_number'] as String?) ?? '',
      color: (map['color'] as String?) ?? '',
      deviceCondition: (map['device_condition'] as String?) ?? '',
      reportedProblem: (map['reported_problem'] as String?) ?? '',
      technicianNotes: (map['technician_notes'] as String?) ?? '',
      accessoriesReceived: (map['accessories_received'] as String?) ?? '',
      lockPinOrPassword: (map['lock_pin_or_password'] as String?) ?? '',
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      advancePaid: (map['advance_paid'] as num?)?.toDouble() ?? 0.0,
      laborCharges: (map['labor_charges'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (map['other_charges'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (map['final_total'] as num?)?.toDouble() ?? 0.0,
      remainingDue: (map['remaining_due'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      status: RepairStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RepairStatus.received,
      ),
      technicianId: (map['technician_id'] as String?) ?? '',
      technicianName: (map['technician_name'] as String?) ?? 'Unassigned',
      expectedDeliveryDate: DateTime.tryParse(map['expected_delivery_date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      deliveredAt: map['delivered_at'] != null ? DateTime.tryParse(map['delivered_at'].toString()) : null,
      partsUsed: parts,
      history: hist,
    );
  }
}
