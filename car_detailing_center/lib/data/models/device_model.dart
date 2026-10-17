class DeviceModel {
  final String deviceId;
  final String businessId;
  final String userId;
  final String userName;
  final String userEmail;
  final String platform; // Windows, Android Mobile, Android Tablet, etc.
  final String? fcmToken;
  final DateTime lastActiveAt;
  final bool isRevoked;
  final DateTime createdAt;

  DeviceModel({
    required this.deviceId,
    required this.businessId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.platform,
    this.fcmToken,
    DateTime? lastActiveAt,
    this.isRevoked = false,
    DateTime? createdAt,
  })  : lastActiveAt = lastActiveAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'businessId': businessId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'platform': platform,
      'fcmToken': fcmToken,
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isRevoked': isRevoked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map, String docId) {
    return DeviceModel(
      deviceId: docId.isNotEmpty ? docId : (map['deviceId'] ?? ''),
      businessId: map['businessId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      platform: map['platform'] ?? 'Unknown',
      fcmToken: map['fcmToken'],
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt']) ?? DateTime.now()
          : DateTime.now(),
      isRevoked: map['isRevoked'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DeviceModel copyWith({
    bool? isRevoked,
    DateTime? lastActiveAt,
    String? fcmToken,
  }) {
    return DeviceModel(
      deviceId: deviceId,
      businessId: businessId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      platform: platform,
      fcmToken: fcmToken ?? this.fcmToken,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isRevoked: isRevoked ?? this.isRevoked,
      createdAt: createdAt,
    );
  }
}
