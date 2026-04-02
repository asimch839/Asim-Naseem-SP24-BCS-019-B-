import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/main.dart';

void main() {
  testWidgets('App launches and shows HomeScreen', (WidgetTester tester) async {
    // Build your TaskManagerApp
    await tester.pumpWidget(
      const TaskManagerApp(),
    );

    // Wait for the frame to settle
    await tester.pumpAndSettle();

    // Verify that HomeScreen is displayed by checking for some text/widget
    expect(find.text('Task Manager'), findsOneWidget);

    // You can also check for the FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
