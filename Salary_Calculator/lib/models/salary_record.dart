import 'salary_model.dart';

/// Represents a persistent salary calculation record stored in Hive
class SalaryRecord {
  final String id;
  final String title;
  final DateTime createdAt;
  final double basicSalary;
  final double houseRentAllowance;
  final double medicalAllowance;
  final double travelAllowance;
  final String taxMode; // 'progressive' or 'flatPercentage'
  final double flatTaxRatePercent;
  final double grossSalary;
  final double taxDeduction;
  final double netMonthlyIncome;
  final String taxDescription;

  const SalaryRecord({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.basicSalary,
    required this.houseRentAllowance,
    required this.medicalAllowance,
    required this.travelAllowance,
    required this.taxMode,
    required this.flatTaxRatePercent,
    required this.grossSalary,
    required this.taxDeduction,
    required this.netMonthlyIncome,
    required this.taxDescription,
  });

  /// Factory from SalaryResult and a user-provided label/title
  factory SalaryRecord.fromResult({
    required String id,
    required String title,
    required SalaryResult result,
    required TaxCalculationMode mode,
    required double flatRate,
    DateTime? createdAt,
  }) {
    return SalaryRecord(
      id: id,
      title: title.trim().isEmpty ? 'Salary Calculation' : title.trim(),
      createdAt: createdAt ?? DateTime.now(),
      basicSalary: result.input.basicSalary,
      houseRentAllowance: result.input.houseRentAllowance,
      medicalAllowance: result.input.medicalAllowance,
      travelAllowance: result.input.travelAllowance,
      taxMode: mode.name,
      flatTaxRatePercent: flatRate,
      grossSalary: result.grossSalary,
      taxDeduction: result.taxDeduction,
      netMonthlyIncome: result.netMonthlyIncome,
      taxDescription: result.taxDescription,
    );
  }

  /// Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'basicSalary': basicSalary,
      'houseRentAllowance': houseRentAllowance,
      'medicalAllowance': medicalAllowance,
      'travelAllowance': travelAllowance,
      'taxMode': taxMode,
      'flatTaxRatePercent': flatTaxRatePercent,
      'grossSalary': grossSalary,
      'taxDeduction': taxDeduction,
      'netMonthlyIncome': netMonthlyIncome,
      'taxDescription': taxDescription,
    };
  }

  /// Create from Map retrieved from Hive
  factory SalaryRecord.fromMap(Map<dynamic, dynamic> map) {
    return SalaryRecord(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Salary Calculation',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      basicSalary: (map['basicSalary'] as num?)?.toDouble() ?? 0.0,
      houseRentAllowance:
          (map['houseRentAllowance'] as num?)?.toDouble() ?? 0.0,
      medicalAllowance: (map['medicalAllowance'] as num?)?.toDouble() ?? 0.0,
      travelAllowance: (map['travelAllowance'] as num?)?.toDouble() ?? 0.0,
      taxMode: map['taxMode']?.toString() ?? 'progressive',
      flatTaxRatePercent:
          (map['flatTaxRatePercent'] as num?)?.toDouble() ?? 5.0,
      grossSalary: (map['grossSalary'] as num?)?.toDouble() ?? 0.0,
      taxDeduction: (map['taxDeduction'] as num?)?.toDouble() ?? 0.0,
      netMonthlyIncome: (map['netMonthlyIncome'] as num?)?.toDouble() ?? 0.0,
      taxDescription: map['taxDescription']?.toString() ?? '',
    );
  }

  /// Convert back to SalaryInput
  SalaryInput toSalaryInput() {
    return SalaryInput(
      basicSalary: basicSalary,
      houseRentAllowance: houseRentAllowance,
      medicalAllowance: medicalAllowance,
      travelAllowance: travelAllowance,
    );
  }

  /// Convert back to SalaryResult
  SalaryResult toSalaryResult() {
    return SalaryResult(
      input: toSalaryInput(),
      grossSalary: grossSalary,
      taxDeduction: taxDeduction,
      netMonthlyIncome: netMonthlyIncome,
      taxDescription: taxDescription,
    );
  }

  /// Tax mode enum
  TaxCalculationMode get calculationMode => taxMode == 'flatPercentage'
      ? TaxCalculationMode.flatPercentage
      : TaxCalculationMode.progressive;

  /// Effective tax rate percentage
  double get effectiveTaxRatePercent =>
      grossSalary > 0 ? (taxDeduction / grossSalary) * 100 : 0.0;
}
