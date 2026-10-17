class VehicleModel {
  final String id;
  final String businessId;
  final String customerId;
  final String registrationNumber;
  final String make;
  final String model;
  final int? year;
  final String? color;
  final int? mileage;
  final String? vin;
  final String vehicleType; // Sedan, SUV, Hatchback, Truck, Coupe, Van
  final String? notes;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  VehicleModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    String? registrationNumber,
    String? plateNumber,
    this.make = '',
    this.model = '',
    this.year,
    this.color,
    int? mileage,
    int? currentMileage,
    this.vin,
    this.vehicleType = 'Sedan',
    this.notes,
    this.photoUrls = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : registrationNumber = (registrationNumber ?? plateNumber ?? '').toUpperCase().trim(),
        mileage = mileage ?? currentMileage,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get plateNumber => registrationNumber;
  int? get currentMileage => mileage;
  int? get currentOdometer => mileage;
  String get vehicleName => '$make $model'.trim().isNotEmpty ? '$make $model' : registrationNumber;
  String get displayName => '$make $model ($registrationNumber)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'registrationNumber': registrationNumber.toUpperCase().trim(),
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'mileage': mileage,
      'vin': vin,
      'vehicleType': vehicleType,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map, String docId) {
    return VehicleModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      registrationNumber: (map['registrationNumber'] ?? '').toString().toUpperCase(),
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: (map['year'] as num?)?.toInt(),
      color: map['color'],
      mileage: (map['mileage'] as num?)?.toInt(),
      vin: map['vin'],
      vehicleType: map['vehicleType'] ?? 'Sedan',
      notes: map['notes'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  factory VehicleModel.fromSqlite(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as String,
      businessId: 'local',
      customerId: map['customer_id'] as String? ?? '',
      registrationNumber: (map['registration_number'] as String? ?? '').toUpperCase(),
      make: map['vehicle_name'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: int.tryParse(map['model_year']?.toString() ?? ''),
      color: map['color'] as String?,
      mileage: (map['current_odometer'] as num?)?.toInt() ?? 0,
      vin: '',
      vehicleType: 'Sedan',
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }


  VehicleModel copyWith({
    String? customerId,
    String? registrationNumber,
    String? make,
    String? model,
    int? year,
    String? color,
    int? mileage,
    String? vin,
    String? vehicleType,
    String? notes,
    List<String>? photoUrls,
    bool? isDeleted,
  }) {
    return VehicleModel(
      id: id,
      businessId: businessId,
      customerId: customerId ?? this.customerId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      mileage: mileage ?? this.mileage,
      vin: vin ?? this.vin,
      vehicleType: vehicleType ?? this.vehicleType,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
