part of 'main.dart';

const _paymentCheckoutUrl = String.fromEnvironment('PAYMENT_CHECKOUT_URL');

Future<void> openKakaoMapSearch(BuildContext context, String query) async {
  final encodedQuery = Uri.encodeComponent(query);
  final opened = await launchUrl(
    Uri.parse('https://map.kakao.com/link/search/$encodedQuery'),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카카오맵을 열 수 없습니다. 잠시 후 다시 시도해 주세요.')),
    );
  }
}

class KakaoMapPanel extends StatelessWidget {
  final String query;
  final int placeCount;

  const KakaoMapPanel({
    super.key,
    required this.query,
    required this.placeCount,
  });

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xffE2E6EE)),
    ),
    child: Column(
      children: [
        SizedBox(
          height: 142,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _MapGridPainter()),
              const Positioned(left: 48, top: 33, child: _MapPin(label: '1')),
              const Positioned(right: 76, top: 61, child: _MapPin(label: '2')),
              const Positioned(
                left: 150,
                bottom: 19,
                child: _MapPin(label: '3'),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Text(
                    '추천 $placeCount곳',
                    style: const TextStyle(color: text, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '추천 학원 위치 확인',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '카카오맵 검색 결과에서 위치와 이동 경로를 확인하세요.',
                      style: TextStyle(color: mute, fontSize: 10),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => openKakaoMapSearch(context, query),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffFEE500),
                  foregroundColor: const Color(0xff191919),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.map_outlined, size: 17),
                label: const Text('카카오맵'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapPin extends StatelessWidget {
  final String label;

  const _MapPin({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: const BoxDecoration(
      color: lime,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 7)],
    ),
    alignment: Alignment.center,
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
  );
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffEDF1E8),
    );
    final minor = Paint()
      ..color = const Color(0xffD5DDD0)
      ..strokeWidth = 1;
    for (double x = -30; x < size.width + 40; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x + 80, size.height), minor);
    }
    for (double y = 20; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 8), minor);
    }
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-10, size.height * .72),
      Offset(size.width + 10, size.height * .35),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .35, -10),
      Offset(size.width * .55, size.height + 10),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PremiumAdmissionOffer extends StatelessWidget {
  final Map<String, dynamic>? freeResult;

  const PremiumAdmissionOffer({super.key, this.freeResult});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('유료 정밀 입시 분석'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GACHI ADMISSION PRO',
                style: TextStyle(color: Color(0xffAFC5FF), fontSize: 10),
              ),
              const SizedBox(height: 9),
              Text(
                freeResult == null
                    ? '지원 전략을 더 깊고\n구체적으로 설계해요.'
                    : '${freeResult!['major']} 무료 진단을\n정밀 전략으로 확장해요.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '대학·전형별 비교, 학생부 보완 포인트, 4주 실행 로드맵을 한 번에 확인합니다.',
                style: TextStyle(
                  color: Color(0xffCAD4E6),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _PlanComparisonRow(title: '핵심 전략 진단', free: '제공', premium: '제공'),
        const _PlanComparisonRow(
          title: '대학·전형별 GAP',
          free: '요약',
          premium: '상세 비교',
        ),
        const _PlanComparisonRow(
          title: '학생부·세특 분석',
          free: '기본',
          premium: '항목별',
        ),
        const _PlanComparisonRow(title: '4주 실행 로드맵', free: '—', premium: '제공'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffDCE4F1)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '정밀 분석 1회',
                      style: TextStyle(color: mute, fontSize: 11),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '49,000원',
                      style: TextStyle(
                        color: text,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text('VAT 포함', style: TextStyle(color: mute, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                productName: 'GACHI 정밀 입시 분석',
                price: 49000,
                freeResult: freeResult,
              ),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
          ),
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('결제하고 정밀 분석 시작'),
        ),
        const SizedBox(height: 9),
        const Text(
          '실제 합격을 보장하는 서비스가 아니며, 최종 지원 판단은 해당 대학의 공식 모집요강을 확인해야 합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mute, fontSize: 10, height: 1.5),
        ),
      ],
    ),
  );
}

class _PlanComparisonRow extends StatelessWidget {
  final String title;
  final String free;
  final String premium;

  const _PlanComparisonRow({
    required this.title,
    required this.free,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    margin: const EdgeInsets.only(bottom: 7),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(title, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Text(
            free,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mute, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            premium,
            textAlign: TextAlign.center,
            style: const TextStyle(color: lime, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class PaymentPage extends StatefulWidget {
  final String productName;
  final int price;
  final Map<String, dynamic>? freeResult;

  const PaymentPage({
    super.key,
    required this.productName,
    required this.price,
    this.freeResult,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = '카드';
  bool agreed = false;
  bool processing = false;

  String get formattedPrice {
    final digits = widget.price.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '$buffer원';
  }

  Future<void> _pay() async {
    if (!agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 조건과 개인정보 처리 안내에 동의해 주세요.')),
      );
      return;
    }
    setState(() => processing = true);
    final orderId = 'GACHI-${DateTime.now().millisecondsSinceEpoch}';

    if (_paymentCheckoutUrl.isNotEmpty) {
      final uri = Uri.parse(_paymentCheckoutUrl).replace(
        queryParameters: {
          'orderId': orderId,
          'orderName': widget.productName,
          'amount': widget.price.toString(),
          'method': method,
        },
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('결제창을 열 수 없습니다.')));
      }
      if (mounted) setState(() => processing = false);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테스트 결제 확인'),
        content: Text(
          '$method 방식으로 $formattedPrice 테스트 결제를 완료할까요?\n\n운영 가맹점 키가 연결되기 전에는 실제 금액이 청구되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('테스트 결제 완료'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      setState(() => processing = false);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('gachi.purchase.admission_pro', true);
    await preferences.setString('gachi.purchase.last_order', orderId);
    if (!mounted) return;
    setState(() => processing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumAdmissionReport(
          orderId: orderId,
          freeResult: widget.freeResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('결제'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        if (_paymentCheckoutUrl.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xffFFF4D4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '테스트 결제 모드입니다. 운영 결제 URL이 설정되기 전에는 실제 금액이 청구되지 않습니다.',
              style: TextStyle(
                color: Color(0xff705600),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(color: text),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '디지털 분석 리포트',
                      style: TextStyle(color: mute, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                formattedPrice,
                style: const TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '결제 수단',
          style: TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        RadioGroup<String>(
          groupValue: method,
          onChanged: (value) {
            if (value != null) setState(() => method = value);
          },
          child: Column(
            children: ['카드', '카카오페이', '계좌이체']
                .map(
                  (item) => RadioListTile<String>(
                    value: item,
                    selected: method == item,
                    title: Text(item),
                    secondary: Icon(
                      item == '카드'
                          ? Icons.credit_card_rounded
                          : item == '카카오페이'
                          ? Icons.account_balance_wallet_outlined
                          : Icons.account_balance_outlined,
                    ),
                    tileColor: surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: agreed,
          onChanged: (value) => setState(() => agreed = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            '구매 조건, 환불 정책 및 개인정보 처리 안내에 동의합니다.',
            style: TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: processing ? null : _pay,
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
          ),
          child: Text(processing ? '결제 준비 중...' : '$formattedPrice 결제하기'),
        ),
      ],
    ),
  );
}

class PremiumAdmissionReport extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic>? freeResult;

  const PremiumAdmissionReport({
    super.key,
    required this.orderId,
    this.freeResult,
  });

  @override
  Widget build(BuildContext context) {
    final targetId = freeResult?['targetId'] as String? ?? 'sky';
    final target = admissionTargetById(targetId);
    final major = freeResult?['major'] ?? target.title;
    final coreSubjects = target.coreSubjects.take(3).join('·');
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(backgroundColor: mist, title: const Text('정밀 분석 리포트')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xffEAF8F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xff168A73)),
                SizedBox(width: 10),
                Expanded(child: Text('테스트 결제가 완료되어 정밀 분석이 열렸습니다.')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$major 4주 실행 로드맵',
            style: const TextStyle(
              color: text,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffDCE4F1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '목표군 정밀 점검 항목',
                  style: TextStyle(color: text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 9),
                ...target.premiumChecks.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: lime,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _PremiumWeek(
            week: '1주차',
            title: '${target.title} 전형 GAP 정리',
            body: '대학별 전형요소와 현재 내신·모의고사·학생부의 차이를 표로 정리합니다.',
          ),
          _PremiumWeek(
            week: '2주차',
            title: '핵심 교과·선택과목 점검',
            body: '$coreSubjects 성취 추이와 전공 연계 과목 이수를 점검하고 보완 순서를 정합니다.',
          ),
          _PremiumWeek(
            week: '3주차',
            title: '학생부·면접 근거 강화',
            body:
                '${target.evaluationFocus.take(3).join('·')} 항목을 기준으로 활동 근거와 답변 구조를 보완합니다.',
          ),
          _PremiumWeek(
            week: '4주차',
            title: '지원 조합·일정 확정',
            body:
                '${target.routes.join('·')} 조합을 안정·적정·도전으로 나누고 최종 모집요강 확인 일정을 확정합니다.',
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('전문가 검토 요청'),
                content: const Text(
                  'MVP에서는 요청이 접수된 것으로 표시합니다. 운영 버전에서는 상담 일정 시스템과 연결됩니다.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('전문가 검토 요청'),
          ),
          const SizedBox(height: 10),
          Text(
            '주문번호 $orderId',
            textAlign: TextAlign.center,
            style: const TextStyle(color: mute, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _PremiumWeek extends StatelessWidget {
  final String week;
  final String title;
  final String body;

  const _PremiumWeek({
    required this.week,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(week, style: const TextStyle(color: lime, fontSize: 10)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: mute, fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
