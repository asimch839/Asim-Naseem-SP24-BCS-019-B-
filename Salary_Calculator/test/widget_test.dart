import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salary_calculator/main.dart';

void main() {
  testWidgets('Salary calculator full user interaction test',
      (WidgetTester tester) async {
    // Set standard mobile screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Pump the app
    await tester.pumpWidget(const SalaryCalculatorApp());
    await tester.pumpAndSettle();

    // Verify Title and 4 required fields exist
    expect(find.text('Salary Calculator'), findsOneWidget);
    expect(find.text('Basic Salary'), findsOneWidget);
    expect(find.text('House Rent Allowance'), findsOneWidget);
    expect(find.text('Medical Allowance'), findsOneWidget);
    expect(find.text('Travel Allowance'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // 2. Tap Calculate while fields are empty to trigger validation
    final calculateBtn = find.text('Calculate');
    await tester.ensureVisible(calculateBtn);
    await tester.tap(calculateBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please enter Basic Salary'), findsOneWidget);
    expect(find.text('Please enter House Rent Allowance'), findsOneWidget);
    expect(find.text('Please enter Medical Allowance'), findsOneWidget);
    expect(find.text('Please enter Travel Allowance'), findsOneWidget);

    // 3. Enter values into the 4 fields
    final basicSalaryField = find.widgetWithText(TextFormField, 'Basic Salary');
    final houseRentField =
        find.widgetWithText(TextFormField, 'House Rent Allowance');
    final medicalField =
        find.widgetWithText(TextFormField, 'Medical Allowance');
    final travelField = find.widgetWithText(TextFormField, 'Travel Allowance');

    await tester.ensureVisible(basicSalaryField);
    await tester.enterText(basicSalaryField, '60000');
    await tester.enterText(houseRentField, '15000');
    await tester.enterText(medicalField, '5000');
    await tester.enterText(travelField, '5000');
    await tester.pumpAndSettle();

    // 4. Tap Calculate
    await tester.ensureVisible(calculateBtn);
    await tester.tap(calculateBtn);
    await tester.pumpAndSettle();

    // Verify Results:
    // Tax Deduction must be displayed first, then Net Monthly Income
    expect(find.text('Calculation Results'), findsOneWidget);
    expect(find.text('Tax Deduction'), findsWidgets);
    expect(find.text('Net Monthly Income'), findsWidgets);

    // Gross = 60000 + 15000 + 5000 + 5000 = 85,000.00
    // Tax under progressive: (85000 - 50000) * 0.05 = 1,750.00
    // Net Monthly Income = 85000 - 1750 = 83,250.00
    expect(find.text('Rs. 1,750.00'), findsWidgets);
    expect(find.text('Rs. 83,250.00'), findsWidgets);

    // Verify Tax Deduction appears before Net Monthly Income in the widget tree
    final taxDeductionFinder = find.text('Tax Deduction');
    final netIncomeFinder = find.text('Net Monthly Income');

    final taxOffset = tester.getTopLeft(taxDeductionFinder.first);
    final netIncomeOffset = tester.getTopLeft(netIncomeFinder.first);
    expect(
      taxOffset.dy,
      lessThan(netIncomeOffset.dy),
      reason: 'Tax Deduction must appear before Net Monthly Income',
    );

    // 5. Test Reset Button
    final resetBtn = find.text('Reset');
    await tester.ensureVisible(resetBtn);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    // Verify fields are cleared and results are removed
    expect(find.text('Calculation Results'), findsNothing);
  });
}
