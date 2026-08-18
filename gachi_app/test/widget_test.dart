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
    expect(find.text('Google로 계속하기'), findsOneWidget);
    await tester.tap(find.text('로그인 없이 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.text('나의 진학 준비'), findsOneWidget);
  });

  testWidgets('상단 알림과 마이페이지 버튼이 실제 화면을 연다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Shell(
          user: SessionUser(
            name: '체험 학생',
            email: 'guest@gachi.local',
            isGuest: true,
            authProvider: 'guest',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header-notifications-button')));
    await tester.pumpAndSettle();
    expect(find.text('2026 입시 인사이트가 업데이트됐어요'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('header-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('체험 학생'), findsOneWidget);
    expect(find.text('결제 및 컨설팅 내역'), findsOneWidget);
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
    expect(find.text('30만 원 이하 학원,\n인증 후기와 함께 찾기'), findsOneWidget);
    expect(find.text('학생 정보 등록'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('무료 진단'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
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

  testWidgets('3초 비상구가 가입 없이 조합 리포트를 만든다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuickEscapeDiagnosis()));

    expect(find.text('학년과 고민만\n고르면 됩니다.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3초 리포트 보기'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -90));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3초 리포트 보기'));
    await tester.pump();

    expect(find.text('개념 소수정예 + 1:1 오답 클리닉'), findsOneWidget);
    expect(find.text('상담 전 꼭 확인'), findsOneWidget);
  });

  testWidgets('갓성비 맵이 예산과 카카오맵 동선을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ValueAcademyMapPage()));

    expect(find.text('갓성비 학원·강사 맵'), findsOneWidget);
    expect(find.text('30만원'), findsOneWidget);
    expect(find.text('카카오맵'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('월 19만'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('월 19만'), findsWidgets);
  });

  testWidgets('게스트에게 회원·영수증 티켓 게이트를 안내한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MemberReceiptGatePage(featureName: '무료 대입전략 진단')),
    );

    expect(find.textContaining('인증 회원 전용'), findsOneWidget);
    expect(find.text('영수증 1건당 대입전략 또는 고교탐색 1회'), findsOneWidget);
    expect(find.text('회원가입·로그인하기'), findsOneWidget);
  });

  testWidgets('인증 회원이 티켓을 사용하면 진단으로 이동한다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    const user = SessionUser(name: '티켓 학생', email: 'ticket@example.com');
    await TrustWallet.issueReceiptReward(user, 'receipt-ticket-test');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => openTicketProtectedFeature(
                context: context,
                user: user,
                featureName: '무료 고교탐색 진단',
                destination: const Scaffold(body: Text('보호된 진단 화면')),
              ),
              child: const Text('진단 열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('진단 열기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('티켓 1매를 사용'), findsOneWidget);
    await tester.tap(find.text('티켓 사용하고 시작'));
    await tester.pumpAndSettle();
    expect(find.text('보호된 진단 화면'), findsOneWidget);
    expect((await TrustWallet.load(user)).tickets, 0);
  });

  testWidgets('영수증 인증 화면이 이미지·후기·보상을 안내한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReceiptVerificationPage(
          user: SessionUser(name: '인증 학생', email: 'proof@example.com'),
        ),
      ),
    );

    expect(find.text('영수증·성적표 인증'), findsOneWidget);
    expect(find.text('영수증 1건 = 진단 티켓 1매'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('이미지 선택'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('이미지 선택'), findsOneWidget);
  });

  testWidgets('메인 영수증 티켓이 펼쳐지는 애니메이션을 표시한다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrustWalletCard(
            user: SessionUser(
              name: '체험 학생',
              email: 'guest@gachi.local',
              isGuest: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('receipt-ticket-animation')), findsOneWidget);
    expect(find.byKey(const Key('receipt-ticket-paper')), findsOneWidget);
    expect(find.text('인증 회원 진단 티켓'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('리얼 제보 피드가 검수 정책과 데모 신호를 보여준다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Community(
            user: SessionUser(
              name: '체험 학생',
              email: 'guest@gachi.local',
              isGuest: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('리얼 제보 · 핫딜'), findsOneWidget);
    expect(find.textContaining('검수 전 학원명'), findsOneWidget);
    expect(find.textContaining('MVP 데모'), findsWidgets);
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
        home: PaymentPage(
          productName: 'GACHI 정밀 입시 분석',
          price: 49000,
          forceTestMode: true,
        ),
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
