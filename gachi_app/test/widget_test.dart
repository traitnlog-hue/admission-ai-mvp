import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('login gate supports guest entry', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GachiApp());
    await tester.pumpAndSettle();

    expect(find.text('다시 만나서\n반가워요.'), findsOneWidget);
    await tester.tap(find.text('로그인 없이 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.text('나의 진학 준비'), findsOneWidget);
  });

  testWidgets('GACHI home renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'gachi.auth.signed_in': true,
      'gachi.auth.name': '테스트 학생',
      'gachi.auth.email': 'student@example.com',
    });
    await tester.pumpWidget(const GachiApp());
    await tester.pumpAndSettle();

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

    await tester.scrollUntilVisible(find.text('무료 입시 분석 시작'), 250);
    await tester.tap(find.text('무료 입시 분석 시작'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('무료 분석 결과'), findsOneWidget);
  });

  testWidgets('SKY strategy hub creates a free readiness report', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdmissionStrategyHub()));

    expect(find.text('SKY'), findsWidgets);
    expect(find.text('서울대·연세대·고려대'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('SKY 무료 준비도 진단'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('SKY 무료 준비도 진단'));
    await tester.pumpAndSettle();

    expect(find.text('SKY 무료 진단'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('무료 전략 분석 결과 보기'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('무료 전략 분석 결과 보기'));
    await tester.pumpAndSettle();

    expect(find.text('SKY\n준비도 리포트'), findsOneWidget);
    expect(find.text('추천 전략 방향'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('PRO 정밀 분석 이어가기'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('PRO 정밀 분석 이어가기'), findsOneWidget);
  });

  testWidgets('의치한약수 목표군이 의료계열 전략을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdmissionStrategyHub(initialTargetId: 'medical')),
    );

    expect(find.text('의치한약수'), findsWidgets);
    expect(find.text('의·치·한·약·수의'), findsOneWidget);
    expect(find.textContaining('수능최저'), findsWidgets);
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

  testWidgets('academy recommendations include Kakao Map actions', (
    WidgetTester tester,
  ) async {
    const profile = AcademyStudentProfile(
      name: '테스트 학생',
      region: '서울 강남구',
      school: '테스트고',
      grade: '고2',
      subjects: ['수학'],
      level: '개념은 안정적, 심화 보완 필요',
      academyCondition: '통학 30분 이내',
    );
    await tester.pumpWidget(
      const MaterialApp(home: AcademyMatchResult(profile: profile)),
    );

    expect(find.text('추천 학원 위치 확인'), findsOneWidget);
    expect(find.text('카카오맵'), findsOneWidget);
    expect(find.text('카카오맵에서 위치 보기'), findsWidgets);
  });

  testWidgets('free admission result connects to premium checkout', (
    WidgetTester tester,
  ) async {
    final result = <String, dynamic>{
      'major': '컴퓨터공학부',
      'primary_strategy': '정시 중심 전략',
      'primary_reason': '모의고사 경쟁력이 안정적입니다.',
      'secondary_strategy': '학생부종합 병행 전략',
      'secondary_reason': '탐구 활동을 보완하세요.',
      'scores': [
        {'label': '학업역량', 'value': 82},
        {'label': '수능역량', 'value': 86},
      ],
      'risks': ['수능최저를 확인하세요.'],
      'action_plan': '이번 주 오답을 정리하세요.',
      'offline': true,
    };
    await tester.pumpWidget(
      MaterialApp(home: CoachAdmissionResult(data: result)),
    );

    await tester.scrollUntilVisible(find.text('유료 정밀 분석 비교하기'), 250);
    await tester.tap(find.text('유료 정밀 분석 비교하기'));
    await tester.pumpAndSettle();

    expect(find.text('GACHI ADMISSION PRO'), findsOneWidget);
    expect(find.text('결제하고 정밀 분석 시작'), findsOneWidget);
  });

  testWidgets('test checkout unlocks premium report', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: PaymentPage(productName: 'GACHI 정밀 입시 분석', price: 49000),
      ),
    );

    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.text('49,000원 결제하기'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('테스트 결제 확인'), findsOneWidget);

    await tester.tap(find.text('테스트 결제 완료'));
    await tester.pumpAndSettle();
    expect(find.text('정밀 분석 리포트'), findsOneWidget);
    expect(find.textContaining('4주 실행 로드맵'), findsOneWidget);
  });
}
