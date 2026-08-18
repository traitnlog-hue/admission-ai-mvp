part of 'main.dart';

class TrustStatus {
  final int tickets;
  final int points;
  final int receiptCount;

  const TrustStatus({
    required this.tickets,
    required this.points,
    required this.receiptCount,
  });

  bool get hasVerifiedReceipt => receiptCount > 0;
}

class TrustWallet {
  static String _accountKey(SessionUser user) => user.email.toLowerCase();
  static String _ticketsKey(SessionUser user) =>
      'gachi.trust.${_accountKey(user)}.tickets';
  static String _pointsKey(SessionUser user) =>
      'gachi.trust.${_accountKey(user)}.points';
  static String _receiptsKey(SessionUser user) =>
      'gachi.trust.${_accountKey(user)}.receipts';
  static const _reportsKey = 'gachi.local.intel.reports';

  static Future<TrustStatus> load(SessionUser user) async {
    final preferences = await SharedPreferences.getInstance();
    final receipts = preferences.getStringList(_receiptsKey(user)) ?? [];
    return TrustStatus(
      tickets: preferences.getInt(_ticketsKey(user)) ?? 0,
      points: preferences.getInt(_pointsKey(user)) ?? 0,
      receiptCount: receipts.length,
    );
  }

  static Future<bool> issueReceiptReward(
    SessionUser user,
    String receiptKey,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final receipts = preferences.getStringList(_receiptsKey(user)) ?? [];
    if (receipts.contains(receiptKey)) return false;
    await preferences.setStringList(_receiptsKey(user), [
      ...receipts,
      receiptKey,
    ]);
    await preferences.setInt(
      _ticketsKey(user),
      (preferences.getInt(_ticketsKey(user)) ?? 0) + 1,
    );
    await preferences.setInt(
      _pointsKey(user),
      (preferences.getInt(_pointsKey(user)) ?? 0) + 500,
    );
    return true;
  }

  static Future<bool> consumeTicket(SessionUser user) async {
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getInt(_ticketsKey(user)) ?? 0;
    if (current < 1) return false;
    await preferences.setInt(_ticketsKey(user), current - 1);
    return true;
  }

  static Future<List<LocalIntelReport>> loadReports() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_reportsKey);
    if (encoded == null) return [];
    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      return values
          .map(
            (item) => LocalIntelReport.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addReport(LocalIntelReport report) async {
    final preferences = await SharedPreferences.getInstance();
    final current = await loadReports();
    await preferences.setString(
      _reportsKey,
      jsonEncode(
        [report, ...current].take(20).map((item) => item.toJson()).toList(),
      ),
    );
  }
}

Future<void> openTicketProtectedFeature({
  required BuildContext context,
  required SessionUser? user,
  required String featureName,
  required Widget destination,
  VoidCallback? onRequireLogin,
}) async {
  if (user == null || user.isGuest) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberReceiptGatePage(
          featureName: featureName,
          onRequireLogin: onRequireLogin,
        ),
      ),
    );
    return;
  }

  var status = await TrustWallet.load(user);
  if (!context.mounted) return;
  if (status.tickets < 1) {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReceiptVerificationPage(user: user)),
    );
    if (verified != true || !context.mounted) return;
    status = await TrustWallet.load(user);
  }
  if (!context.mounted || status.tickets < 1) return;

  final useTicket = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: lime,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              '$featureName에\n티켓 1매를 사용할까요?',
              style: const TextStyle(
                color: text,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 ${status.tickets}매 보유 · 사용 후 ${status.tickets - 1}매',
              style: const TextStyle(color: mute, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('티켓 사용하고 시작'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('다음에 할게요'),
            ),
          ],
        ),
      ),
    ),
  );
  if (useTicket != true || !context.mounted) return;
  final consumed = await TrustWallet.consumeTicket(user);
  if (!consumed || !context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
}

class MemberReceiptGatePage extends StatelessWidget {
  final String featureName;
  final VoidCallback? onRequireLogin;

  const MemberReceiptGatePage({
    super.key,
    required this.featureName,
    this.onRequireLogin,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: lime,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '$featureName은\n인증 회원 전용이에요.',
          style: const TextStyle(
            color: text,
            fontSize: 27,
            height: 1.16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '알바·브로커 후기를 줄이기 위해 회원가입과 영수증 인증을 모두 필요로 합니다.',
          style: TextStyle(color: mute, fontSize: 12, height: 1.55),
        ),
        const SizedBox(height: 22),
        const _GateStep(
          number: '1',
          title: '무료 회원가입',
          body: '진단 기록과 티켓을 계정에 안전하게 연결',
        ),
        const _GateStep(
          number: '2',
          title: '영수증·성적표 인증',
          body: '수강 영수증과 실제 학습 후기를 함께 제출',
        ),
        const _GateStep(
          number: '3',
          title: '진단 티켓 1매',
          body: '영수증 1건당 대입전략 또는 고교탐색 1회',
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onRequireLogin?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
          ),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('회원가입·로그인하기'),
        ),
      ],
    ),
  );
}

class _GateStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _GateStep({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: navy,
          foregroundColor: Colors.white,
          child: Text(number, style: const TextStyle(fontSize: 11)),
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
              Text(body, style: const TextStyle(color: mute, fontSize: 10)),
            ],
          ),
        ),
      ],
    ),
  );
}

class ReceiptVerificationPage extends StatefulWidget {
  final SessionUser user;

  const ReceiptVerificationPage({super.key, required this.user});

  @override
  State<ReceiptVerificationPage> createState() =>
      _ReceiptVerificationPageState();
}

class _ReceiptVerificationPageState extends State<ReceiptVerificationPage> {
  final formKey = GlobalKey<FormState>();
  final academy = TextEditingController();
  final receiptNumber = TextEditingController();
  final amount = TextEditingController();
  final review = TextEditingController();
  PlatformFile? proofFile;
  DateTime paidAt = DateTime.now();
  int rating = 4;
  bool submitting = false;

  @override
  void dispose() {
    academy.dispose();
    receiptNumber.dispose();
    amount.dispose();
    review.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final selected = result?.files.firstOrNull;
    if (selected == null) return;
    if (selected.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('10MB 이하 이미지로 올려 주세요.')));
      }
      return;
    }
    setState(() => proofFile = selected);
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: paidAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => paidAt = selected);
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (proofFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('영수증 또는 성적표 이미지를 첨부해 주세요.')));
      return;
    }
    setState(() => submitting = true);
    final receiptKey = [
      academy.text.trim().toLowerCase(),
      receiptNumber.text.trim().toLowerCase(),
      amount.text.trim(),
      '${paidAt.year}-${paidAt.month}-${paidAt.day}',
    ].join('|');
    final issued = await TrustWallet.issueReceiptReward(
      widget.user,
      receiptKey,
    );
    if (!mounted) return;
    setState(() => submitting = false);
    if (!issued) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미 보상을 받은 영수증입니다.')));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.verified_rounded, color: lime, size: 36),
        title: const Text('인증 보상이 지급됐어요'),
        content: const Text('진단 티켓 1매와 교육 포인트 500P가 적립됐습니다.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, title: const Text('영수증·성적표 인증')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          const Text(
            '실제 수강 경험을\n안전하게 인증해요.',
            style: TextStyle(
              color: text,
              fontSize: 26,
              height: 1.16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.user.name}님 계정에 티켓과 포인트가 지급됩니다.',
            style: const TextStyle(color: mute, fontSize: 11),
          ),
          const SizedBox(height: 18),
          _ProofRewardBanner(),
          const SizedBox(height: 18),
          const _FormLabel('학원·강사명'),
          TextFormField(
            controller: academy,
            decoration: _inputDecoration(hint: '예: ○○수학관'),
            validator: (value) =>
                (value?.trim().length ?? 0) < 2 ? '학원·강사명을 입력해 주세요.' : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('영수증 번호'),
          TextFormField(
            controller: receiptNumber,
            decoration: _inputDecoration(hint: '결제 영수증의 승인·영수 번호'),
            validator: (value) => (value?.trim().length ?? 0) < 4
                ? '영수증 번호를 4자 이상 입력해 주세요.'
                : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('결제 금액'),
          TextFormField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(hint: '예: 280000'),
            validator: (value) =>
                int.tryParse((value ?? '').replaceAll(',', '')) == null
                ? '숫자로 입력해 주세요.'
                : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('결제일'),
          OutlinedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              '${paidAt.year}.${paidAt.month.toString().padLeft(2, '0')}.${paidAt.day.toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 14),
          const _FormLabel('영수증·성적표 이미지'),
          OutlinedButton.icon(
            onPressed: _pickProof,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: Icon(
              proofFile == null
                  ? Icons.add_photo_alternate_outlined
                  : Icons.check_circle,
              color: proofFile == null ? mute : lime,
            ),
            label: Text(proofFile?.name ?? '이미지 선택'),
          ),
          const SizedBox(height: 17),
          const _FormLabel('실제 수강 후기'),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xffF2A900),
                ),
              ),
            ),
          ),
          TextFormField(
            controller: review,
            maxLines: 4,
            decoration: _inputDecoration(
              hint: '수업·관리 방식과 실제로 도움 받은 점을 20자 이상 적어 주세요.',
            ),
            validator: (value) =>
                (value?.trim().length ?? 0) < 20 ? '후기를 20자 이상 입력해 주세요.' : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'MVP에서는 이미지·필수값·중복을 기기에서 사전 확인합니다. 운영 버전은 OCR, 결제자 대조, 관리자 검수 후 게시됩니다.',
            style: TextStyle(color: mute, fontSize: 9, height: 1.5),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
            ),
            icon: const Icon(Icons.verified_outlined),
            label: Text(submitting ? '중복·형식 확인 중...' : '인증하고 티켓 1매·500P 받기'),
          ),
        ],
      ),
    ),
  );
}

class _ProofRewardBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.receipt_long_outlined, color: Color(0xffAFC5FF), size: 28),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '영수증 1건 = 진단 티켓 1매',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '실제 후기 작성 시 교육 포인트 500P',
                style: TextStyle(color: Color(0xffCAD4E6), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TrustWalletCard extends StatefulWidget {
  final SessionUser? user;
  final VoidCallback? onRequireLogin;
  final bool embedded;

  const TrustWalletCard({
    super.key,
    this.user,
    this.onRequireLogin,
    this.embedded = false,
  });

  @override
  State<TrustWalletCard> createState() => _TrustWalletCardState();
}

class _TrustWalletCardState extends State<TrustWalletCard> {
  Future<TrustStatus>? status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final user = widget.user;
    status = user == null || user.isGuest ? null : TrustWallet.load(user);
  }

  Future<void> _open() async {
    final user = widget.user;
    if (user == null || user.isGuest) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberReceiptGatePage(
            featureName: '영수증 인증 티켓',
            onRequireLogin: widget.onRequireLogin,
          ),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptVerificationPage(user: user)),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (user == null || user.isGuest) {
      return _WalletShell(
        title: '영수증 인증 진단 티켓',
        body: '영수증 1건 인증하면 무료 진단 1회',
        trailing: '안내',
        embedded: widget.embedded,
        onTap: _open,
      );
    }
    return FutureBuilder<TrustStatus>(
      future: status,
      builder: (context, snapshot) {
        final value =
            snapshot.data ??
            const TrustStatus(tickets: 0, points: 0, receiptCount: 0);
        return _WalletShell(
          title: '진단 티켓 ${value.tickets}매',
          body: '보유 ${value.points}P · 영수증 인증 ${value.receiptCount}건',
          trailing: '영수증 인증',
          embedded: widget.embedded,
          onTap: _open,
        );
      },
    );
  }
}

class _WalletShell extends StatefulWidget {
  final String title;
  final String body;
  final String trailing;
  final VoidCallback onTap;
  final bool embedded;

  const _WalletShell({
    required this.title,
    required this.body,
    required this.trailing,
    required this.onTap,
    this.embedded = false,
  });

  @override
  State<_WalletShell> createState() => _WalletShellState();
}

class _WalletShellState extends State<_WalletShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _receiptReveal;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _receiptReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.78, curve: Curves.easeOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller
        ..stop()
        ..value = 1;
    } else {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    excludeSemantics: true,
    label: '${widget.title}. ${widget.body}. ${widget.trailing}',
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.embedded ? 12 : 0,
            vertical: widget.embedded ? 12 : 0,
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 13, 12),
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffD6E3FB)),
          ),
          child: Row(
            children: [
              _ReceiptTicketAnimation(reveal: _receiptReveal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        color: mute,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: widget.embedded
                      ? Colors.white
                      : const Color(0xffFFF7DF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xffD1DDF3)),
                ),
                child: Text(
                  widget.trailing,
                  style: const TextStyle(
                    color: lime,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReceiptTicketAnimation extends StatelessWidget {
  final Animation<double> reveal;

  const _ReceiptTicketAnimation({required this.reveal});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      key: const Key('receipt-ticket-animation'),
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (context, _) {
          final progress = reveal.value.clamp(0.0, 1.0).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 2 - (progress * 2),
                child: Transform.scale(
                  scale: 0.92 + (0.08 * progress),
                  child: _ReceiptTicketPulse(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff4384F8), Color(0xff1A57D1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xff7CB0FF)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(
                              19,
                              71,
                              158,
                              0.18 + (0.16 * progress),
                            ),
                            blurRadius: 10 + (5 * progress),
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  key: const Key('receipt-ticket-paper'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF4C4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffE2B53D)),
                  ),
                  child: const Text(
                    '+1 TICKET',
                    style: TextStyle(
                      color: Color(0xff755000),
                      fontSize: 7,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _ReceiptTicketPulse extends StatefulWidget {
  final Widget child;

  const _ReceiptTicketPulse({required this.child});

  @override
  State<_ReceiptTicketPulse> createState() => _ReceiptTicketPulseState();
}

class _ReceiptTicketPulseState extends State<_ReceiptTicketPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller
        ..stop()
        ..value = 0;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final value = Curves.easeInOut.transform(_controller.value);
      return Transform.translate(
        offset: Offset(0, -2 * value),
        child: Transform.scale(
          scale: 1 + (0.025 * value),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                widget.child,
                Positioned(
                  top: -7,
                  right: -7,
                  child: Opacity(
                    opacity: 0.3 + (0.7 * value),
                    child: Transform.scale(
                      scale: 0.7 + (0.3 * value),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xff8EB6FF),
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ReceiptEdgeClipper extends CustomClipper<Path> {
  const _ReceiptEdgeClipper();

  @override
  Path getClip(Size size) {
    const toothWidth = 4.0;
    const toothDepth = 3.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - toothDepth);
    var x = size.width;
    var up = false;
    while (x > 0) {
      x = (x - toothWidth).clamp(0.0, size.width).toDouble();
      path.lineTo(x, size.height - (up ? toothDepth : 0));
      up = !up;
    }
    return path
      ..lineTo(0, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ValueAcademy {
  final String name;
  final String region;
  final String subject;
  final int monthlyFee;
  final String format;
  final String signal;
  final String teacherType;

  const ValueAcademy({
    required this.name,
    required this.region,
    required this.subject,
    required this.monthlyFee,
    required this.format,
    required this.signal,
    required this.teacherType,
  });
}

const valueAcademies = <ValueAcademy>[
  ValueAcademy(
    name: '강남권 수학 소수정예 A',
    region: '강남',
    subject: '수학',
    monthlyFee: 28,
    format: '6명 이하·오답 클리닉',
    signal: '4등급 탈출 후기 유형',
    teacherType: '개념 진단형 강사',
  ),
  ValueAcademy(
    name: '목동권 영어 내신반 B',
    region: '목동',
    subject: '영어',
    monthlyFee: 24,
    format: '학교별 내신·주 2회',
    signal: '서술형 오답 후기 유형',
    teacherType: '직접 첨삭형 강사',
  ),
  ValueAcademy(
    name: '노원권 국어 독서논술 C',
    region: '노원',
    subject: '국어',
    monthlyFee: 19,
    format: '독서·비문학 반복',
    signal: '독해 시간 단축 후기 유형',
    teacherType: '질문 유도형 강사',
  ),
  ValueAcademy(
    name: '분당권 과학 탐구반 D',
    region: '분당',
    subject: '과학',
    monthlyFee: 30,
    format: '실험·내신 서술형',
    signal: '개념 연결 후기 유형',
    teacherType: '실험 시각화형 강사',
  ),
  ValueAcademy(
    name: '송파권 수학 오답관리 E',
    region: '송파',
    subject: '수학',
    monthlyFee: 26,
    format: '매일 20분 오답 체크',
    signal: '오답 재발 감소 후기 유형',
    teacherType: '피드백 밀착형 강사',
  ),
  ValueAcademy(
    name: '마포권 영어 소수정예 F',
    region: '마포',
    subject: '영어',
    monthlyFee: 22,
    format: '문법·독해 개별 처방',
    signal: '기초 복구 후기 유형',
    teacherType: '단계별 설명형 강사',
  ),
];

class ValueAcademyHero extends StatelessWidget {
  final AcademyStudentProfile? profile;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenMap;
  final VoidCallback onQuickCheck;

  const ValueAcademyHero({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onOpenMap,
    required this.onQuickCheck,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffD9E4F5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: lime),
              SizedBox(width: 5),
              Text(
                '맞춤 학원 추천',
                style: TextStyle(
                  color: lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          '학원, 가치 있게\n같이 찾기',
          style: TextStyle(
            color: text,
            fontSize: 25,
            height: 1.18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '학생의 학년·과목·학습 스타일을 바탕으로\n꼭 맞는 학원을 추천해 드려요.',
          style: TextStyle(color: mute, fontSize: 12, height: 1.55),
        ),
        const SizedBox(height: 18),
        _AcademyProfileInline(profile: profile, onTap: onEditProfile),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onOpenMap,
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('학원 지도 보기'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onQuickCheck,
              style: OutlinedButton.styleFrom(
                foregroundColor: lime,
                side: const BorderSide(color: Color(0xffA9C4FC)),
                minimumSize: const Size(86, 48),
              ),
              child: const Text('3초 진단'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AcademyProfileInline extends StatelessWidget {
  final AcademyStudentProfile? profile;
  final VoidCallback onTap;

  const _AcademyProfileInline({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final registered = profile != null;
    final title = registered
        ? '${profile!.name} · ${profile!.grade}'
        : '학생 정보 등록';
    final detail = registered
        ? '${profile!.school} · ${profile!.subjects.join('·')}'
        : '나에게 맞는 학원을 추천받아 보세요';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffD9E4F5)),
          ),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  registered
                      ? Icons.person_outline_rounded
                      : Icons.person_add_alt_1_outlined,
                  size: 19,
                  color: lime,
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
                    const SizedBox(height: 1),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mute, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 19, color: mute),
            ],
          ),
        ),
      ),
    );
  }
}

class ValueAcademyMapPage extends StatefulWidget {
  const ValueAcademyMapPage({super.key});

  @override
  State<ValueAcademyMapPage> createState() => _ValueAcademyMapPageState();
}

class _ValueAcademyMapPageState extends State<ValueAcademyMapPage> {
  String region = '전체';
  String subject = '전체';
  double maxFee = 30;
  bool resultFirst = false;

  List<ValueAcademy> get visible {
    final result = valueAcademies.where((academy) {
      return (region == '전체' || academy.region == region) &&
          (subject == '전체' || academy.subject == subject) &&
          academy.monthlyFee <= maxFee;
    }).toList();
    result.sort(
      (a, b) => resultFirst
          ? a.signal.compareTo(b.signal)
          : a.monthlyFee.compareTo(b.monthlyFee),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final items = visible;
    final mapQuery =
        '${region == '전체' ? '서울' : region} ${subject == '전체' ? '학원' : '$subject 학원'}';
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(backgroundColor: mist, title: const Text('갓성비 학원·강사 맵')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            '진짜 비교할 수 있게\n예산부터 고르세요.',
            style: TextStyle(
              color: text,
              fontSize: 25,
              height: 1.16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '교습비·통학권·강사 유형과 인증 후기 신호를 함께 비교합니다.',
            style: TextStyle(color: mute, fontSize: 11),
          ),
          const SizedBox(height: 17),
          _FilterStrip(
            label: '동네',
            values: const ['전체', '강남', '목동', '노원', '송파', '마포', '분당'],
            selected: region,
            onChanged: (value) => setState(() => region = value),
          ),
          const SizedBox(height: 9),
          _FilterStrip(
            label: '과목',
            values: const ['전체', '수학', '영어', '국어', '과학'],
            selected: subject,
            onChanged: (value) => setState(() => subject = value),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      '월 수강료 상한',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${maxFee.round()}만원',
                      style: const TextStyle(
                        color: lime,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: maxFee,
                  min: 15,
                  max: 30,
                  divisions: 15,
                  label: '${maxFee.round()}만원',
                  onChanged: (value) => setState(() => maxFee = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KakaoMapPanel(query: mapQuery, placeCount: items.length),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  '조건에 맞는 데모 ${items.length}곳',
                  style: const TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('상승 후기 우선', style: TextStyle(fontSize: 9)),
                selected: resultFirst,
                onSelected: (value) => setState(() => resultFirst = value),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (items.isEmpty)
            const _NoAcademyResult()
          else
            ...items.map((academy) => _ValueAcademyCard(academy: academy)),
          const SizedBox(height: 8),
          const Text(
            '현재는 알고리즘·화면 검증을 위한 익명 데모 데이터입니다. 실제 게시 시 교육청 교습비, 영수증, 검수된 성적표 후기를 연결해야 합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 9, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterStrip({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: mute, fontSize: 9)),
      const SizedBox(height: 5),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: values
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: (_) => onChanged(value),
                    selectedColor: lavender,
                    checkmarkColor: lime,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

class _ValueAcademyCard extends StatelessWidget {
  final ValueAcademy academy;

  const _ValueAcademyCard({required this.academy});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE2E6EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                academy.name,
                style: const TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffEAF8F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '월 ${academy.monthlyFee}만',
                style: const TextStyle(
                  color: Color(0xff168A73),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '${academy.region} · ${academy.subject} · ${academy.format}',
          style: const TextStyle(color: mute, fontSize: 10),
        ),
        const SizedBox(height: 10),
        _AcademySignal(icon: Icons.trending_up_rounded, value: academy.signal),
        _AcademySignal(
          icon: Icons.record_voice_over_outlined,
          value: academy.teacherType,
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () => openKakaoMapSearch(
            context,
            '${academy.region} ${academy.subject} 학원',
          ),
          icon: const Icon(Icons.location_on_outlined, size: 17),
          label: const Text('카카오맵에서 후보 비교'),
        ),
      ],
    ),
  );
}

class _AcademySignal extends StatelessWidget {
  final IconData icon;
  final String value;

  const _AcademySignal({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, color: lime, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(value, style: const TextStyle(color: text, fontSize: 10)),
        ),
      ],
    ),
  );
}

class _NoAcademyResult extends StatelessWidget {
  const _NoAcademyResult();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      '조건에 맞는 데모 후보가 없어요. 예산 상한을 높이거나 동네·과목을 바꿔 보세요.',
      style: TextStyle(color: mute, fontSize: 11, height: 1.5),
    ),
  );
}

Future<void> showQuickEscapeDiagnosis(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: .92,
        child: QuickEscapeDiagnosis(),
      ),
    );

class QuickEscapeDiagnosis extends StatefulWidget {
  const QuickEscapeDiagnosis({super.key});

  @override
  State<QuickEscapeDiagnosis> createState() => _QuickEscapeDiagnosisState();
}

class _QuickEscapeDiagnosisState extends State<QuickEscapeDiagnosis> {
  String grade = '고1';
  String concern = '수학 4등급 탈출';
  bool result = false;

  (String, String, String, String) get report => switch (concern) {
    '수학 4등급 탈출' => (
      '개념 소수정예 + 1:1 오답 클리닉',
      '개념을 짧게 확인하고 매주 누적 오답을 강사가 직접 확인하는 조합',
      '진도보다 오답 재발률·주간 테스트를 물어보세요.',
      '수학',
    ),
    '영어 내신 서술형' => (
      '학교별 단과 + 주 1회 서술 첨삭',
      '교과서·부교재 지문을 단원별로 분리하고 직접 첨삭을 받는 조합',
      '재원 학교 기출·서술 첨삭 주기를 확인하세요.',
      '영어',
    ),
    '국어 비문학 시간 부족' => (
      '독해 시간훈련 + 근거 표시 피드백',
      '매일 짧은 지문으로 시간을 측정하고 오답 근거를 설명하는 조합',
      '풀이 기술만 주는지, 근거 설명을 시키는지 확인하세요.',
      '국어',
    ),
    '고교 선택이 막막함' => (
      '진학 상담 + 학교 환경 탐색',
      '통학·내신·진로 활동 우선순위를 정한 후 고교 환경을 비교하는 조합',
      '학교별 과목 개설·진학 지도 자료를 공식 채널에서 확인하세요.',
      '입시',
    ),
    _ => (
      '주간 학습코치 + 과목 단과',
      '계획을 30분 단위로 쪼개고 전문 강사의 피드백을 받는 조합',
      '출결만 관리하는지, 완료율과 오답을 함께 보는지 확인하세요.',
      '종합',
    ),
  };

  @override
  Widget build(BuildContext context) => Material(
    color: mist,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xffCBD2DE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: coral),
            const SizedBox(width: 7),
            Text(
              result ? '3초 비상구 리포트' : '가입 없이 3초 진단',
              style: const TextStyle(
                color: coral,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (!result) ...[
          const Text(
            '학년과 고민만\n고르면 됩니다.',
            style: TextStyle(
              color: text,
              fontSize: 26,
              height: 1.16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '학년',
            style: TextStyle(color: text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: ['중1', '중2', '중3', '고1', '고2', '고3']
                .map(
                  (item) => ChoiceChip(
                    label: Text(item),
                    selected: grade == item,
                    onSelected: (_) => setState(() => grade = item),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            '지금 가장 급한 고민',
            style: TextStyle(color: text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: concern,
            onChanged: (value) {
              if (value != null) {
                setState(() => concern = value);
              }
            },
            child: Column(
              children:
                  [
                        '수학 4등급 탈출',
                        '영어 내신 서술형',
                        '국어 비문학 시간 부족',
                        '학습 계획이 안 지켜짐',
                        '고교 선택이 막막함',
                      ]
                      .map(
                        (item) => RadioListTile<String>(
                          value: item,
                          title: Text(
                            item,
                            style: const TextStyle(fontSize: 12),
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
          FilledButton.icon(
            onPressed: () => setState(() => result = true),
            style: FilledButton.styleFrom(
              backgroundColor: coral,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
            ),
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('3초 리포트 보기'),
          ),
        ] else ...[
          Text(
            '$grade · $concern',
            style: const TextStyle(color: mute, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            report.$1,
            style: const TextStyle(
              color: text,
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _QuickReportBlock(
            icon: Icons.groups_2_outlined,
            title: '동일 고민 후기에서 반복된 조합',
            body: report.$2,
          ),
          _QuickReportBlock(
            icon: Icons.fact_check_outlined,
            title: '상담 전 꼭 확인',
            body: report.$3,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffFFF4EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '초기 MVP는 익명 데모 조합입니다. 영수증·성적표 후기가 누적되면 지역·학년·성적대별 검수 조합으로 교체합니다.',
              style: TextStyle(
                color: Color(0xff9A4A22),
                fontSize: 9,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(builder: (_) => const ValueAcademyMapPage()),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: Text('${report.$4} 갓성비 지도 보기'),
          ),
          TextButton(
            onPressed: () => setState(() => result = false),
            child: const Text('다시 진단'),
          ),
        ],
      ],
    ),
  );
}

class _QuickReportBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _QuickReportBlock({
    required this.icon,
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
        Icon(icon, color: lime),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
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

class LocalIntelReport {
  final String category;
  final String region;
  final String title;
  final String body;
  final String proofStatus;
  final String time;
  final bool isDemo;

  const LocalIntelReport({
    required this.category,
    required this.region,
    required this.title,
    required this.body,
    required this.proofStatus,
    required this.time,
    this.isDemo = false,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'region': region,
    'title': title,
    'body': body,
    'proofStatus': proofStatus,
    'time': time,
    'isDemo': isDemo,
  };

  factory LocalIntelReport.fromJson(Map<String, dynamic> json) =>
      LocalIntelReport(
        category: json['category'] as String,
        region: json['region'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        proofStatus: json['proofStatus'] as String,
        time: json['time'] as String,
        isDemo: json['isDemo'] as bool? ?? false,
      );
}

const demoIntelReports = <LocalIntelReport>[
  LocalIntelReport(
    category: '핫딜',
    region: '목동',
    title: '영어 단과 레테비 면제 제보',
    body: '이번 주 상담 예약자 대상으로 레벨테스트 비용 면제 안내를 받았다는 제보입니다. 학원에 직접 재확인해 주세요.',
    proofStatus: '예시 게시글 · 확인 전',
    time: '방금',
    isDemo: true,
  ),
  LocalIntelReport(
    category: '비용',
    region: '강남',
    title: '수학 소수정예 월 교습비 제보',
    body: '교재비·클리닉비를 포함하면 상담 금액과 실제 결제 금액이 다르다는 유형의 제보입니다.',
    proofStatus: '예시 게시글 · 영수증 확인 필요',
    time: '20분 전',
    isDemo: true,
  ),
  LocalIntelReport(
    category: '마감',
    region: '분당',
    title: '과학 내신반 대기 접수 제보',
    body: '중간고사 대비반 추가 반 개설 문의가 많아 대기 명단을 받고 있다는 제보입니다.',
    proofStatus: '예시 게시글 · 재확인 필요',
    time: '1시간 전',
    isDemo: true,
  ),
];

class Community extends StatefulWidget {
  final SessionUser? user;
  final VoidCallback? onRequireLogin;

  const Community({super.key, this.user, this.onRequireLogin});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  String category = '전체';
  List<LocalIntelReport> reports = [...demoIntelReports];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await TrustWallet.loadReports();
    if (mounted) setState(() => reports = [...stored, ...demoIntelReports]);
  }

  Future<void> _submitReport() async {
    final user = widget.user;
    if (user == null || user.isGuest) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberReceiptGatePage(
            featureName: '리얼 제보 작성',
            onRequireLogin: widget.onRequireLogin,
          ),
        ),
      );
      return;
    }
    var status = await TrustWallet.load(user);
    if (!mounted) return;
    if (!status.hasVerifiedReceipt) {
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => ReceiptVerificationPage(user: user)),
      );
      if (verified != true || !mounted) return;
      status = await TrustWallet.load(user);
    }
    if (!status.hasVerifiedReceipt || !mounted) return;
    final report = await Navigator.push<LocalIntelReport>(
      context,
      MaterialPageRoute(builder: (_) => const IntelReportForm()),
    );
    if (report == null || !mounted) return;
    await TrustWallet.addReport(report);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = reports
        .where((item) => category == '전체' || item.category == category)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '목동 학원 이야기',
                    style: TextStyle(
                      color: text,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '우리 동네 학원 정보를 함께 나눠요.',
                    style: TextStyle(color: mute, fontSize: 11),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('글쓰기'),
            ),
          ],
        ),
        const SizedBox(height: 19),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['전체', '핫딜', '비용', '마감', '수업']
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      onSelected: (_) => setState(() => category = item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '최신 글',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...visible.map((item) => _IntelFeedCard(item: item)),
      ],
    );
  }
}

class _RollingIntelHook extends StatelessWidget {
  final List<LocalIntelReport> items;

  const _RollingIntelHook({required this.items});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 108,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 9),
      itemBuilder: (_, index) {
        final item = items[index];
        return Container(
          width: 248,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE · ${item.region} · ${item.category}',
                style: const TextStyle(color: Color(0xffAFC5FF), fontSize: 9),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                item.time,
                style: const TextStyle(color: Color(0xffAAB4C7), fontSize: 8),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _IntelFeedCard extends StatelessWidget {
  final LocalIntelReport item;

  const _IntelFeedCard({required this.item});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () =>
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('게시글 상세 화면은 준비 중입니다.'))),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE6EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${item.region} · ${item.category}',
                style: const TextStyle(color: mute, fontSize: 10),
              ),
              const SizedBox(width: 5),
              const Text('·', style: TextStyle(color: Color(0xffC3CAD6))),
              const SizedBox(width: 5),
              Text(
                item.time,
                style: const TextStyle(color: mute, fontSize: 10),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('신고가 접수됐습니다.'))),
                tooltip: '신고',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: mute,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: const TextStyle(
              color: text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: mute, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                item.isDemo
                    ? Icons.info_outline_rounded
                    : Icons.verified_outlined,
                color: item.isDemo ? coral : lime,
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.proofStatus,
                  style: TextStyle(
                    color: item.isDemo ? coral : lime,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.favorite_border_rounded, color: mute, size: 16),
              const SizedBox(width: 4),
              const Text('공감', style: TextStyle(color: mute, fontSize: 9)),
              const SizedBox(width: 12),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: mute,
                size: 15,
              ),
              const SizedBox(width: 4),
              const Text('댓글', style: TextStyle(color: mute, fontSize: 9)),
            ],
          ),
        ],
      ),
    ),
  );
}

class IntelReportForm extends StatefulWidget {
  const IntelReportForm({super.key});

  @override
  State<IntelReportForm> createState() => _IntelReportFormState();
}

class _IntelReportFormState extends State<IntelReportForm> {
  String category = '비용';
  String region = '강남';
  final academy = TextEditingController();
  final detail = TextEditingController();
  PlatformFile? evidence;

  @override
  void dispose() {
    academy.dispose();
    detail.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result?.files.firstOrNull != null) {
      setState(() => evidence = result!.files.first);
    }
  }

  void _submit() {
    final label = academy.text.trim();
    final body = detail.text.trim();
    final phone = RegExp(r'01[016789][-\s]?\d{3,4}[-\s]?\d{4}');
    if (label.length < 2 || body.length < 20 || evidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학원명, 20자 이상 내용, 증빙 이미지를 확인해 주세요.')),
      );
      return;
    }
    if (phone.hasMatch(body)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('개인 연락처는 제보에 포함할 수 없어요.')));
      return;
    }
    Navigator.pop(
      context,
      LocalIntelReport(
        category: category,
        region: region,
        title: '${_maskAcademy(label)} $category 제보',
        body: body,
        proofStatus: '영수증 인증 회원 · 운영진 검수 대기',
        time: '방금',
      ),
    );
  }

  String _maskAcademy(String value) {
    if (value.length <= 2) return '${value.substring(0, 1)}○';
    final middle = List.filled(value.length - 2, '○').join();
    return '${value.substring(0, 1)}$middle${value.substring(value.length - 1)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, title: const Text('우리 동네 제보')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const Text(
          '증빙은 확실하게,\n표현은 안전하게.',
          style: TextStyle(
            color: text,
            fontSize: 25,
            height: 1.17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '제보는 바로 실명 게시되지 않고, 학원명 익명화와 운영진 검수를 거칩니다.',
          style: TextStyle(color: mute, fontSize: 11),
        ),
        const SizedBox(height: 18),
        const _FormLabel('제보 유형'),
        Wrap(
          spacing: 7,
          children: ['핫딜', '비용', '마감', '수업']
              .map(
                (item) => ChoiceChip(
                  label: Text(item),
                  selected: category == item,
                  onSelected: (_) => setState(() => category = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const _FormLabel('지역'),
        DropdownButtonFormField<String>(
          initialValue: region,
          decoration: _inputDecoration(),
          items: ['강남', '목동', '노원', '송파', '마포', '분당', '기타']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => region = value!),
        ),
        const SizedBox(height: 16),
        const _FormLabel('학원·강사명'),
        TextField(
          controller: academy,
          decoration: _inputDecoration(hint: '게시시 자동으로 익명 처리됩니다.'),
        ),
        const SizedBox(height: 16),
        const _FormLabel('제보 내용'),
        TextField(
          controller: detail,
          minLines: 4,
          maxLines: 7,
          decoration: _inputDecoration(
            hint: '날짜·금액·상담 내용 등 직접 확인한 사실만 적어 주세요.',
          ),
        ),
        const SizedBox(height: 16),
        const _FormLabel('영수증·안내문 증빙'),
        OutlinedButton.icon(
          onPressed: _pick,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          icon: Icon(
            evidence == null
                ? Icons.add_photo_alternate_outlined
                : Icons.check_circle,
            color: evidence == null ? mute : lime,
          ),
          label: Text(evidence?.name ?? '이미지 선택'),
        ),
        const SizedBox(height: 14),
        const Text(
          '미확인 비방·명예훼손·개인정보는 게시하지 않습니다. 지속적인 허위 제보는 계정 제한 대상입니다.',
          style: TextStyle(color: mute, fontSize: 9, height: 1.5),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
          ),
          icon: const Icon(Icons.send_outlined),
          label: const Text('검수 요청하기'),
        ),
      ],
    ),
  );
}
