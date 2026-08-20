part of 'main.dart';

const _paymentCheckoutUrl = String.fromEnvironment('PAYMENT_CHECKOUT_URL');
const _storeProductId = String.fromEnvironment(
  'STORE_PRODUCT_ID',
  defaultValue: 'gachi_admission_pro',
);
const _purchaseVerificationUrl = String.fromEnvironment(
  'PURCHASE_VERIFICATION_URL',
);

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

class PremiumAdmissionOffer extends StatefulWidget {
  final Map<String, dynamic>? freeResult;
  final ConsultantProfile? consultant;

  const PremiumAdmissionOffer({super.key, this.freeResult, this.consultant});

  @override
  State<PremiumAdmissionOffer> createState() => _PremiumAdmissionOfferState();
}

class _PremiumAdmissionOfferState extends State<PremiumAdmissionOffer> {
  final selectedPrograms = <String>{'입시전략 분석 리포트'};
  String selectedGrade = '전체';

  static const programs = <_ConsultingProgram>[
    _ConsultingProgram(
      title: '고교선택·고입 전략 컨설팅',
      recommendedFor: '중1~중3 1학기',
      grades: ['중1', '중2', '중3'],
      sessionInfo: 'MVP 기본 구성 · 회당 60분 · 총 1회',
      price: 39000,
      summary: '특목·자사고를 포함한 고교 선택과 지원 전략을 세워요.',
      detail: '학생의 성향과 목표를 바탕으로 고교 선택 기준과 지원 전략을 정리합니다.',
      deliverables: ['고교 선택 기준', '지원 전략 요약', '준비 체크리스트'],
      siteUrl: 'https://consulting-kisae.com/high',
    ),
    _ConsultingProgram(
      title: '특목·자사 1% 자소서·면접 컨설팅',
      recommendedFor: '중3 여름방학 이후',
      grades: ['중3'],
      sessionInfo: 'MVP 기본 구성 · 회당 60분 · 총 4회',
      price: 79000,
      summary: '자소서 소재 설계부터 예상 질문·답변 연습까지 1:1로 준비해요.',
      detail: '문항별 소재를 설계·완성하고, 지원 학교 기준 예상 질문과 답변을 연습합니다.',
      deliverables: ['문항별 소재 설계', '자소서 피드백', '면접 예상 질문'],
    ),
    _ConsultingProgram(
      title: '1% 관리형 컨설팅',
      recommendedFor: '고1~고3 학기 중',
      grades: ['고1', '고2', '고3'],
      sessionInfo: 'MVP 기본 구성 · 회당 60분 · 총 8회',
      price: 99000,
      summary: '학교생활·생기부를 초기부터 관리하고 상시 피드백을 제공해요.',
      detail: '한 학기 커리큘럼과 채팅방 기반 상시 관리로 활동의 일관성과 생기부 완성도를 높입니다.',
      deliverables: ['학기 커리큘럼', '채팅방 기반 점검', '생기부 활동 관리'],
      siteUrl: 'https://consulting-kisae.com/1percent',
    ),
    _ConsultingProgram(
      title: '입시전략 분석 리포트',
      recommendedFor: '고2 방학',
      grades: ['고2'],
      sessionInfo: 'MVP 기본 구성 · 회당 90분 · 총 1회',
      price: 49000,
      summary: '내신·모의고사·세특을 분석해 목표 대학과 실행 로드맵을 설정해요.',
      detail: '성적과 학생부 기록을 함께 분석해 목표 대학의 방향과 실행 우선순위를 제안합니다.',
      deliverables: ['입시전략 분석', '목표 대학 방향', '실행 로드맵'],
      siteUrl: 'https://consulting-kisae.com/pass',
    ),
    _ConsultingProgram(
      title: '생기부 전략 컨설팅',
      recommendedFor: '고2 후반~고3 초',
      grades: ['고2', '고3'],
      sessionInfo: 'MVP 기본 구성 · 회당 90분 · 총 2회',
      price: 69000,
      summary: '목표 대학에 맞춘 생기부 스토리라인과 세특·활동 전략을 설계해요.',
      detail: '목표 대학의 평가 관점에 맞춰 학생부의 스토리라인과 다음 활동 방향을 구체화합니다.',
      deliverables: ['생기부 스토리라인', '세특 전략', '활동 우선순위'],
      siteUrl: 'https://consulting-kisae.com/roadmap',
    ),
    _ConsultingProgram(
      title: '수시 컨설팅',
      recommendedFor: '고3 1~7월',
      grades: ['고3'],
      sessionInfo: 'MVP 기본 구성 · 회당 90분 · 총 2회',
      price: 79000,
      summary: '학생부 보완과 지원 방향 확정, 수시 원서 전략을 준비해요.',
      detail: '수시 전형별 지원 방향을 정리하고, 원서 전 준비해야 할 자료와 판단 기준을 점검합니다.',
      deliverables: ['수시 지원 전략', '원서 준비 체크리스트', '지원 우선순위'],
      siteUrl: 'https://consulting-kisae.com/blog',
    ),
    _ConsultingProgram(
      title: '결과 후 보완 컨설팅',
      recommendedFor: '고3 8~12월',
      grades: ['고3'],
      sessionInfo: 'MVP 기본 구성 · 회당 60분 · 총 2회',
      price: 39000,
      summary: '수시 결과 이후에도 학생부·지원 관련 보완을 이어가요.',
      detail:
          '관리형 상담을 바탕으로 결과 이후의 보완 과제를 정리합니다. 자기소개서 컨설팅은 과거형 안내로 별도 검토가 필요합니다.',
      deliverables: ['결과 후 보완 과제', '지원 상태 점검', '다음 단계 안내'],
    ),
    _ConsultingProgram(
      title: '정시 컨설팅',
      recommendedFor: '고3 12월~1월',
      grades: ['고3'],
      sessionInfo: 'MVP 기본 구성 · 회당 90분 · 총 1회',
      price: 79000,
      summary: '정시 지원 전략을 세우고 최종 대학·학과 선택을 돕습니다.',
      detail: '수능 성적과 모집 요강을 바탕으로 지원 가능한 대학·학과의 조합과 우선순위를 정리합니다.',
      deliverables: ['정시 지원 전략', '대학·학과 조합', '최종 지원 우선순위'],
    ),
  ];

  List<_ConsultingProgram> get chosen => programs
      .where((program) => selectedPrograms.contains(program.title))
      .toList();
  List<_ConsultingProgram> get visiblePrograms => selectedGrade == '전체'
      ? programs
      : programs
            .where((program) => program.grades.contains(selectedGrade))
            .toList();
  int get totalPrice =>
      chosen.fold(0, (total, program) => total + program.price);
  String _formatWon(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',')}원';

  Future<void> _startMatchingCheckout(BuildContext context) async {
    final ready = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConsultantMatchingBriefPage()),
    );
    if (ready != true || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          productName: '컨설턴트 매칭 상담권 (최대 3명)',
          price: 9900,
          paymentItems: const ['컨설턴트 매칭 상담권 · 최대 3명'],
          freeResult: widget.freeResult,
          forceTestMode: _paymentCheckoutUrl.isEmpty,
          afterPayment: (orderId) => PaidConsultantMatchingPage(
            matchOrderId: orderId,
            freeResult: widget.freeResult,
            studentBriefReady: true,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchStart(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('유료 입시 컨설팅'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const _ConsultingJourneyStepBar(activeStep: 1),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GACHI CONSULTING FLOW',
                style: TextStyle(
                  color: Color(0xffAFC5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '먼저 상담 성향을 확인하고\n나에게 맞는 컨설턴트를 만나요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '결제 후 컨설턴트를 직접 선택하고, 채팅 상담을 통해 필요한 프로그램만 고를 수 있어요.',
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
        const _JourneyGuideRow(
          number: '1',
          title: '매칭 상담 신청 결제',
          body: '학생부·학습 성향을 먼저 확인한 뒤, 최대 3명과 상담할 수 있는 상담권을 결제해요.',
        ),
        const _JourneyGuideRow(
          number: '2',
          title: '컨설턴트 선택 · 채팅 상담',
          body: '전문 분야와 소개를 보고 선택한 뒤, 채팅으로 우선 고민을 정리해요.',
        ),
        const _JourneyGuideRow(
          number: '3',
          title: '맞춤 프로그램 선택 · 결제',
          body: '상담 후 필요한 프로그램만 골라 최종 결제해요.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _startMatchingCheckout(context),
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
          ),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('최대 3명 매칭 상담권 결제 · 9,900원'),
        ),
        const SizedBox(height: 8),
        const Text(
          '상담권 1건으로 서로 다른 컨설턴트 최대 3명과 채팅 상담할 수 있습니다. 현재는 테스트 결제이며 실제 청구되지 않습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mute, fontSize: 10, height: 1.45),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.consultant == null) return _buildMatchStart(context);
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text('유료 정밀 입시 분석'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _ConsultingJourneyStepBar(activeStep: 3),
          const SizedBox(height: 14),
          _SelectedConsultantBanner(consultant: widget.consultant!),
          const SizedBox(height: 14),
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
                  widget.freeResult == null
                      ? '지원 전략을 더 깊고\n구체적으로 설계해요.'
                      : '${widget.freeResult!['major']} 무료 진단을\n정밀 전략으로 확장해요.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '필요한 프로그램만 선택해 나만의 입시 컨설팅 구성을 만들어요.',
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
          const Text(
            '원하는 프로그램 선택',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '프로그램별 상세 내용은 보기 버튼에서 확인할 수 있어요.',
            style: TextStyle(color: mute, fontSize: 10),
          ),
          const SizedBox(height: 12),
          const Text(
            '학년별로 보기',
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: ['전체', '중1', '중2', '중3', '고1', '고2', '고3']
                .map(
                  (grade) => ChoiceChip(
                    label: Text(grade),
                    selected: selectedGrade == grade,
                    selectedColor: lavender,
                    checkmarkColor: lime,
                    onSelected: (_) => setState(() => selectedGrade = grade),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          if (visiblePrograms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                '선택한 학년의 프로그램을 준비 중이에요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 11),
              ),
            )
          else
            ...visiblePrograms.map(
              (program) => _ConsultingProgramCard(
                program: program,
                selected: selectedPrograms.contains(program.title),
                onChanged: (selected) => setState(() {
                  if (selected) {
                    selectedPrograms.add(program.title);
                  } else {
                    selectedPrograms.remove(program.title);
                  }
                }),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffDCE4F1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${chosen.length}개 프로그램 선택',
                        style: const TextStyle(color: mute, fontSize: 11),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatWon(totalPrice),
                        style: const TextStyle(
                          color: text,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'MVP 검토 가격 · VAT 포함',
                  style: TextStyle(color: mute, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: chosen.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(
                        productName: chosen
                            .map((program) => program.title)
                            .join(' + '),
                        price: totalPrice,
                        paymentItems: chosen
                            .map((program) => program.title)
                            .toList(),
                        freeResult: widget.freeResult,
                        forceTestMode: _paymentCheckoutUrl.isEmpty,
                      ),
                    ),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(chosen.isEmpty ? '프로그램을 선택해 주세요' : '결제하고 정밀 분석 시작'),
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
}

class _ConsultingJourneyStepBar extends StatelessWidget {
  final int activeStep;
  const _ConsultingJourneyStepBar({required this.activeStep});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(3, (index) {
      final step = index + 1;
      final active = step <= activeStep;
      final label = ['결제', '상담', '프로그램'][index];
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 23,
              height: 23,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? lime : const Color(0xffE5EAF4),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$step',
                style: TextStyle(
                  color: active ? Colors.white : mute,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? text : mute,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (index < 2)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Divider(color: Color(0xffD9E2F1)),
                ),
              ),
          ],
        ),
      );
    }),
  );
}

class _JourneyGuideRow extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _JourneyGuideRow({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: lavender,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: lime,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(color: mute, fontSize: 10, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ConsultantMatchingBrief {
  final String studentRecordSummary;
  final List<String> learningTraits;
  final String schoolGrades;
  final String mockExamScores;
  final String desiredMajor;
  final String targetUniversities;
  final String activitySummary;
  final String consultationRequest;
  final List<String> admissionTracks;
  final int academicReadiness;
  final int mockReadiness;
  final int recordReadiness;
  final int careerReadiness;

  const ConsultantMatchingBrief({
    required this.studentRecordSummary,
    required this.learningTraits,
    required this.schoolGrades,
    required this.mockExamScores,
    required this.desiredMajor,
    required this.targetUniversities,
    required this.activitySummary,
    required this.consultationRequest,
    required this.admissionTracks,
    required this.academicReadiness,
    required this.mockReadiness,
    required this.recordReadiness,
    required this.careerReadiness,
  });

  static const _key = 'gachi.consultant.matching_brief';

  static Future<ConsultantMatchingBrief?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ConsultantMatchingBrief(
        studentRecordSummary: data['studentRecordSummary'] as String? ?? '',
        learningTraits: List<String>.from(
          data['learningTraits'] as List? ?? [],
        ),
        schoolGrades: data['schoolGrades'] as String? ?? '',
        mockExamScores: data['mockExamScores'] as String? ?? '',
        desiredMajor: data['desiredMajor'] as String? ?? '',
        targetUniversities: data['targetUniversities'] as String? ?? '',
        activitySummary: data['activitySummary'] as String? ?? '',
        consultationRequest: data['consultationRequest'] as String? ?? '',
        admissionTracks: List<String>.from(
          data['admissionTracks'] as List? ?? [],
        ),
        academicReadiness: data['academicReadiness'] as int? ?? 3,
        mockReadiness: data['mockReadiness'] as int? ?? 3,
        recordReadiness: data['recordReadiness'] as int? ?? 3,
        careerReadiness: data['careerReadiness'] as int? ?? 3,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode({
        'studentRecordSummary': studentRecordSummary,
        'learningTraits': learningTraits,
        'schoolGrades': schoolGrades,
        'mockExamScores': mockExamScores,
        'desiredMajor': desiredMajor,
        'targetUniversities': targetUniversities,
        'activitySummary': activitySummary,
        'consultationRequest': consultationRequest,
        'admissionTracks': admissionTracks,
        'academicReadiness': academicReadiness,
        'mockReadiness': mockReadiness,
        'recordReadiness': recordReadiness,
        'careerReadiness': careerReadiness,
      }),
    );
  }
}

class ConsultantMatchPass {
  final Set<String> consultantNames;
  const ConsultantMatchPass(this.consultantNames);

  static String _key(String orderId) => 'gachi.consultant.match_pass.$orderId';

  static Future<ConsultantMatchPass> load(String orderId) async {
    final preferences = await SharedPreferences.getInstance();
    return ConsultantMatchPass(
      (preferences.getStringList(_key(orderId)) ?? []).toSet(),
    );
  }

  static Future<void> addConsultant(String orderId, String name) async {
    final preferences = await SharedPreferences.getInstance();
    final names = (preferences.getStringList(_key(orderId)) ?? []).toSet()
      ..add(name);
    await preferences.setStringList(_key(orderId), names.toList());
  }
}

class ConsultantMatchingBriefPage extends StatefulWidget {
  const ConsultantMatchingBriefPage({super.key});

  @override
  State<ConsultantMatchingBriefPage> createState() =>
      _ConsultantMatchingBriefPageState();
}

class _ConsultantMatchingBriefPageState
    extends State<ConsultantMatchingBriefPage> {
  final _recordController = TextEditingController();
  final _schoolGradesController = TextEditingController();
  final _mockExamController = TextEditingController();
  final _desiredMajorController = TextEditingController();
  final _targetUniversitiesController = TextEditingController();
  final _activityController = TextEditingController();
  final _requestController = TextEditingController();
  final _traits = <String>{};
  final _admissionTracks = <String>{};
  bool _consented = false;
  AcademyStudentProfile? _profile;
  int _academicReadiness = 3;
  int _mockReadiness = 3;
  int _recordReadiness = 3;
  int _careerReadiness = 3;

  static const _traitOptions = [
    '개념을 먼저 이해해요',
    '문제풀이로 익혀요',
    '계획 점검이 필요해요',
    '혼자 집중해요',
    '피드백이 동기 돼요',
  ];
  static const _admissionTrackOptions = ['학생부교과', '학생부종합', '정시', '논술·실기'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProfile = preferences.getString('gachi.student.profile');
    final brief = await ConsultantMatchingBrief.load();
    if (!mounted) return;
    setState(() {
      if (rawProfile != null) {
        try {
          _profile = AcademyStudentProfile.fromJson(
            jsonDecode(rawProfile) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
      if (brief != null) {
        _recordController.text = brief.studentRecordSummary;
        _schoolGradesController.text = brief.schoolGrades;
        _mockExamController.text = brief.mockExamScores;
        _desiredMajorController.text = brief.desiredMajor;
        _targetUniversitiesController.text = brief.targetUniversities;
        _activityController.text = brief.activitySummary;
        _requestController.text = brief.consultationRequest;
        _traits.addAll(brief.learningTraits);
        _admissionTracks.addAll(brief.admissionTracks);
        _academicReadiness = brief.academicReadiness;
        _mockReadiness = brief.mockReadiness;
        _recordReadiness = brief.recordReadiness;
        _careerReadiness = brief.careerReadiness;
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (!_consented) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('매칭에 정보를 사용하는 데 동의해 주세요.')));
      return;
    }
    await ConsultantMatchingBrief(
      studentRecordSummary: _recordController.text.trim(),
      learningTraits: _traits.toList(),
      schoolGrades: _schoolGradesController.text.trim(),
      mockExamScores: _mockExamController.text.trim(),
      desiredMajor: _desiredMajorController.text.trim(),
      targetUniversities: _targetUniversitiesController.text.trim(),
      activitySummary: _activityController.text.trim(),
      consultationRequest: _requestController.text.trim(),
      admissionTracks: _admissionTracks.toList(),
      academicReadiness: _academicReadiness,
      mockReadiness: _mockReadiness,
      recordReadiness: _recordReadiness,
      careerReadiness: _careerReadiness,
    ).save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _recordController.dispose();
    _schoolGradesController.dispose();
    _mockExamController.dispose();
    _desiredMajorController.dispose();
    _targetUniversitiesController.dispose();
    _activityController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('매칭 전 정보 확인'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const Text(
          '나에게 맞는 컨설턴트를\n더 정확히 찾아볼게요.',
          style: TextStyle(
            color: text,
            fontSize: 27,
            height: 1.18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '등록한 학생 정보와 아래 요약을 매칭 기준으로 확인합니다.',
          style: TextStyle(color: mute, fontSize: 12, height: 1.45),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xffEEF4FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, color: lime),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _profile == null
                      ? '등록된 학생 정보가 없어요. 기본 매칭으로 진행됩니다.'
                      : '${_profile!.school} · ${_profile!.grade}\n${_profile!.subjects.join(' · ')} 관심',
                  style: const TextStyle(
                    color: text,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '상담 준비 차트',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '현재 준비 상태를 1~5단계로 표시해 주세요. 컨설턴트가 상담 우선순위를 파악하는 데 사용합니다.',
          style: TextStyle(color: mute, fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 10),
        _AdmissionReadinessEditor(
          academic: _academicReadiness,
          mock: _mockReadiness,
          record: _recordReadiness,
          career: _careerReadiness,
          onAcademicChanged: (value) =>
              setState(() => _academicReadiness = value),
          onMockChanged: (value) => setState(() => _mockReadiness = value),
          onRecordChanged: (value) => setState(() => _recordReadiness = value),
          onCareerChanged: (value) => setState(() => _careerReadiness = value),
        ),
        const SizedBox(height: 24),
        const Text(
          '학업 현황',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '정확한 성적표 업로드는 상담 확정 후 안내합니다. 지금은 최근 성적 흐름만 적어 주세요.',
          style: TextStyle(color: mute, fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _schoolGradesController,
          maxLength: 160,
          decoration: const InputDecoration(
            labelText: '내신 성적 흐름',
            hintText: '예: 국어 2, 수학 2, 영어 1 · 최근 상승 중',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _mockExamController,
          maxLength: 160,
          decoration: const InputDecoration(
            labelText: '모의고사·수능 성적 흐름',
            hintText: '예: 6월 모의 국2 수3 영2 · 수학 보완 필요',
          ),
        ),
        const SizedBox(height: 19),
        const Text(
          '목표와 지원 방향',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _desiredMajorController,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: '희망 학과·진로',
            hintText: '예: 환경공학, 데이터사이언스',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _targetUniversitiesController,
          maxLength: 140,
          decoration: const InputDecoration(
            labelText: '희망 대학군 (선택)',
            hintText: '예: 서울권 자연계 · 수도권 안전 지원',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _admissionTrackOptions
              .map(
                (track) => FilterChip(
                  label: Text(track),
                  selected: _admissionTracks.contains(track),
                  onSelected: (selected) => setState(() {
                    selected
                        ? _admissionTracks.add(track)
                        : _admissionTracks.remove(track);
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          '학생부 핵심 요약',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '세특·교과·진로 활동 중 상담에서 꼭 봐야 할 내용을 적어 주세요. 선택 항목입니다.',
          style: TextStyle(color: mute, fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _recordController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: '예: 환경공학 진로를 희망하며 과학 탐구 활동을 이어가고 있어요.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _activityController,
          maxLines: 3,
          maxLength: 350,
          decoration: const InputDecoration(
            labelText: '최근 활동·세특에서 강조하고 싶은 점 (선택)',
            hintText: '예: 교내 과학 동아리에서 미세플라스틱 탐구 보고서를 작성했어요.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          '학습 성향',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _traitOptions
              .map(
                (trait) => FilterChip(
                  label: Text(trait),
                  selected: _traits.contains(trait),
                  onSelected: (selected) => setState(() {
                    selected ? _traits.add(trait) : _traits.remove(trait);
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 19),
        const Text(
          '이번 상담에서 해결하고 싶은 질문',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _requestController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: '예: 현재 성적으로 학생부종합과 교과전형 중 어디에 더 집중해야 할지 알고 싶어요.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffDCE5F2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.privacy_tip_outlined, color: lime, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  '현재 MVP에서는 이 요약을 이 기기에만 저장하며, 외부 AI나 클라우드로 전송하지 않습니다.',
                  style: TextStyle(color: mute, fontSize: 10, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _consented,
          onChanged: (value) => setState(() => _consented = value ?? false),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            '매칭 상담 목적으로 정보를 사용하는 데 동의합니다.',
            style: TextStyle(color: text, fontSize: 11),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saveAndContinue,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(55)),
          child: const Text('확인하고 매칭 상담 결제하기'),
        ),
      ],
    ),
  );
}

class _AdmissionReadinessEditor extends StatelessWidget {
  final int academic;
  final int mock;
  final int record;
  final int career;
  final ValueChanged<int> onAcademicChanged;
  final ValueChanged<int> onMockChanged;
  final ValueChanged<int> onRecordChanged;
  final ValueChanged<int> onCareerChanged;

  const _AdmissionReadinessEditor({
    required this.academic,
    required this.mock,
    required this.record,
    required this.career,
    required this.onAcademicChanged,
    required this.onMockChanged,
    required this.onRecordChanged,
    required this.onCareerChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffDCE5F2)),
    ),
    child: Column(
      children: [
        _ReadinessBar(
          label: '교과 성적',
          helper: '내신 흐름',
          value: academic,
          onChanged: onAcademicChanged,
        ),
        _ReadinessBar(
          label: '모의 성적',
          helper: '수능 대비',
          value: mock,
          onChanged: onMockChanged,
        ),
        _ReadinessBar(
          label: '학생부 활동',
          helper: '세특·활동',
          value: record,
          onChanged: onRecordChanged,
        ),
        _ReadinessBar(
          label: '진로 명확성',
          helper: '학과·목표',
          value: career,
          onChanged: onCareerChanged,
        ),
      ],
    ),
  );
}

class _ReadinessBar extends StatelessWidget {
  final String label;
  final String helper;
  final int value;
  final ValueChanged<int> onChanged;
  const _ReadinessBar({
    required this.label,
    required this.helper,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(helper, style: const TextStyle(color: mute, fontSize: 9)),
            ],
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$value단계',
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(
          width: 33,
          child: Text(
            '$value/5',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: lime,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class PaidConsultantMatchingPage extends StatefulWidget {
  final String matchOrderId;
  final Map<String, dynamic>? freeResult;
  final bool studentBriefReady;
  const PaidConsultantMatchingPage({
    super.key,
    required this.matchOrderId,
    this.freeResult,
    this.studentBriefReady = false,
  });

  @override
  State<PaidConsultantMatchingPage> createState() =>
      _PaidConsultantMatchingPageState();
}

class _PaidConsultantMatchingPageState
    extends State<PaidConsultantMatchingPage> {
  int selectedConsultant = 0;
  Set<String> _consultedNames = {};
  bool _loadingPass = true;

  static const _matchScores = [92, 86, 82];
  static const _strengths = [
    ['매우 강점', '보통', '강점'],
    ['보통', '매우 강점', '강점'],
    ['강점', '보통', '매우 강점'],
  ];

  String get _selectedName => _consultantProfiles[selectedConsultant].name;
  int get _remainingConsultations => 3 - _consultedNames.length;

  @override
  void initState() {
    super.initState();
    _loadPass();
  }

  Future<void> _loadPass() async {
    final pass = await ConsultantMatchPass.load(widget.matchOrderId);
    if (mounted) {
      setState(() {
        _consultedNames = pass.consultantNames;
        _loadingPass = false;
      });
    }
  }

  Future<void> _openConsultantChat(ConsultantProfile consultant) async {
    final isNewConsultant = !_consultedNames.contains(consultant.name);
    if (isNewConsultant && _consultedNames.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 상담권으로는 최대 3명과 상담할 수 있어요.')),
      );
      return;
    }
    if (isNewConsultant) {
      await ConsultantMatchPass.addConsultant(
        widget.matchOrderId,
        consultant.name,
      );
      if (!mounted) return;
      setState(() => _consultedNames.add(consultant.name));
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaidConsultantChatPage(
          consultant: consultant,
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
      title: const Text('컨설턴트 매칭'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const _ConsultingJourneyStepBar(activeStep: 2),
        const SizedBox(height: 18),
        _SignalMatchSummary(studentBriefReady: widget.studentBriefReady),
        const SizedBox(height: 15),
        _MatchConsultationQuota(
          used: _consultedNames.length,
          loading: _loadingPass,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 238,
          child: Row(
            children: List.generate(
              _consultantProfiles.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == _consultantProfiles.length - 1 ? 0 : 7,
                  ),
                  child: _SignalConsultantCard(
                    consultant: _consultantProfiles[index],
                    score: _matchScores[index],
                    rank: index + 1,
                    selected: selectedConsultant == index,
                    onTap: () => setState(() => selectedConsultant = index),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ConsultantComparisonPanel(
          selected: selectedConsultant,
          strengths: _strengths,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final consultant = await Navigator.push<ConsultantProfile>(
              context,
              MaterialPageRoute(builder: (_) => const AllConsultantsPage()),
            );
            if (consultant == null || !context.mounted) return;
            await _openConsultantChat(consultant);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: lime,
            side: const BorderSide(color: Color(0xffB7D0FF)),
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.people_alt_outlined, size: 19),
          label: Text('전체 컨설턴트 ${_allConsultantProfiles.length}명 보기'),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xffFBF9FF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffE8DFFF)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xff7657D7),
                size: 18,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '선택이 고민된다면 첫 상담에서 목표를 다시 확인할 수 있어요.',
                  style: TextStyle(color: mute, fontSize: 10, height: 1.35),
                ),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('상담에서 현재 목표와 고민을 함께 정리해 드려요.')),
                ),
                child: const Text('안내', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _loadingPass
              ? null
              : () => _openConsultantChat(
                  _consultantProfiles[selectedConsultant],
                ),
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(58),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: Text(
            _consultedNames.contains(_selectedName)
                ? '$_selectedName와 채팅 이어가기'
                : '$_selectedName와 채팅 상담',
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '매칭 점수는 입력한 목표와 상담 분야를 기준으로 한 데모 비교 지표입니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mute, fontSize: 9, height: 1.4),
        ),
      ],
    ),
  );
}

class AllConsultantsPage extends StatefulWidget {
  const AllConsultantsPage({super.key});

  @override
  State<AllConsultantsPage> createState() => _AllConsultantsPageState();
}

class _AllConsultantsPageState extends State<AllConsultantsPage> {
  String filter = '전체';

  List<ConsultantProfile> get _visibleProfiles => switch (filter) {
    '학생부' =>
      _allConsultantProfiles
          .where(
            (profile) =>
                profile.role.contains('학생부') || profile.role.contains('수시'),
          )
          .toList(),
    '정시' =>
      _allConsultantProfiles
          .where(
            (profile) =>
                profile.role.contains('정시') || profile.role.contains('재수'),
          )
          .toList(),
    '전공 탐색' =>
      _allConsultantProfiles
          .where(
            (profile) =>
                profile.role.contains('전공') || profile.role.contains('계열'),
          )
          .toList(),
    '고입' =>
      _allConsultantProfiles
          .where((profile) => profile.role.contains('고입'))
          .toList(),
    _ => _allConsultantProfiles,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('전체 컨설턴트'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        Text(
          '등록된 컨설턴트 ${_allConsultantProfiles.length}명',
          style: const TextStyle(
            color: text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '전문 분야와 상담 경력을 비교하고, 원하는 컨설턴트를 선택하세요.',
          style: TextStyle(color: mute, fontSize: 11, height: 1.45),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['전체', '학생부', '정시', '전공 탐색', '고입']
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filter == label,
                      onSelected: (_) => setState(() => filter = label),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        ..._visibleProfiles.map(
          (consultant) => _AllConsultantListCard(
            consultant: consultant,
            recommended: _consultantProfiles.contains(consultant),
            onSelect: () => Navigator.pop(context, consultant),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '현재 목록은 MVP 데모 프로필입니다. 운영 버전에서는 관리자 승인 컨설턴트만 표시됩니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mute, fontSize: 9, height: 1.45),
        ),
      ],
    ),
  );
}

class _AllConsultantListCard extends StatelessWidget {
  final ConsultantProfile consultant;
  final bool recommended;
  final VoidCallback onSelect;
  const _AllConsultantListCard({
    required this.consultant,
    required this.recommended,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffE0E7F2)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xffEAF1FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: lime, size: 28),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      consultant.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (recommended) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lavender,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        '추천',
                        style: TextStyle(
                          color: lime,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${consultant.role} · ${consultant.experience}',
                style: const TextStyle(color: mute, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                consultant.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: mute, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        TextButton(onPressed: onSelect, child: const Text('선택')),
      ],
    ),
  );
}

class _SignalMatchSummary extends StatelessWidget {
  final bool studentBriefReady;
  const _SignalMatchSummary({this.studentBriefReady = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffFBFDFF), Color(0xffECF4FF)],
      ),
      border: Border.all(color: const Color(0xffDCE9FE)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100B63F6),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        const _MatchScoreRing(score: 92),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _SoftSignalPill(
                  icon: Icons.auto_awesome_rounded,
                  label: studentBriefReady ? '학생 정보 확인 완료' : '맞춤 추천',
                ),
              ),
              SizedBox(height: 10),
              Text(
                '학습 목표와\n상담 스타일을 분석했어요',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '학생 정보와 선택한 목표를 바탕으로\n잘 맞는 상담 분야를 비교했어요.',
                style: TextStyle(color: mute, fontSize: 10, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MatchConsultationQuota extends StatelessWidget {
  final int used;
  final bool loading;
  const _MatchConsultationQuota({required this.used, required this.loading});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffDCE5F2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.forum_outlined, color: lime, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            loading ? '매칭 상담권을 확인하고 있어요.' : '매칭 상담권 · 최대 3명',
            style: const TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!loading)
          Text(
            '$used/3명 사용',
            style: const TextStyle(
              color: lime,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );
}

class _MatchScoreRing extends StatelessWidget {
  final int score;
  const _MatchScoreRing({required this.score});

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    height: 116,
    padding: const EdgeInsets.all(9),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xffEAF3FF),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 98,
          height: 98,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            backgroundColor: const Color(0xffD6E6FF),
            valueColor: const AlwaysStoppedAnimation(lime),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('매칭 신호', style: TextStyle(color: mute, fontSize: 9)),
            Text(
              '$score%',
              style: const TextStyle(
                color: lime,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SoftSignalPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SoftSignalPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffF7F2FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE1D4FF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xff7657D7), size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff7657D7),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SignalConsultantCard extends StatelessWidget {
  final ConsultantProfile consultant;
  final int score;
  final int rank;
  final bool selected;
  final VoidCallback onTap;
  const _SignalConsultantCard({
    required this.consultant,
    required this.score,
    required this.rank,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffF1F6FF) : surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? lime : const Color(0xffE0E7F2),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x140B63F6),
                    blurRadius: 15,
                    offset: Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? lime : mist,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rank == 1 ? '추천 1' : '$rank',
                    style: TextStyle(
                      color: selected ? Colors.white : mute,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? lime : const Color(0xffC8D2E3),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? lime : const Color(0xffEAF1FF),
              ),
              child: Icon(
                Icons.person_rounded,
                color: selected ? Colors.white : lime,
                size: 28,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              consultant.name.replaceAll(' 컨설턴트', ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xffEAF3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$score%',
                style: const TextStyle(
                  color: lime,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              consultant.role,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: mute, fontSize: 8, height: 1.25),
            ),
            const SizedBox(height: 3),
            Text(
              consultant.experience,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: mute, fontSize: 8),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ConsultantComparisonPanel extends StatelessWidget {
  final int selected;
  final List<List<String>> strengths;
  const _ConsultantComparisonPanel({
    required this.selected,
    required this.strengths,
  });

  static const _criteria = [
    (Icons.menu_book_outlined, '학생부'),
    (Icons.track_changes_rounded, '정시'),
    (Icons.explore_outlined, '전공 탐색'),
  ];

  int _dots(String label) => switch (label) {
    '매우 강점' => 5,
    '강점' => 4,
    _ => 3,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE0E7F2)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _criteria
                .map(
                  (criterion) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Icon(criterion.$1, size: 16, color: lime),
                        const SizedBox(width: 6),
                        Text(
                          criterion.$2,
                          style: const TextStyle(
                            color: text,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        ...List.generate(
          3,
          (profileIndex) => Expanded(
            flex: 10,
            child: Container(
              padding: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: profileIndex == 0
                        ? Colors.transparent
                        : const Color(0xffEDF0F6),
                  ),
                ),
              ),
              child: Column(
                children: List.generate(3, (criterionIndex) {
                  final label = strengths[profileIndex][criterionIndex];
                  final isCurrent = profileIndex == selected;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isCurrent ? lime : mute,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (dot) => Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dot < _dots(label)
                                    ? (isCurrent
                                          ? lime
                                          : const Color(0xff8DB4F7))
                                    : const Color(0xffE0E7F2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class PaidConsultantChatPage extends StatefulWidget {
  final ConsultantProfile consultant;
  final Map<String, dynamic>? freeResult;
  const PaidConsultantChatPage({
    super.key,
    required this.consultant,
    this.freeResult,
  });

  @override
  State<PaidConsultantChatPage> createState() => _PaidConsultantChatPageState();
}

class _PaidConsultantChatPageState extends State<PaidConsultantChatPage> {
  final input = TextEditingController();
  late final List<(bool, String)> messages;

  @override
  void initState() {
    super.initState();
    messages = [
      (
        false,
        '안녕하세요. ${widget.consultant.name}입니다. 현재 가장 고민되는 입시 목표나 과목을 알려주세요.',
      ),
    ];
    _restoreChat();
  }

  String get _chatKey => 'gachi.consulting.chat.${widget.consultant.name}';

  Future<void> _restoreChat() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_chatKey);
    if (encoded == null || !mounted) return;
    try {
      final saved = (jsonDecode(encoded) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) => (item['mine'] == true, item['body']?.toString() ?? ''))
          .where((item) => item.$2.isNotEmpty)
          .toList();
      if (saved.isNotEmpty) setState(() => messages.addAll(saved));
    } catch (_) {}
  }

  Future<void> _saveChat() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _chatKey,
      jsonEncode(
        messages.map((item) => {'mine': item.$1, 'body': item.$2}).toList(),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _send([String? value]) {
    final body = (value ?? input.text).trim();
    if (body.isEmpty) return;
    setState(() {
      messages.add((true, body));
      messages.add((false, '말씀해 주신 내용을 바탕으로 필요한 전략과 프로그램을 정리해 볼게요.'));
      input.clear();
    });
    _saveChat();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: Text('${widget.consultant.name} 상담'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: _ConsultingJourneyStepBar(activeStep: 2),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: lime, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${widget.consultant.specialty} · MVP 채팅 상담',
                    style: const TextStyle(
                      color: text,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              children: messages
                  .map(
                    (message) => Align(
                      alignment: message.$1
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 290),
                        decoration: BoxDecoration(
                          color: message.$1 ? lime : surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.$2,
                          style: TextStyle(
                            color: message.$1 ? Colors.white : text,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              children: ['목표 대학', '내신 관리', '학생부 방향']
                  .map(
                    (item) => ActionChip(
                      label: Text(item),
                      onPressed: () => _send(item),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    onSubmitted: _send,
                    decoration: _inputDecoration(hint: '상담 내용을 입력하세요'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FilledButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PremiumAdmissionOffer(
                    freeResult: widget.freeResult,
                    consultant: widget.consultant,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('상담 요약 후 맞춤 프로그램 선택'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SelectedConsultantBanner extends StatelessWidget {
  final ConsultantProfile consultant;
  const _SelectedConsultantBanner({required this.consultant});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: lavender,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.person_outline_rounded, color: lime),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${consultant.name} 상담 후 추천 구성',
            style: const TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          consultant.specialty,
          style: const TextStyle(color: mute, fontSize: 9),
        ),
      ],
    ),
  );
}

class _ConsultingProgram {
  final String title;
  final String recommendedFor;
  final List<String> grades;
  final String sessionInfo;
  final int price;
  final String summary;
  final String detail;
  final List<String> deliverables;
  final String? siteUrl;

  const _ConsultingProgram({
    required this.title,
    required this.recommendedFor,
    required this.grades,
    required this.sessionInfo,
    required this.price,
    required this.summary,
    required this.detail,
    required this.deliverables,
    this.siteUrl,
  });
}

class _ConsultingProgramCard extends StatelessWidget {
  final _ConsultingProgram program;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _ConsultingProgramCard({
    required this.program,
    required this.selected,
    required this.onChanged,
  });

  String get priceLabel =>
      '${program.price.toString().replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',')}원';

  Future<void> _showDetail(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.title,
              style: const TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '권장 시기 · ${program.recommendedFor}',
                style: const TextStyle(
                  color: lime,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              program.sessionInfo,
              style: const TextStyle(
                color: mute,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              program.detail,
              style: const TextStyle(color: mute, fontSize: 12, height: 1.55),
            ),
            const SizedBox(height: 16),
            const Text(
              '제공 내용',
              style: TextStyle(color: text, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...program.deliverables.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: lime,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      item,
                      style: const TextStyle(color: text, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'MVP 검토 가격 · $priceLabel',
              style: const TextStyle(color: mute, fontSize: 10),
            ),
            if (program.siteUrl != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(program.siteUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('사이트 프로그램 보기'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? const Color(0xff9FC1FF) : const Color(0xffE2E6EE),
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: lime,
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            visualDensity: VisualDensity.standard,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              program.title,
              style: const TextStyle(
                color: text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  program.recommendedFor,
                  style: const TextStyle(
                    color: lime,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  program.sessionInfo,
                  style: const TextStyle(color: mute, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  program.summary,
                  style: const TextStyle(
                    color: mute,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            secondary: Text(
              priceLabel,
              style: const TextStyle(
                color: lime,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showDetail(context),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('상세 내용 보기'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlanComparisonRow extends StatelessWidget {
  // Deprecated comparison component kept for compatibility with prior screens.
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
  final List<String> paymentItems;
  final Map<String, dynamic>? freeResult;
  final bool forceTestMode;
  final Widget Function(String orderId)? afterPayment;

  const PaymentPage({
    super.key,
    required this.productName,
    required this.price,
    this.paymentItems = const [],
    this.freeResult,
    this.forceTestMode = false,
    this.afterPayment,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool agreed = false;
  bool processing = false;
  String selectedTestMethod = '토스페이먼츠';
  bool storeLoading = true;
  bool storeAvailable = false;
  String? storeMessage;
  ProductDetails? storeProduct;
  StreamSubscription<List<PurchaseDetails>>? purchaseSubscription;

  bool get nativeStoreSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get storeReadyForPurchase =>
      storeAvailable && _purchaseVerificationUrl.isNotEmpty;

  String get storeName => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'Apple App Store',
    TargetPlatform.android => 'Google Play',
    _ => '모바일 앱스토어',
  };

  @override
  void initState() {
    super.initState();
    if (widget.forceTestMode) {
      storeLoading = false;
      return;
    }
    if (!nativeStoreSupported) {
      unawaited(_loadStore());
      return;
    }
    purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        if (mounted) {
          setState(() {
            processing = false;
            storeMessage = '스토어 결제 상태를 불러오지 못했습니다.';
          });
        }
      },
    );
    unawaited(_loadStore());
  }

  @override
  void dispose() {
    purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStore() async {
    if (!nativeStoreSupported) {
      if (mounted) {
        setState(() {
          storeLoading = false;
          storeMessage = '스토어 결제는 Android·iOS 앱에서 사용할 수 있습니다.';
        });
      }
      return;
    }
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        if (mounted) {
          setState(() {
            storeLoading = false;
            storeMessage = '$storeName에 연결할 수 없습니다.';
          });
        }
        return;
      }
      final response = await InAppPurchase.instance.queryProductDetails({
        _storeProductId,
      });
      final product = response.productDetails.isEmpty
          ? null
          : response.productDetails.first;
      if (!mounted) return;
      setState(() {
        storeLoading = false;
        storeAvailable = product != null;
        storeProduct = product;
        storeMessage = product == null
            ? '$storeName에 상품 ID $_storeProductId를 등록해 주세요.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        storeLoading = false;
        storeMessage = '$storeName 초기화에 실패했습니다. 스토어 설정을 확인해 주세요.';
      });
    }
  }

  String get formattedPrice {
    final digits = widget.price.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '$buffer원';
  }

  String get displayedPrice => storeProduct?.price ?? formattedPrice;

  Future<void> _pay() async {
    if (!agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 조건과 개인정보 처리 안내에 동의해 주세요.')),
      );
      return;
    }

    if (widget.forceTestMode) {
      await _runTestPayment();
      return;
    }

    if (!nativeStoreSupported && _paymentCheckoutUrl.isNotEmpty) {
      setState(() => processing = true);
      try {
        final response = await http
            .post(
              Uri.parse('$_authApiBaseUrl/api/payments/prepare'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'items': widget.paymentItems.isEmpty
                    ? [widget.productName]
                    : widget.paymentItems,
              }),
            )
            .timeout(const Duration(seconds: 12));
        final order = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode != 200) {
          throw Exception(order['detail']?.toString() ?? '주문 정보를 준비하지 못했습니다.');
        }
        final uri = Uri.parse(_paymentCheckoutUrl).replace(
          queryParameters: {
            'orderId': order['order_id']?.toString() ?? '',
            'orderName': order['order_name']?.toString() ?? '',
            'amount': order['amount']?.toString() ?? '',
            'orderToken': order['order_token']?.toString() ?? '',
          },
        );
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('결제창을 열 수 없습니다.')));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('결제 준비 서버에 연결하지 못했습니다. 설정을 확인해 주세요.')),
          );
        }
      }
      if (mounted) setState(() => processing = false);
      return;
    }

    final product = storeProduct;
    if (!nativeStoreSupported || !storeAvailable || product == null) {
      await _showStoreSetupDialog();
      return;
    }
    if (_purchaseVerificationUrl.isEmpty) {
      await _showStoreSetupDialog(
        message: '상품은 조회됐지만 구매 검증 서버가 연결되지 않았습니다. 실제 청구 전에 PURCHASE_VERIFICATION_URL을 설정해 주세요.',
      );
      return;
    }
    setState(() => processing = true);
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => processing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('스토어 결제를 시작하지 못했습니다.')));
    }
  }

  Future<void> _showStoreSetupDialog({String? message}) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$storeName 연결 준비 중'),
      content: Text(
        message ?? storeMessage ?? '스토어 상품과 구매 검증 서버 설정을 확인한 후 다시 시도해 주세요.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  Future<void> _runTestPayment() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DemoPaymentCheckoutPage(
          productName: widget.productName,
          items: widget.paymentItems.isEmpty
              ? [widget.productName]
              : widget.paymentItems,
          price: widget.price,
          paymentMethod: selectedTestMethod,
        ),
      ),
    );
    if (completed != true || !mounted) return;
    await _unlockPremium('GACHI-TEST-${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!mounted) return;
      if (purchase.status == PurchaseStatus.pending) {
        setState(() => processing = true);
        continue;
      }
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        setState(() => processing = false);
        if (purchase.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(purchase.error?.message ?? '결제가 취소되었습니다.')),
          );
        }
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final verified = await _verifyPurchase(purchase);
        if (!mounted) return;
        if (!verified) {
          setState(() => processing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구매 검증에 실패했습니다. 결제 내역에서 다시 확인해 주세요.')),
          );
          continue;
        }
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        await _unlockPremium(
          purchase.purchaseID ??
              'STORE-${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (_purchaseVerificationUrl.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse(_purchaseVerificationUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'productId': purchase.productID,
              'purchaseId': purchase.purchaseID,
              'source': purchase.verificationData.source,
              'serverVerificationData':
                  purchase.verificationData.serverVerificationData,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final data = jsonDecode(response.body);
      return data is Map && data['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restorePurchases() async {
    if (!nativeStoreSupported || _purchaseVerificationUrl.isEmpty) {
      await _showStoreSetupDialog();
      return;
    }
    setState(() => processing = true);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> _unlockPremium(String orderId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('gachi.purchase.admission_pro', true);
    await preferences.setString('gachi.purchase.last_order', orderId);
    if (!mounted) return;
    setState(() => processing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            widget.afterPayment?.call(orderId) ??
            PremiumAdmissionReport(
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
        if (!widget.forceTestMode)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: storeReadyForPurchase
                  ? const Color(0xffEAF8F3)
                  : const Color(0xffFFF4D4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                if (storeLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    storeReadyForPurchase
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    color: storeReadyForPurchase
                        ? const Color(0xff168A73)
                        : const Color(0xff8A6800),
                    size: 19,
                  ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    storeLoading
                        ? '$storeName 상품을 확인하고 있습니다.'
                        : storeReadyForPurchase
                        ? '$storeName 공식 인앱결제로 안전하게 결제합니다.'
                        : storeAvailable
                        ? '상품을 찾았습니다. 구매 검증 서버 연결이 필요합니다.'
                        : storeMessage ?? '스토어 설정을 확인해 주세요.',
                    style: TextStyle(
                      color: storeReadyForPurchase
                          ? const Color(0xff126A5A)
                          : const Color(0xff705600),
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xffFFF4D4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '자동 테스트용 결제 모드입니다. 실제 금액은 청구되지 않습니다.',
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
                displayedPrice,
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
        if (widget.forceTestMode) ...[
          _TestPaymentMethodTile(
            icon: Icons.account_balance_wallet_outlined,
            title: '토스페이먼츠',
            detail: '카드 · 계좌이체 · 간편결제 · 가상계좌',
            selected: selectedTestMethod == '토스페이먼츠',
            onTap: () => setState(() => selectedTestMethod = '토스페이먼츠'),
          ),
          const SizedBox(height: 8),
          _TestPaymentMethodTile(
            icon: Icons.play_arrow_rounded,
            title: 'Google Play 결제',
            detail: '등록 카드 · 은행계좌(KCP) · 휴대폰 · Naver Pay',
            selected: selectedTestMethod == 'Google Play 결제',
            onTap: () => setState(() => selectedTestMethod = 'Google Play 결제'),
          ),
          const SizedBox(height: 8),
          _TestPaymentMethodTile(
            icon: Icons.apple_rounded,
            title: 'Apple App Store 결제',
            detail: '카카오·네이버·토스·PAYCO · 카드 · 휴대폰',
            selected: selectedTestMethod == 'Apple App Store 결제',
            onTap: () =>
                setState(() => selectedTestMethod = 'Apple App Store 결제'),
          ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xffE2E6EE)),
            ),
            child: Row(
              children: [
                Icon(
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? Icons.apple_rounded
                      : Icons.shop_outlined,
                  color: text,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          color: text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '스토어 계정의 결제수단·환불정책 적용',
                        style: TextStyle(color: mute, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                Icon(
                  storeReadyForPurchase
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: storeReadyForPurchase ? lime : mute,
                  size: 20,
                ),
              ],
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
          child: Text(processing ? '결제 준비 중...' : '$displayedPrice 결제하기'),
        ),
        if (!widget.forceTestMode) ...[
          const SizedBox(height: 7),
          TextButton(
            onPressed: processing ? null : _restorePurchases,
            child: const Text('이전 구매 복원'),
          ),
        ],
      ],
    ),
  );
}

/// 실제 PG 키를 연결하기 전, 사용자가 결제 경험과 후속 흐름을 검토할 수 있는
/// 앱 내 테스트 체크아웃입니다. 어떤 결제 수단도 외부로 전송하거나 청구하지 않습니다.
class DemoPaymentCheckoutPage extends StatefulWidget {
  final String productName;
  final List<String> items;
  final int price;
  final String paymentMethod;

  const DemoPaymentCheckoutPage({
    super.key,
    required this.productName,
    required this.items,
    required this.price,
    required this.paymentMethod,
  });

  @override
  State<DemoPaymentCheckoutPage> createState() =>
      _DemoPaymentCheckoutPageState();
}

class _DemoPaymentCheckoutPageState extends State<DemoPaymentCheckoutPage> {
  int selectedMethod = 0;

  String get formattedPrice {
    final digits = widget.price.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '$buffer원';
  }

  Future<void> _completeTestPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테스트 결제를 완료할까요?'),
        content: const Text(
          '실제 카드 승인이나 금액 청구는 발생하지 않습니다.\n결제 완료 화면 뒤 다음 단계로 이동합니다.',
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
    if (confirmed == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final methods = switch (widget.paymentMethod) {
      '토스페이먼츠' => [
        (Icons.credit_card_rounded, '카드 결제', '신용·체크카드 테스트'),
        (Icons.account_balance_outlined, '계좌이체', '은행 계좌이체 테스트'),
        (Icons.account_balance_wallet_outlined, '간편결제', '토스페이 · 카카오페이 등 테스트'),
        (Icons.receipt_long_outlined, '가상계좌', '입금 전용 가상계좌 테스트'),
      ],
      'Google Play 결제' => [
        (Icons.credit_card_rounded, 'Google 계정 등록 카드', '신용·체크카드 테스트'),
        (Icons.account_balance_outlined, '등록 은행계좌', 'KCP를 통한 계좌 등록 결제 테스트'),
        (Icons.phone_android_rounded, '휴대폰 결제', '이동통신사 소액결제 테스트'),
        (
          Icons.account_balance_wallet_outlined,
          'Naver Pay · Play 잔액',
          'Google 계정에서 지원되는 수단 테스트',
        ),
      ],
      _ => [
        (
          Icons.account_balance_wallet_outlined,
          '국내 간편결제',
          '카카오페이 · Naver Pay · Toss Pay · PAYCO',
        ),
        (Icons.credit_card_rounded, 'Apple 계정 등록 카드', '신용·체크카드 테스트'),
        (Icons.phone_iphone_rounded, '휴대폰 결제', 'KT · LG U+ · SK Telecom 테스트'),
      ],
    };
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text('테스트 결제'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xffEAF1FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.science_outlined, color: lime, size: 19),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '테스트 결제 환경입니다. 실제 승인·청구는 발생하지 않아요.',
                            style: TextStyle(
                              color: text,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '주문 정보',
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xffE1E6F0)),
                    ),
                    child: Column(
                      children: [
                        ...widget.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '총 결제 금액',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formattedPrice,
                              style: const TextStyle(
                                color: lime,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '선택한 결제 수단 · ${widget.paymentMethod}',
                    style: const TextStyle(
                      color: lime,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    '결제 수단',
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...methods.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => selectedMethod = entry.key),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedMethod == entry.key
                                  ? lime
                                  : const Color(0xffE1E6F0),
                              width: selectedMethod == entry.key ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                entry.value.$1,
                                color: selectedMethod == entry.key
                                    ? lime
                                    : mute,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.value.$2,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.value.$3,
                                      style: const TextStyle(
                                        color: mute,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<int>(
                                value: entry.key,
                                groupValue: selectedMethod,
                                activeColor: lime,
                                onChanged: (value) =>
                                    setState(() => selectedMethod = value!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '대한민국 기준 데모입니다. 실제 지원 수단은 계정·기기·판매 정책에 따라 달라질 수 있어요.',
                      style: TextStyle(color: mute, fontSize: 9, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _completeTestPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(
                  '$formattedPrice 테스트 결제하기',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestPaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  const _TestPaymentMethodTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? lime : const Color(0xffE2E6EE),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? lime : text),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(detail, style: const TextStyle(color: mute, fontSize: 9)),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? lime : mute,
            size: 20,
          ),
        ],
      ),
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
                Expanded(child: Text('스토어 결제가 확인되어 정밀 분석이 열렸습니다.')),
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
