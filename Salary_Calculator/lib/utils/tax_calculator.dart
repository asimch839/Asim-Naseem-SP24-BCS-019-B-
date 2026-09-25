import '../models/salary_model.dart';

class TaxCalculator {
  /// Calculate tax and net monthly income based on salary inputs
  static SalaryResult calculate({
    required SalaryInput input,
    TaxCalculationMode mode = TaxCalculationMode.progressive,
    double flatTaxRatePercent = 5.0,
  }) {
    final gross = input.grossSalary;
    double tax = 0.0;
    String taxDesc = '';

    if (mode == TaxCalculationMode.flatPercentage) {
      final rate = flatTaxRatePercent.clamp(0.0, 100.0);
      tax = gross * (rate / 100.0);
      taxDesc = 'Flat ${rate.toStringAsFixed(1)}% of Gross Salary';
    } else {
      // Standard Progressive Income Tax Slabs
      if (gross <= 50000) {
        tax = 0.0;
        taxDesc = '0% Tax (Gross Salary <= 50,000)';
      } else if (gross <= 100000) {
        tax = (gross - 50000) * 0.05;
        taxDesc = '5% on income above 50,000';
      } else if (gross <= 200000) {
        tax = 2500 + (gross - 100000) * 0.10;
        taxDesc = '2,500 + 10% on income above 100,000';
      } else {
        tax = 12500 + (gross - 200000) * 0.15;
        taxDesc = '12,500 + 15% on income above 200,000';
      }
    }

    // Ensure tax doesn't exceed gross
    if (tax > gross) {
      tax = gross;
    }

    final netIncome = gross - tax;

    return SalaryResult(
      input: input,
      grossSalary: gross,
      taxDeduction: tax,
      netMonthlyIncome: netIncome,
      taxDescription: taxDesc,
    );
  }

  /// Formats a numeric value into currency format (e.g. 50,000.00)
  static String formatCurrency(double amount, {String symbol = 'Rs. '}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formattedInt = integerPart.replaceAllMapped(regExp, (match) => ',');

    return '${isNegative ? '-' : ''}$symbol$formattedInt.$decimalPart';
  }
}
