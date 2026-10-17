class ServiceRecordModel {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String vehicleId;
  final String carName;
  final int? modelYear;
  final String vehicleNumber;
  final String service;
  final DateTime serviceDate;
  final DateTime? deliveryDate;
  final int odometerKm;
  final double serviceAmount;
  final String? technician;
  final String? notes;
  final DateTime createdAt;

  ServiceRecordModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.vehicleId,
    required this.carName,
    this.modelYear,
    required this.vehicleNumber,
    required this.service,
    DateTime? serviceDate,
    this.deliveryDate,
    this.odometerKm = 0,
    required this.serviceAmount,
    this.technician,
    this.notes,
    DateTime? createdAt,
  })  : serviceDate = serviceDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'vehicleId': vehicleId,
      'carName': carName,
      'modelYear': modelYear,
      'vehicleNumber': vehicleNumber.toUpperCase().trim(),
      'service': service,
      'serviceDate': serviceDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'odometerKm': odometerKm,
      'serviceAmount': serviceAmount,
      'technician': technician,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceRecordModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceRecordModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      carName: map['carName'] ?? '',
      modelYear: (map['modelYear'] as num?)?.toInt(),
      vehicleNumber: (map['vehicleNumber'] ?? '').toString().toUpperCase(),
      service: map['service'] ?? '',
      serviceDate: map['serviceDate'] != null
          ? DateTime.tryParse(map['serviceDate']) ?? DateTime.now()
          : DateTime.now(),
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.tryParse(map['deliveryDate'])
          : null,
      odometerKm: (map['odometerKm'] as num?)?.toInt() ?? 0,
      serviceAmount: (map['serviceAmount'] as num?)?.toDouble() ?? 0.0,
      technician: map['technician'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
