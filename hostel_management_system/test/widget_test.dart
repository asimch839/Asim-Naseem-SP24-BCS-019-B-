import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management_system/main.dart';

void main() {
  testWidgets('Hostel Management App initial load test', (WidgetTester tester) async {
    await tester.pumpWidget(const HostelManagementApp());
    expect(find.byType(HostelManagementApp), findsOneWidget);
  });
}

