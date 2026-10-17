class AuditLogModel {
  final String id;
  final String businessId;
  final String userId;
  final String userName;
  final String action; // Created, Updated, Deleted, Status Changed, Payment Added, Stock Adjusted
  final String entityType; // Customer, Vehicle, Job, Invoice, Payment, Inventory, Salary, Expense
  final String entityId;
  final String details;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
    this.previousState,
    this.newState,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'userId': userId,
      'userName': userName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'details': details,
      'previousState': previousState,
      'newState': newState,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return AuditLogModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      entityType: map['entityType'] ?? '',
      entityId: map['entityId'] ?? '',
      details: map['details'] ?? '',
      previousState: map['previousState'] as Map<String, dynamic>?,
      newState: map['newState'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
