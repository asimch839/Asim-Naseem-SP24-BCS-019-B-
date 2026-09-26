class RoomModel {
  final int? id;
  final String roomNumber;
  final String block;
  final String floor;
  final String roomType; // 'Single', 'Double', 'Triple', 'Four Bed', 'Other'
  final int totalBeds;
  final double monthlyRent;
  final String roomStatus; // 'Available', 'Full', 'Maintenance'
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  // Joined/calculated fields
  final int occupiedBedsCount;
  final int availableBedsCount;

  RoomModel({
    this.id,
    required this.roomNumber,
    required this.block,
    required this.floor,
    required this.roomType,
    required this.totalBeds,
    required this.monthlyRent,
    this.roomStatus = 'Available',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.occupiedBedsCount = 0,
    this.availableBedsCount = 0,
  });

  bool get isAvailable => roomStatus == 'Available' && availableBedsCount > 0;
  bool get isFull => roomStatus == 'Full' || occupiedBedsCount >= totalBeds;
  bool get isMaintenance => roomStatus == 'Maintenance';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_number': roomNumber,
      'block': block,
      'floor': floor,
      'room_type': roomType,
      'total_beds': totalBeds,
      'monthly_rent': monthlyRent,
      'room_status': roomStatus,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    final total = (map['total_beds'] as int?) ?? 1;
    final occupied = (map['occupied_beds_count'] as int?) ?? 0;
    return RoomModel(
      id: map['id'] as int?,
      roomNumber: map['room_number'] as String,
      block: (map['block'] as String?) ?? 'Main',
      floor: (map['floor'] as String?) ?? 'Ground',
      roomType: (map['room_type'] as String?) ?? 'Single',
      totalBeds: total,
      monthlyRent: (map['monthly_rent'] as num?)?.toDouble() ?? 0.0,
      roomStatus: (map['room_status'] as String?) ?? 'Available',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      occupiedBedsCount: occupied,
      availableBedsCount: (total - occupied).clamp(0, total),
    );
  }

  RoomModel copyWith({
    int? id,
    String? roomNumber,
    String? block,
    String? floor,
    String? roomType,
    int? totalBeds,
    double? monthlyRent,
    String? roomStatus,
    String? notes,
    String? createdAt,
    String? updatedAt,
    int? occupiedBedsCount,
    int? availableBedsCount,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      block: block ?? this.block,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      totalBeds: totalBeds ?? this.totalBeds,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      roomStatus: roomStatus ?? this.roomStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      occupiedBedsCount: occupiedBedsCount ?? this.occupiedBedsCount,
      availableBedsCount: availableBedsCount ?? this.availableBedsCount,
    );
  }
}
