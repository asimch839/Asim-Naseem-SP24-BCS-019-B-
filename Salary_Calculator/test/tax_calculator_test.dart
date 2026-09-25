import 'package:flutter_test/flutter_test.dart';
import 'package:salary_calculator/models/salary_model.dart';
import 'package:salary_calculator/utils/tax_calculator.dart';

void main() {
  group('TaxCalculator Unit Tests', () {
    test('Calculates zero tax for gross salary <= 50,000', () {
      const input = SalaryInput(
        basicSalary: 30000,
        houseRentAllowance: 10000,
        medicalAllowance: 5000,
        travelAllowance: 5000,
      );

      final result = TaxCalculator.calculate(
        input: input,
        mode: TaxCalculationMode.progressive,
      );

      expect(result.grossSalary, 50000.0);
      expect(result.taxDeduction, 0.0);
      expect(result.netMonthlyIncome, 50000.0);
    });

    test('Calculates 5% tax on amount above 50,000 (Tier 2)', () {
      const input = SalaryInput(
        basicSalary: 50000,
        houseRentAllowance: 15000,
        medicalAllowance: 5000,
        travelAllowance: 5000,
      );
      // Gross = 75,000. Tax = (75,000 - 50,000) * 0.05 = 1,250.
      final result = TaxCalculator.calculate(
        input: input,
        mode: TaxCalculationMode.progressive,
      );

      expect(result.grossSalary, 75000.0);
      expect(result.taxDeduction, 1250.0);
      expect(result.netMonthlyIncome, 73750.0);
    });

    test('Calculates Tier 3 tax (100k - 200k)', () {
      const input = SalaryInput(
        basicSalary: 100000,
        houseRentAllowance: 30000,
        medicalAllowance: 10000,
        travelAllowance: 10000,
      );
      // Gross = 150,000. Tax = 2500 + (150,000 - 100,000) * 0.10 = 2500 + 5000 = 7500.
      final result = TaxCalculator.calculate(
        input: input,
        mode: TaxCalculationMode.progressive,
      );

      expect(result.grossSalary, 150000.0);
      expect(result.taxDeduction, 7500.0);
      expect(result.netMonthlyIncome, 142500.0);
    });

    test('Calculates Flat Tax percentage mode correctly', () {
      const input = SalaryInput(
        basicSalary: 100000,
        houseRentAllowance: 20000,
        medicalAllowance: 0,
        travelAllowance: 0,
      );
      // Gross = 120,000. 10% flat tax = 12,000.
      final result = TaxCalculator.calculate(
        input: input,
        mode: TaxCalculationMode.flatPercentage,
        flatTaxRatePercent: 10.0,
      );

      expect(result.grossSalary, 120000.0);
      expect(result.taxDeduction, 12000.0);
      expect(result.netMonthlyIncome, 108000.0);
    });

    test('Formats currency with commas and decimals properly', () {
      expect(TaxCalculator.formatCurrency(1250.0), 'Rs. 1,250.00');
      expect(TaxCalculator.formatCurrency(83250.5), 'Rs. 83,250.50');
      expect(TaxCalculator.formatCurrency(1000000.0), 'Rs. 1,000,000.00');
      expect(TaxCalculator.formatCurrency(0.0), 'Rs. 0.00');
    });
  });
}
