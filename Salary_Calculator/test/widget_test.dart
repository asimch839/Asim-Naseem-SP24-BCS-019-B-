import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:salary_calculator/main.dart';
import 'package:salary_calculator/services/salary_storage_service.dart';
import 'package:salary_calculator/widgets/modern_bottom_nav_bar.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('salary_hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(SalaryStorageService.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Salary calculator full user interaction test',
      (WidgetTester tester) async {
    // Set standard mobile screen size
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    // 1. Pump the app
    await tester.pumpWidget(const SalaryCalculatorApp());
    await tester.pumpAndSettle();

    // Verify Title and input fields exist
    expect(find.text('Salary Pro'), findsOneWidget);
    expect(find.text('Basic Salary'), findsOneWidget);
    expect(find.text('House Rent Allowance (HRA)'), findsOneWidget);
    expect(find.text('Medical Allowance'), findsOneWidget);
    expect(find.text('Travel Allowance'), findsOneWidget);
    expect(find.text('Calculate Salary'), findsOneWidget);

    // 2. Tap Calculate while fields are empty to trigger validation
    final calculateBtn =
        find.widgetWithText(ElevatedButton, 'Calculate Salary');
    debugPrint('NAVBAR RECT: ${tester.getRect(find.byType(ModernBottomNavBar))}');
    debugPrint('BUTTON RECT: ${tester.getRect(calculateBtn)}');
    final hitResult = tester.hitTestOnBinding(const Offset(270, 800));
    for (final entry in hitResult.path) {
      debugPrint('HIT: ${entry.target.runtimeType}');
    }
    await tester.tap(calculateBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Please enter Basic Salary'), findsOneWidget);
    expect(find.text('Please enter House Rent Allowance (HRA)'), findsOneWidget);
    expect(find.text('Please enter Medical Allowance'), findsOneWidget);
    expect(find.text('Please enter Travel Allowance'), findsOneWidget);

    // 3. Enter values into the 4 fields
    final basicSalaryField = find.widgetWithText(TextFormField, 'Basic Salary');
    final houseRentField =
        find.widgetWithText(TextFormField, 'House Rent Allowance (HRA)');
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
    await tester.tap(calculateBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Results:
    // Tax Deduction must be displayed first, then Net Monthly Income
    expect(find.text('Calculation Results'), findsOneWidget);
    expect(find.text('Tax Deduction'), findsWidgets);
    expect(find.text('Net Monthly Income'), findsWidgets);
    expect(find.text('Salary Circle Graph'), findsOneWidget);

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

    // 5. Verify Circle Graph tab navigation
    final circleTab = find.text('Circle Graph');
    await tester.tap(circleTab);
    await tester.pumpAndSettle();
    expect(find.text('Distribution Analytics'), findsOneWidget);
    expect(find.text('Financial Ratios & Metrics'), findsOneWidget);

    // 6. Verify History tab navigation
    final historyTab = find.text('History');
    await tester.tap(historyTab);
    await tester.pumpAndSettle();
    expect(find.text('Calculation History'), findsOneWidget);

    // 7. Switch back to Calculator tab
    final calcTab = find.text('Calculator');
    await tester.tap(calcTab);
    await tester.pumpAndSettle();

    // 8. Test Clear Button
    final clearBtn = find.text('Clear');
    await tester.ensureVisible(clearBtn);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Verify fields are cleared and results are removed
    expect(find.text('Calculation Results'), findsNothing);
  });

  testWidgets('Responsive layout test across mobile, tablet, and laptop viewports with saved records',
      (WidgetTester tester) async {
    // 1. Mobile narrow viewport (e.g. iPhone SE / small Android - 360 logical width)
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const SalaryCalculatorApp());
    await tester.pumpAndSettle();

    // Fill in values and calculate
    final basicSalaryField = find.widgetWithText(TextFormField, 'Basic Salary');
    final houseRentField =
        find.widgetWithText(TextFormField, 'House Rent Allowance (HRA)');
    final medicalField =
        find.widgetWithText(TextFormField, 'Medical Allowance');
    final travelField = find.widgetWithText(TextFormField, 'Travel Allowance');

    await tester.enterText(basicSalaryField, '75000');
    await tester.enterText(houseRentField, '20000');
    await tester.enterText(medicalField, '8000');
    await tester.enterText(travelField, '7000');
    await tester.pumpAndSettle();

    final calculateBtn =
        find.widgetWithText(ElevatedButton, 'Calculate Salary');
    await tester.tap(calculateBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Save button exists and tap it
    final saveBtn = find.text('Save');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify it changed to 'Saved'
    expect(find.text('Saved'), findsOneWidget);

    // Switch to History screen
    final historyTab = find.text('History');
    await tester.tap(historyTab);
    await tester.pumpAndSettle();

    // Verify Calculation History header and record card are rendered without overflow
    expect(find.text('Calculation History'), findsOneWidget);
    expect(find.text('Take-Home Pay'), findsWidgets);
    expect(find.text('Tax Deducted'), findsWidgets);
    expect(find.text('Gross Total'), findsWidgets);

    // 2. iPad / Tablet viewport (768 width)
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    await tester.pumpAndSettle();
    expect(find.text('Calculation History'), findsOneWidget);

    // 3. Laptop / Desktop viewport (1440 width)
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpAndSettle();
    expect(find.text('Calculation History'), findsOneWidget);
  });
}
