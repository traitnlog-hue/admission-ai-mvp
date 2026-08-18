import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GACHI home renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GachiApp());
    await tester.pump();

    expect(find.text('나의 진학 준비'), findsOneWidget);
    expect(find.text('무료 진단'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('탐색'), findsOneWidget);
    expect(find.text('커뮤니티'), findsOneWidget);
    expect(find.text('코치'), findsOneWidget);
    expect(find.text('MY'), findsOneWidget);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 무엇을\n도와드릴까요?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('GACHI ADMISSION'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('GACHI ADMISSION'), findsOneWidget);

    await tester.tap(find.text('AI 챗봇'));
    await tester.pumpAndSettle();

    expect(find.text('GACHI AI'), findsOneWidget);
    await tester.tap(find.text('무료 진단 알려줘'));
    await tester.pump();
    expect(find.textContaining('국어·영어·수학'), findsOneWidget);
  });

  testWidgets('admission intake renders valid grade controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CoachAdmissionIntake()));
    await tester.pump();

    expect(find.text('GACHI 입시 전략 진단'), findsOneWidget);
    expect(find.text('현재 기록을 입력해 주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high school finder creates a recommendation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HighSchoolFinder()));

    await tester.tap(find.text('맞춤 환경 분석하기'));
    await tester.pump();

    expect(find.text('추천 고교 환경'), findsOneWidget);
    expect(find.textContaining('일반고'), findsOneWidget);
  });
}
