import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shop_management_system/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileShopLabApp());
    expect(find.byType(MobileShopLabApp), findsOneWidget);
  });
}
