import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('KiwiApp loads dashboard screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const KiwiApp());
    expect(find.textContaining('secure your'), findsOneWidget);
  });
}
