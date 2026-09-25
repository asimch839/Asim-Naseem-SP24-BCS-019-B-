/// Data model holding the salary inputs
class SalaryInput {
  final double basicSalary;
  final double houseRentAllowance;
  final double medicalAllowance;
  final double travelAllowance;

  const SalaryInput({
    required this.basicSalary,
    required this.houseRentAllowance,
    required this.medicalAllowance,
    required this.travelAllowance,
  });

  double get grossSalary =>
      basicSalary + houseRentAllowance + medicalAllowance + travelAllowance;

  double get totalAllowances =>
      houseRentAllowance + medicalAllowance + travelAllowance;
}

/// Tax calculation mode
enum TaxCalculationMode {
  progressive('Progressive Slabs (Recommended)'),
  flatPercentage('Flat Percentage');

  final String label;
  const TaxCalculationMode(this.label);
}

/// Data model holding the calculation result
class SalaryResult {
  final SalaryInput input;
  final double grossSalary;
  final double taxDeduction;
  final double netMonthlyIncome;
  final String taxDescription;

  const SalaryResult({
    required this.input,
    required this.grossSalary,
    required this.taxDeduction,
    required this.netMonthlyIncome,
    required this.taxDescription,
  });
}
