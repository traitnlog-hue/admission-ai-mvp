import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/main.dart';

void main() {
  testWidgets('GACHI home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GachiApp());

    expect(find.text('나의 진학 준비'), findsOneWidget);
    expect(find.text('무료 진단'), findsOneWidget);
  });
}
