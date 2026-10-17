import '../../core/constants/app_constants.dart';

class StaffModel {
  final String id;
  final String businessId;
  final String name;
  final String? fatherName;
  final String? cnic;
  final String phone;
  final String? address;
  final DateTime joiningDate;
  final String designation;
  final double baseSalary;
  final String salaryType; // Monthly, Daily, Weekly, Commission, Mixed
  final double commissionRate; // e.g. 5% or 10%
  final String? photoUrl;
  final String status; // Active, Inactive, On Leave
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  StaffModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.fatherName,
    this.cnic,
    required this.phone,
    this.address,
    DateTime? joiningDate,
    required this.designation,
    double? baseSalary,
    double? basicSalary,
    this.salaryType = AppConstants.salaryTypeMonthly,
    this.commissionRate = 0.0,
    this.photoUrl,
    this.status = 'Active',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : baseSalary = baseSalary ?? basicSalary ?? 0.0,
        joiningDate = joiningDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get basicSalary => baseSalary;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'fatherName': fatherName,
      'cnic': cnic,
      'phone': phone,
      'address': address,
      'joiningDate': joiningDate.toIso8601String(),
      'designation': designation,
      'baseSalary': baseSalary,
      'salaryType': salaryType,
      'commissionRate': commissionRate,
      'photoUrl': photoUrl,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory StaffModel.fromMap(Map<String, dynamic> map, String docId) {
    return StaffModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      fatherName: map['fatherName'],
      cnic: map['cnic'],
      phone: map['phone'] ?? '',
      address: map['address'],
      joiningDate: map['joiningDate'] != null
          ? DateTime.tryParse(map['joiningDate']) ?? DateTime.now()
          : DateTime.now(),
      designation: map['designation'] ?? 'Detailer',
      baseSalary: (map['baseSalary'] as num?)?.toDouble() ?? 0.0,
      salaryType: map['salaryType'] ?? AppConstants.salaryTypeMonthly,
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'Active',
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  StaffModel copyWith({
    String? name,
    String? fatherName,
    String? cnic,
    String? phone,
    String? address,
    DateTime? joiningDate,
    String? designation,
    double? baseSalary,
    String? salaryType,
    double? commissionRate,
    String? photoUrl,
    String? status,
    String? notes,
    bool? isDeleted,
  }) {
    return StaffModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      joiningDate: joiningDate ?? this.joiningDate,
      designation: designation ?? this.designation,
      baseSalary: baseSalary ?? this.baseSalary,
      salaryType: salaryType ?? this.salaryType,
      commissionRate: commissionRate ?? this.commissionRate,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
