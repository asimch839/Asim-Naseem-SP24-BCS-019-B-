class NotificationModel {
  final String id;
  final String businessId;
  final String title;
  final String message;
  final String type; // Job, Inventory, Payment, Invoice, Attendance, Salary, Expense, System
  final String? targetRoute;
  final String? relatedEntityId;
  final List<String> targetRoles; // ['admin', 'manager', 'staff']
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.message,
    required this.type,
    this.targetRoute,
    this.relatedEntityId,
    this.targetRoles = const ['admin', 'manager'],
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'message': message,
      'type': type,
      'targetRoute': targetRoute,
      'relatedEntityId': relatedEntityId,
      'targetRoles': targetRoles,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'System',
      targetRoute: map['targetRoute'],
      relatedEntityId: map['relatedEntityId'],
      targetRoles: List<String>.from(map['targetRoles'] ?? ['admin', 'manager']),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      businessId: businessId,
      title: title,
      message: message,
      type: type,
      targetRoute: targetRoute,
      relatedEntityId: relatedEntityId,
      targetRoles: targetRoles,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
