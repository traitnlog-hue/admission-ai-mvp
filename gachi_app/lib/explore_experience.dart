part of 'main.dart';

class Explore extends StatefulWidget {
  final VoidCallback onOpenCoach;

  const Explore({super.key, required this.onOpenCoach});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final TextEditingController _searchController = TextEditingController();
  String category = '전체';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tools = <_ExploreToolData>[
      _ExploreToolData(
        category: '진단',
        title: 'GACHI LEVEL',
        description: '국어·영어·수학 20문항으로 현재 학습 수준을 확인해요.',
        meta: '약 15분 · 무료',
        badge: '학습 진단',
        icon: Icons.quiz_outlined,
        color: lime,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LevelTest()),
        ),
      ),
      _ExploreToolData(
        category: '입시',
        title: 'GACHI ADMISSION',
        description: '희망 대학·전공과 성적을 입력하고 지원 전략 GAP을 분석해요.',
        meta: '약 5분 · 맞춤 분석',
        badge: '대입 전략',
        icon: Icons.school_outlined,
        color: const Color(0xff5146E5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CoachAdmissionIntake()),
        ),
      ),
      _ExploreToolData(
        category: '진로',
        title: 'GACHI HIGH',
        description: '학습 성향과 통학 조건을 바탕으로 맞는 고교 환경을 찾아요.',
        meta: '약 3분 · 환경 추천',
        badge: '고교 탐색',
        icon: Icons.domain_outlined,
        color: const Color(0xffE75B2B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HighSchoolFinder()),
        ),
      ),
      _ExploreToolData(
        category: '입시',
        title: 'COACH+',
        description: '성적과 학생부를 점검하고 이번 주 실행 과제를 만들어요.',
        meta: '주간 플랜 · 실행 관리',
        badge: 'AI 코치',
        icon: Icons.route_outlined,
        color: const Color(0xff168A73),
        onTap: widget.onOpenCoach,
      ),
      _ExploreToolData(
        category: '정보',
        title: '2026 입시 인사이트',
        description: '중1부터 고3까지 교육부·교육청의 공식 정보를 학년별로 봐요.',
        meta: '공식 출처 · 원문 연결',
        badge: '최신 정보',
        icon: Icons.newspaper_outlined,
        color: const Color(0xff2765A8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InsightsHub(initialGrade: '고3'),
          ),
        ),
      ),
    ];
    final query = _searchController.text.trim().toLowerCase();
    final visible = tools.where((tool) {
      final matchesCategory = category == '전체' || tool.category == category;
      final searchable = '${tool.title} ${tool.description} ${tool.badge}'
          .toLowerCase();
      return matchesCategory && (query.isEmpty || searchable.contains(query));
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
      children: [
        const _Logo(),
        const SizedBox(height: 24),
        const Text(
          '오늘 무엇을\n도와드릴까요?',
          style: TextStyle(
            color: text,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '진단부터 입시 전략, 고교 탐색까지 필요한 활동을 바로 시작하세요.',
          style: TextStyle(color: mute, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '진단, 대학, 고교, 인사이트 검색',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '검색어 지우기',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['전체', '진단', '입시', '진로', '정보']
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      onSelected: (_) => setState(() => category = item),
                      selectedColor: lavender,
                      checkmarkColor: lime,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _AssistantBanner(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatAssistantPage()),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                '전체 활동',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${visible.length}개',
              style: const TextStyle(color: mute, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          const _EmptyExploreResult()
        else
          ...visible.map((tool) => _ExploreToolCard(tool: tool)),
      ],
    );
  }
}

class _ExploreToolData {
  final String category;
  final String title;
  final String description;
  final String meta;
  final String badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExploreToolData({
    required this.category,
    required this.title,
    required this.description,
    required this.meta,
    required this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ExploreToolCard extends StatelessWidget {
  final _ExploreToolData tool;

  const _ExploreToolCard({required this.tool});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Material(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(tool.icon, color: tool.color, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tool.color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tool.badge,
                        style: TextStyle(
                          color: tool.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tool.title,
                      style: const TextStyle(
                        color: text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.description,
                      style: const TextStyle(
                        color: mute,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tool.meta,
                      style: TextStyle(color: tool.color, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: mute,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AssistantBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AssistantBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: navy,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GACHI AI에게 물어보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '어떤 활동부터 시작할지 함께 찾아드려요.',
                    style: TextStyle(color: Color(0xffCBD5E7), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class _EmptyExploreResult extends StatelessWidget {
  const _EmptyExploreResult();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, color: mute, size: 32),
        SizedBox(height: 9),
        Text('검색 결과가 없어요.', style: TextStyle(color: text)),
        SizedBox(height: 4),
        Text(
          '다른 검색어 또는 카테고리를 선택해 주세요.',
          style: TextStyle(color: mute, fontSize: 11),
        ),
      ],
    ),
  );
}

class HighSchoolFinder extends StatefulWidget {
  const HighSchoolFinder({super.key});

  @override
  State<HighSchoolFinder> createState() => _HighSchoolFinderState();
}

class _HighSchoolFinderState extends State<HighSchoolFinder> {
  String priority = '내신 관리';
  String environment = '안정적인 분위기';
  String commute = '30분 이내';
  bool submitted = false;

  String get recommendation {
    if (priority == '심화 학습') return '심화 프로그램이 강한 자율형 교육 환경';
    if (priority == '진로 활동') return '과목 선택과 진로 활동이 다양한 일반고';
    return '내신 관리 체계가 안정적인 일반고';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('GACHI HIGH'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const Text(
          '나에게 맞는\n고교 환경 찾기',
          style: TextStyle(
            color: text,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '학교 서열이 아니라 학습 성향과 실행 가능성을 기준으로 추천합니다.',
          style: TextStyle(color: mute, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 22),
        _ChoiceField(
          title: '고교 선택에서 가장 중요한 것',
          values: const ['내신 관리', '심화 학습', '진로 활동'],
          selected: priority,
          onSelected: (value) => setState(() {
            priority = value;
            submitted = false;
          }),
        ),
        _ChoiceField(
          title: '선호하는 학습 분위기',
          values: const ['안정적인 분위기', '경쟁적인 분위기', '자율적인 분위기'],
          selected: environment,
          onSelected: (value) => setState(() {
            environment = value;
            submitted = false;
          }),
        ),
        _ChoiceField(
          title: '가능한 통학 시간',
          values: const ['30분 이내', '60분 이내', '거리 무관'],
          selected: commute,
          onSelected: (value) => setState(() {
            commute = value;
            submitted = false;
          }),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => setState(() => submitted = true),
          icon: const Icon(Icons.auto_graph_rounded),
          label: const Text('맞춤 환경 분석하기'),
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        if (submitted) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffDDE6F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '추천 고교 환경',
                  style: TextStyle(color: lime, fontSize: 11),
                ),
                const SizedBox(height: 7),
                Text(
                  recommendation,
                  style: const TextStyle(
                    color: text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$environment · $commute 조건을 우선으로 학교별 교육과정, 선택과목, 통학 가능성을 비교해 보세요.',
                  style: const TextStyle(
                    color: mute,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 13),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: lime, size: 17),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '다음 단계: 관심 학교 3곳의 교육과정 편성표와 최근 설명회 자료를 확인하세요.',
                        style: TextStyle(
                          color: text,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _ChoiceField extends StatelessWidget {
  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChoiceField({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: values
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                  selectedColor: lavender,
                  checkmarkColor: lime,
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class ChatAssistantPage extends StatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> messages = const [
    _ChatMessage(
      text: '안녕하세요! 진단, 목표 플랜, 대입 전략, 고교 선택 중 무엇을 도와드릴까요?',
      fromUser: false,
    ),
  ].toList();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? quickText]) {
    final value = (quickText ?? _controller.text).trim();
    if (value.isEmpty) return;
    _controller.clear();
    setState(() {
      messages.add(_ChatMessage(text: value, fromUser: true));
      messages.add(_ChatMessage(text: _reply(value), fromUser: false));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _reply(String input) {
    final message = input.toLowerCase();
    if (message.contains('진단') || message.contains('레벨')) {
      return '무료 진단은 국어·영어·수학 중 한 과목을 선택해 20문항을 풀어요. 탐색 탭의 GACHI LEVEL에서 시작할 수 있습니다.';
    }
    if (message.contains('목표') || message.contains('플랜')) {
      return '홈에서 목표 추가를 누르고 과목, 기간, 주간 시간, 약점과 성공 기준을 입력해 보세요. 입력 즉시 이번 주 실행 과제가 만들어집니다.';
    }
    if (message.contains('대학') ||
        message.contains('입시') ||
        message.contains('전형')) {
      return '탐색 탭의 GACHI ADMISSION에서 희망 대학·전공, 내신과 모의고사 성적을 입력하면 우선 전략과 이번 주 보완 과제를 확인할 수 있어요.';
    }
    if (message.contains('고교') || message.contains('학교')) {
      return 'GACHI HIGH에서 내신 관리, 심화 학습, 진로 활동 중 우선순위를 고르면 적합한 고교 환경과 확인할 항목을 안내해 드려요.';
    }
    if (message.contains('2026') ||
        message.contains('교육청') ||
        message.contains('정보')) {
      return '2026 입시 인사이트에서 현재 중1부터 고3까지 학년별 공식 정보를 확인할 수 있습니다. 각 카드의 공식 원문도 바로 열 수 있어요.';
    }
    return '말씀하신 내용을 기준으로는 먼저 현재 수준을 진단하고, 한 가지 목표를 이번 주 행동으로 나누는 것이 좋아요. 학년과 가장 고민되는 과목을 함께 알려주세요.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: surface,
      foregroundColor: text,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GACHI AI', style: TextStyle(fontSize: 16)),
          Text('학습·진학 도우미', style: TextStyle(color: mute, fontSize: 10)),
        ],
      ),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: lavender,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: const Text(
              '현재 데모 챗봇은 앱 기능과 학습 방향을 안내하며, 입력 내용은 서버로 전송하지 않습니다.',
              style: TextStyle(color: Color(0xff40516F), fontSize: 10),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                for (final suggestion in const [
                  '무료 진단 알려줘',
                  '목표 플랜 만들기',
                  '대입 전략 진단',
                  '고교 선택 도와줘',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _send(suggestion),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(message: messages[index]),
            ),
          ),
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: '궁금한 내용을 입력하세요',
                      filled: true,
                      fillColor: mist,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton.filled(
                  tooltip: '메시지 보내기',
                  onPressed: _send,
                  style: IconButton.styleFrom(backgroundColor: lime),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChatMessage {
  final String text;
  final bool fromUser;

  const _ChatMessage({required this.text, required this.fromUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .78,
      ),
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: message.fromUser ? lime : surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(17),
          topRight: const Radius.circular(17),
          bottomLeft: Radius.circular(message.fromUser ? 17 : 4),
          bottomRight: Radius.circular(message.fromUser ? 4 : 17),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.fromUser ? Colors.white : text,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    ),
  );
}
