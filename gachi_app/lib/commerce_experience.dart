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

  const PremiumAdmissionOffer({super.key, this.freeResult});

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
                      freeResult: widget.freeResult,
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
  final Map<String, dynamic>? freeResult;
  final bool forceTestMode;

  const PaymentPage({
    super.key,
    required this.productName,
    required this.price,
    this.freeResult,
    this.forceTestMode = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool agreed = false;
  bool processing = false;
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
      final orderId = 'GACHI-${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse(_paymentCheckoutUrl).replace(
        queryParameters: {
          'orderId': orderId,
          'orderName': widget.productName,
          'amount': widget.price.toString(),
          'method': 'web',
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
    setState(() => processing = true);
    final orderId = 'GACHI-TEST-${DateTime.now().millisecondsSinceEpoch}';

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테스트 결제 확인'),
        content: Text(
          '$formattedPrice 테스트 결제를 완료할까요?\n\n위젯 테스트 전용 흐름이며 실제 금액은 청구되지 않습니다.',
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
    await _unlockPremium(orderId);
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
                      widget.forceTestMode ? '테스트 스토어' : storeName,
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
