import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const user = SessionUser(name: '테스트 학생', email: 'trust@example.com');

  test('영수증 1건은 티켓 1매와 500P를 한 번만 지급한다', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await TrustWallet.issueReceiptReward(user, 'receipt-001'), isTrue);
    expect(await TrustWallet.issueReceiptReward(user, 'receipt-001'), isFalse);

    final status = await TrustWallet.load(user);
    expect(status.tickets, 1);
    expect(status.points, 500);
    expect(status.receiptCount, 1);
    expect(status.hasVerifiedReceipt, isTrue);

    expect(await TrustWallet.consumeTicket(user), isTrue);
    expect((await TrustWallet.load(user)).tickets, 0);
    expect(await TrustWallet.consumeTicket(user), isFalse);
  });

  test('갓성비 데모 후보는 월 30만 원 이하다', () {
    expect(valueAcademies, isNotEmpty);
    expect(valueAcademies.every((academy) => academy.monthlyFee <= 30), isTrue);
  });

  test('검수 대기 제보를 로컬 피드에 보존한다', () async {
    SharedPreferences.setMockInitialValues({});
    const report = LocalIntelReport(
      category: '비용',
      region: '강남',
      title: '익명 비용 제보',
      body: '직접 확인한 상담 내용을 검수 요청합니다.',
      proofStatus: '검수 대기',
      time: '방금',
    );

    await TrustWallet.addReport(report);
    final loaded = await TrustWallet.loadReports();
    expect(loaded, hasLength(1));
    expect(loaded.first.title, '익명 비용 제보');
  });
}
