part of 'main.dart';

class AdmissionStrategyHub extends StatefulWidget {
  final String initialTargetId;

  const AdmissionStrategyHub({super.key, this.initialTargetId = 'sky'});

  @override
  State<AdmissionStrategyHub> createState() => _AdmissionStrategyHubState();
}

class _AdmissionStrategyHubState extends State<AdmissionStrategyHub> {
  late String selectedId = widget.initialTargetId;

  Future<void> _openSource(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('공식 자료를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = admissionTargetById(selectedId);
    final color = Color(selected.colorValue);
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text('대입전략 탐색'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
        children: [
          const Text(
            '목표 대학·전공부터\n전략을 좁혀보세요.',
            style: TextStyle(
              color: text,
              fontSize: 28,
              height: 1.16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SKY, 의치한약수와 주요 관심 전공을 공식 전형자료 기준으로 비교합니다. 합격확률이 아닌 준비도 진단입니다.',
            style: TextStyle(color: mute, fontSize: 11, height: 1.55),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 39,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: admissionTargetGroups
                  .map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(group.title),
                        selected: selectedId == group.id,
                        onSelected: (_) =>
                            setState(() => selectedId = group.id),
                        selectedColor: Color(group.colorValue)
                            .withValues(alpha: .14),
                        checkmarkColor: Color(group.colorValue),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 15),
          _TargetHero(group: selected),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StrategyMetric(
                  icon: Icons.menu_book_outlined,
                  label: '핵심 교과',
                  value: selected.coreSubjects.take(3).join(' · '),
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StrategyMetric(
                  icon: Icons.route_outlined,
                  label: '전형 경로',
                  value: selected.routes.take(2).join(' · '),
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '무료로 확인하는 항목',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          ...selected.freeChecks.map(
            (item) => _CheckLine(text: item, color: color),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StrategyQuickCheck(group: selected),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
            icon: const Icon(Icons.auto_graph_rounded),
            label: Text('${selected.title} 무료 준비도 진단'),
          ),
          const SizedBox(height: 20),
          _ProStrategyBanner(group: selected),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openSource(selected.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label: Text('${selected.sourceName} 보기'),
          ),
          const SizedBox(height: 9),
          const Text(
            '모집인원·전형요소·수능최저는 변경될 수 있으므로 지원 시점의 대학별 최종 모집요강을 다시 확인하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 9, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            '공식 정보 원문',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '전형 판단 전 최신 시행계획과 모집요강을 원문으로 확인하세요.',
            style: TextStyle(color: mute, fontSize: 10),
          ),
          const SizedBox(height: 10),
          ...admissionOfficialSources.map(
            (source) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                tileColor: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                leading: const Icon(Icons.verified_outlined, color: lime),
                title: Text(source.title, style: const TextStyle(fontSize: 12)),
                subtitle: Text(
                  source.description,
                  style: const TextStyle(color: mute, fontSize: 9),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 17),
                onTap: () => _openSource(source.url),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoachStrategyPanel extends StatelessWidget {
  const CoachStrategyPanel({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xffDCE4F1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: lime, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '목표군별 AI 코치',
                style: TextStyle(
                  color: text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          '학년과 현재 준비 상태를 반영해 전형 방향과 이번 주 실행 과제를 만듭니다.',
          style: TextStyle(color: mute, fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: admissionTargetGroups
              .map(
                (group) => ActionChip(
                  avatar: Icon(
                    _targetIcon(group.id),
                    size: 16,
                    color: Color(group.colorValue),
                  ),
                  label: Text(group.title),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdmissionStrategyHub(initialTargetId: group.id),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdmissionStrategyHub()),
          ),
          icon: const Icon(Icons.insights_outlined, size: 18),
          label: const Text('무료 대입 준비도 분석'),
        ),
      ],
    ),
  );
}

class _TargetHero extends StatelessWidget {
  final AdmissionTargetGroup group;

  const _TargetHero({required this.group});

  @override
  Widget build(BuildContext context) {
    final color = Color(group.colorValue);
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_targetIcon(group.id), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        color: text,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      group.shortLabel,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            group.summary,
            style: const TextStyle(color: mute, fontSize: 12, height: 1.55),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: group.majors
                .take(6)
                .map(
                  (major) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: mist,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      major,
                      style: const TextStyle(color: text, fontSize: 9),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

IconData _targetIcon(String id) => switch (id) {
  'sky' => Icons.account_balance_outlined,
  'medical' => Icons.medical_services_outlined,
  'ai_semiconductor' => Icons.memory_outlined,
  'business' => Icons.show_chart_rounded,
  'bio' => Icons.biotech_outlined,
  _ => Icons.psychology_outlined,
};

class _StrategyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StrategyMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 104),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: mute, fontSize: 9)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(color: text, fontSize: 11, height: 1.35),
        ),
      ],
    ),
  );
}

class _CheckLine extends StatelessWidget {
  final String label;
  final Color color;

  const _CheckLine({required String text, required this.color}) : label = text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, color: color, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(color: text, fontSize: 11)),
        ),
      ],
    ),
  );
}

class _ProStrategyBanner extends StatelessWidget {
  final AdmissionTargetGroup group;

  const _ProStrategyBanner({required this.group});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRO 정밀 분석',
          style: TextStyle(color: Color(0xffAFC5FF), fontSize: 10),
        ),
        const SizedBox(height: 7),
        Text(
          '${group.title} 지원 조합과 4주 로드맵',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          group.premiumChecks.take(3).join(' · '),
          style: const TextStyle(
            color: Color(0xffCBD5E7),
            fontSize: 10,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PremiumAdmissionOffer(
                freeResult: {'targetId': group.id, 'major': group.title},
              ),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: Colors.white,
          ),
          child: const Text('무료·유료 분석 비교'),
        ),
      ],
    ),
  );
}

class StrategyQuickCheck extends StatefulWidget {
  final AdmissionTargetGroup group;

  const StrategyQuickCheck({super.key, required this.group});

  @override
  State<StrategyQuickCheck> createState() => _StrategyQuickCheckState();
}

class _StrategyQuickCheckState extends State<StrategyQuickCheck> {
  String grade = '고2';
  double schoolGrade = 2.5;
  double mockGrade = 2.0;
  double recordStrength = 3;
  double explorationStrength = 3;

  String get admissionYear => switch (grade) {
    '고3' || 'N수' => '2027학년도',
    '고2' => '2028학년도',
    _ => '2029학년도 이후',
  };

  void _analyze() {
    final isMedical = widget.group.id == 'medical';
    final academic = (112 - schoolGrade * 12).clamp(10, 100).round();
    final csat = (112 - mockGrade * 12).clamp(10, 100).round();
    final record = (recordStrength * 20).round();
    final exploration = (explorationStrength * 20).round();
    final readiness = isMedical
        ? (academic * .36 + csat * .36 + record * .14 + exploration * .14)
              .round()
        : (academic * .3 + csat * .3 + record * .2 + exploration * .2).round();
    final primaryRoute = csat >= academic + 7
        ? '정시 중심'
        : record + exploration >= academic + csat
        ? '학생부종합 중심'
        : academic >= csat + 7
        ? '학생부교과·추천 중심'
        : '수시·정시 병행';
    final gaps = <String>[];
    if (academic < 78) gaps.add('내신 핵심교과의 학기별 상승 흐름');
    if (csat < 78) gaps.add('수능최저·정시를 위한 모의고사 안정성');
    if (record < 70) gaps.add('교과 활동을 근거로 한 학생부 기록');
    if (exploration < 70) gaps.add('전공 질문–과정–결과가 이어지는 탐구');
    if (gaps.isEmpty) gaps.add('대학별 전형요소와 지원 조합의 세밀한 검증');

    final result = <String, dynamic>{
      'targetId': widget.group.id,
      'major': widget.group.title,
      'admissionYear': admissionYear,
      'grade': grade,
      'readiness': readiness,
      'academic': academic,
      'csat': csat,
      'record': record,
      'exploration': exploration,
      'primary_strategy': primaryRoute,
      'gaps': gaps,
      'action_plan': _nextAction(widget.group, grade, gaps.first),
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StrategyFreeResultPage(group: widget.group, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.group.colorValue);
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: Text('${widget.group.title} 무료 진단'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            '현재 준비 상태를\n빠르게 입력해 주세요.',
            style: TextStyle(
              color: text,
              fontSize: 25,
              height: 1.16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '점수는 합격 가능성이 아니라 학업·수능·학생부·탐구의 균형을 보여주는 준비도 지표입니다.',
            style: TextStyle(color: mute, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 20),
          const Text(
            '현재 학년',
            style: TextStyle(color: text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '고1', label: Text('고1')),
              ButtonSegment(value: '고2', label: Text('고2')),
              ButtonSegment(value: '고3', label: Text('고3')),
              ButtonSegment(value: 'N수', label: Text('N수')),
            ],
            selected: {grade},
            onSelectionChanged: (value) => setState(() => grade = value.first),
          ),
          const SizedBox(height: 20),
          _GradeSlider(
            title: '내신 평균 등급',
            value: schoolGrade,
            color: color,
            onChanged: (value) => setState(() => schoolGrade = value),
          ),
          _GradeSlider(
            title: '모의고사 평균 등급',
            value: mockGrade,
            color: color,
            onChanged: (value) => setState(() => mockGrade = value),
          ),
          _StrengthSlider(
            title: '학생부 기록의 구체성',
            value: recordStrength,
            color: color,
            onChanged: (value) => setState(() => recordStrength = value),
          ),
          _StrengthSlider(
            title: '전공 탐구의 깊이',
            value: explorationStrength,
            color: color,
            onChanged: (value) => setState(() => explorationStrength = value),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _analyze,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
            ),
            icon: const Icon(Icons.insights_outlined),
            label: const Text('무료 전략 분석 결과 보기'),
          ),
        ],
      ),
    );
  }
}

class _GradeSlider extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _GradeSlider({
    required this.title,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => _SliderShell(
    title: title,
    valueLabel: value.toStringAsFixed(1),
    child: Slider(
      value: value,
      min: 1,
      max: 9,
      divisions: 16,
      activeColor: color,
      label: value.toStringAsFixed(1),
      onChanged: onChanged,
    ),
  );
}

class _StrengthSlider extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _StrengthSlider({
    required this.title,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => _SliderShell(
    title: title,
    valueLabel: '${value.round()} / 5',
    child: Slider(
      value: value,
      min: 1,
      max: 5,
      divisions: 4,
      activeColor: color,
      label: '${value.round()}',
      onChanged: onChanged,
    ),
  );
}

class _SliderShell extends StatelessWidget {
  final String title;
  final String valueLabel;
  final Widget child;

  const _SliderShell({
    required this.title,
    required this.valueLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(15, 13, 8, 8),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: text, fontSize: 12),
              ),
            ),
            Text(valueLabel, style: const TextStyle(color: lime, fontSize: 11)),
          ],
        ),
        child,
      ],
    ),
  );
}

class StrategyFreeResultPage extends StatelessWidget {
  final AdmissionTargetGroup group;
  final Map<String, dynamic> result;

  const StrategyFreeResultPage({
    super.key,
    required this.group,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(group.colorValue);
    final readiness = result['readiness'] as int;
    final gaps = (result['gaps'] as List).cast<String>();
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(backgroundColor: mist, title: const Text('무료 전략 분석')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${group.title}\n준비도 리포트',
                      style: const TextStyle(
                        color: text,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${result['grade']} · ${result['admissionYear']}',
                      style: const TextStyle(color: mute, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: readiness / 100,
                      strokeWidth: 8,
                      color: color,
                      backgroundColor: color.withValues(alpha: .12),
                    ),
                    Text(
                      '$readiness',
                      style: const TextStyle(
                        color: text,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ResultMetricGrid(result: result, color: color),
          const SizedBox(height: 20),
          const Text(
            '추천 전략 방향',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.route_outlined, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result['primary_strategy'] as String,
                    style: const TextStyle(
                      color: text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '우선 보완할 GAP',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          ...gaps.map((gap) => _CheckLine(text: gap, color: coral)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이번 주 ACTION',
                  style: TextStyle(color: Color(0xffAFC5FF), fontSize: 10),
                ),
                const SizedBox(height: 7),
                Text(
                  result['action_plan'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '대학·전형별 정밀 비교가 필요하다면',
                  style: TextStyle(color: text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  group.premiumChecks.join(' · '),
                  style: const TextStyle(
                    color: mute,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PremiumAdmissionOffer(freeResult: result),
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: const Text('PRO 정밀 분석 이어가기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetricGrid extends StatelessWidget {
  final Map<String, dynamic> result;
  final Color color;

  const _ResultMetricGrid({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('내신', result['academic'] as int),
      ('수능', result['csat'] as int),
      ('학생부', result['record'] as int),
      ('탐구', result['exploration'] as int),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics
          .map(
            (metric) => Container(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.$1,
                    style: const TextStyle(color: mute, fontSize: 10),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${metric.$2}',
                    style: const TextStyle(
                      color: text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: metric.$2 / 100,
                    color: color,
                    backgroundColor: color.withValues(alpha: .1),
                    minHeight: 5,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

String _nextAction(AdmissionTargetGroup group, String grade, String firstGap) {
  final timing = switch (grade) {
    '고3' || 'N수' => '이번 주 안에 지원 대학별 수능최저와 전형 일정을 표로 정리하고',
    '고2' => '다음 시험 전까지 핵심교과 한 과목의 약점 단원을 정리하고',
    _ => '다음 학기 선택과목과 전공 연계성을 확인하고',
  };
  return '$timing, ${group.title} 준비에서 필요한 “$firstGap”을 보완할 행동 1개를 완료하세요.';
}
