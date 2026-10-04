import 'dart:convert';

class WarrantyClaim {
  final String id;
  final String warrantyId;
  final DateTime claimDate;
  final String reportedIssue;
  final String resolution;
  final String status; // 'Pending', 'Approved', 'Replaced', 'Rejected'
  final String technicianNotes;

  WarrantyClaim({
    required this.id,
    required this.warrantyId,
    DateTime? claimDate,
    required this.reportedIssue,
    this.resolution = '',
    this.status = 'Pending',
    this.technicianNotes = '',
  }) : claimDate = claimDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warranty_id': warrantyId,
      'claim_date': claimDate.toIso8601String(),
      'reported_issue': reportedIssue,
      'resolution': resolution,
      'status': status,
      'technician_notes': technicianNotes,
    };
  }

  factory WarrantyClaim.fromMap(Map<String, dynamic> map) {
    return WarrantyClaim(
      id: map['id'] as String,
      warrantyId: (map['warranty_id'] as String?) ?? '',
      claimDate: DateTime.tryParse(map['claim_date']?.toString() ?? '') ?? DateTime.now(),
      reportedIssue: (map['reported_issue'] as String?) ?? '',
      resolution: (map['resolution'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'Pending',
      technicianNotes: (map['technician_notes'] as String?) ?? '',
    );
  }
}

class WarrantyRecord {
  final String id;
  final String type; // 'phone', 'accessory', 'repair'
  final String referenceId; // INV-1001 or REP-1002
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String itemName;
  final String imei;
  final DateTime startDate;
  final DateTime endDate;
  final String warrantyTerms;
  final String status; // 'Active', 'Expiring Soon', 'Expired', 'Claimed'
  final List<WarrantyClaim> claims;

  WarrantyRecord({
    required this.id,
    required this.type,
    required this.referenceId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.itemName,
    this.imei = '',
    required this.startDate,
    required this.endDate,
    this.warrantyTerms = 'Standard Shop Warranty',
    this.status = 'Active',
    this.claims = const [],
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon => !isExpired && endDate.difference(DateTime.now()).inDays <= 15;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  WarrantyRecord copyWith({
    String? id,
    String? type,
    String? referenceId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? itemName,
    String? imei,
    DateTime? startDate,
    DateTime? endDate,
    String? warrantyTerms,
    String? status,
    List<WarrantyClaim>? claims,
  }) {
    return WarrantyRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      itemName: itemName ?? this.itemName,
      imei: imei ?? this.imei,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      warrantyTerms: warrantyTerms ?? this.warrantyTerms,
      status: status ?? this.status,
      claims: claims ?? this.claims,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'reference_id': referenceId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'item_name': itemName,
      'imei': imei,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'warranty_terms': warrantyTerms,
      'status': isExpired ? 'Expired' : (isExpiringSoon ? 'Expiring Soon' : status),
      'claims_json': jsonEncode(claims.map((c) => c.toMap()).toList()),
    };
  }

  factory WarrantyRecord.fromMap(Map<String, dynamic> map) {
    List<WarrantyClaim> claimsList = [];
    if (map['claims_json'] != null) {
      try {
        final decoded = jsonDecode(map['claims_json'].toString()) as List;
        claimsList = decoded.map((e) => WarrantyClaim.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    final start = DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(map['end_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 365));
    String stat = (map['status'] as String?) ?? 'Active';
    if (DateTime.now().isAfter(end)) {
      stat = 'Expired';
    } else if (end.difference(DateTime.now()).inDays <= 15 && stat == 'Active') {
      stat = 'Expiring Soon';
    }

    return WarrantyRecord(
      id: map['id'] as String,
      type: (map['type'] as String?) ?? 'phone',
      referenceId: (map['reference_id'] as String?) ?? '',
      customerId: (map['customer_id'] as String?) ?? '',
      customerName: (map['customer_name'] as String?) ?? '',
      customerPhone: (map['customer_phone'] as String?) ?? '',
      itemName: (map['item_name'] as String?) ?? '',
      imei: (map['imei'] as String?) ?? '',
      startDate: start,
      endDate: end,
      warrantyTerms: (map['warranty_terms'] as String?) ?? 'Standard Shop Warranty',
      status: stat,
      claims: claimsList,
    );
  }
}
