class InspectionPartItem {
  final String partName;
  final String view; // 'Front', 'Rear', 'Top', 'Left Side', 'Right Side', 'Custom'
  final String condition; // Free-text (e.g. 'Good', 'Minor scratch', 'Dent')
  final String? damageDescription;
  final String? notes;
  final List<String> photoUrls;
  final bool hasDamage;

  InspectionPartItem({
    required this.partName,
    required this.view,
    required this.condition,
    this.damageDescription,
    this.notes,
    this.photoUrls = const [],
    this.hasDamage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'partName': partName,
      'view': view,
      'condition': condition,
      'damageDescription': damageDescription,
      'notes': notes,
      'photoUrls': photoUrls,
      'hasDamage': hasDamage,
    };
  }

  factory InspectionPartItem.fromMap(Map<String, dynamic> map) {
    return InspectionPartItem(
      partName: map['partName'] ?? '',
      view: map['view'] ?? 'Top',
      condition: map['condition'] ?? 'Good',
      damageDescription: map['damageDescription'],
      notes: map['notes'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      hasDamage: map['hasDamage'] ?? false,
    );
  }

  InspectionPartItem copyWith({
    String? condition,
    String? damageDescription,
    String? notes,
    List<String>? photoUrls,
    bool? hasDamage,
  }) {
    return InspectionPartItem(
      partName: partName,
      view: view,
      condition: condition ?? this.condition,
      damageDescription: damageDescription ?? this.damageDescription,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      hasDamage: hasDamage ?? this.hasDamage,
    );
  }
}

class ChecklistRecordItem {
  final String item;
  final String status; // 'Present', 'Missing', 'Damaged', 'Not Applicable'
  final String? notes;

  ChecklistRecordItem({
    required this.item,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'status': status,
      'notes': notes,
    };
  }

  factory ChecklistRecordItem.fromMap(Map<String, dynamic> map) {
    return ChecklistRecordItem(
      item: map['item'] ?? '',
      status: map['status'] ?? 'Present',
      notes: map['notes'],
    );
  }
}

class InspectionModel {
  final String id;
  final String businessId;
  final String vehicleId;
  final String customerId;
  final String? jobId;
  final String inspectorStaffId;
  final String inspectorStaffName;
  final DateTime inspectionDate;

  // Diagram Parts (Front, Rear, Top, Left, Right + Custom)
  final List<InspectionPartItem> diagramParts;

  // Free-text Configurable Sections: Exterior, Interior, Tires, Engine, Windscreen, Body, Paint, Suspension, Electronics, Drive
  final Map<String, String> sectionConditions;

  // Drive Condition Detailed
  final Map<String, String> driveCondition;

  // Vehicle Belongings / Checklist
  final List<ChecklistRecordItem> checklist;

  final String? staffRemarks;
  final String? customerRemarks;
  final List<String> damagePhotoUrls;
  final String? customerSignatureUrl;
  final String? advisorSignatureUrl;
  final String? authorizedSignatureUrl;
  final DateTime createdAt;

  InspectionModel({
    required this.id,
    required this.businessId,
    required this.vehicleId,
    required this.customerId,
    this.jobId,
    this.inspectorStaffId = 'inspector',
    required this.inspectorStaffName,
    DateTime? inspectionDate,
    this.diagramParts = const [],
    this.sectionConditions = const {},
    this.driveCondition = const {},
    this.checklist = const [],
    this.staffRemarks,
    this.customerRemarks,
    this.damagePhotoUrls = const [],
    this.customerSignatureUrl,
    this.advisorSignatureUrl,
    this.authorizedSignatureUrl,
    DateTime? createdAt,
  })  : inspectionDate = inspectionDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  int get damagedAreasCount {
    int count = diagramParts.where((p) => p.hasDamage || (p.damageDescription != null && p.damageDescription!.isNotEmpty)).length;
    for (var c in sectionConditions.values) {
      if (c.toLowerCase().contains('scratch') ||
          c.toLowerCase().contains('dent') ||
          c.toLowerCase().contains('damage') ||
          c.toLowerCase().contains('broken') ||
          c.toLowerCase().contains('crack') ||
          c.toLowerCase().contains('leak')) {
        count++;
      }
    }
    return count;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'vehicleId': vehicleId,
      'customerId': customerId,
      'jobId': jobId,
      'inspectorStaffId': inspectorStaffId,
      'inspectorStaffName': inspectorStaffName,
      'inspectionDate': inspectionDate.toIso8601String(),
      'diagramParts': diagramParts.map((p) => p.toMap()).toList(),
      'sectionConditions': sectionConditions,
      'driveCondition': driveCondition,
      'checklist': checklist.map((c) => c.toMap()).toList(),
      'staffRemarks': staffRemarks,
      'customerRemarks': customerRemarks,
      'damagePhotoUrls': damagePhotoUrls,
      'customerSignatureUrl': customerSignatureUrl,
      'advisorSignatureUrl': advisorSignatureUrl,
      'authorizedSignatureUrl': authorizedSignatureUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InspectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return InspectionModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      customerId: map['customerId'] ?? '',
      jobId: map['jobId'],
      inspectorStaffId: map['inspectorStaffId'] ?? '',
      inspectorStaffName: map['inspectorStaffName'] ?? '',
      inspectionDate: map['inspectionDate'] != null
          ? DateTime.tryParse(map['inspectionDate']) ?? DateTime.now()
          : DateTime.now(),
      diagramParts: (map['diagramParts'] as List<dynamic>?)
              ?.map((p) => InspectionPartItem.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      sectionConditions: Map<String, String>.from(map['sectionConditions'] ?? {}),
      driveCondition: Map<String, String>.from(map['driveCondition'] ?? {}),
      checklist: (map['checklist'] as List<dynamic>?)
              ?.map((c) => ChecklistRecordItem.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      staffRemarks: map['staffRemarks'],
      customerRemarks: map['customerRemarks'],
      damagePhotoUrls: List<String>.from(map['damagePhotoUrls'] ?? []),
      customerSignatureUrl: map['customerSignatureUrl'],
      advisorSignatureUrl: map['advisorSignatureUrl'],
      authorizedSignatureUrl: map['authorizedSignatureUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
