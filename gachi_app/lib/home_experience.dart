part of 'main.dart';

class Home extends StatefulWidget {
  final SessionUser? user;
  final VoidCallback? onRequireLogin;
  final VoidCallback? onOpenHome;
  final VoidCallback? onOpenProfile;

  const Home({
    super.key,
    this.user,
    this.onRequireLogin,
    this.onOpenHome,
    this.onOpenProfile,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const _goalsKey = 'gachi.study.goals';
  static const _completedKey = 'gachi.study.completed';
  static const _profileKey = 'gachi.student.profile';
  static const _notificationsReadKey = 'gachi.notifications.read';
  AcademyStudentProfile? academyProfile;
  final List<StudyGoal> goals = [];
  final Set<String> completedTaskIds = {};
  String insightGrade = '고3';
  bool hasUnreadNotifications = true;

  List<StudyTask> get weeklyTasks => goals.expand(buildWeeklyTasks).toList();

  @override
  void initState() {
    super.initState();
    _restorePlan();
  }

  Future<void> _restorePlan() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedGoals = preferences.getString(_goalsKey);
    final encodedProfile = preferences.getString(_profileKey);
    final savedCompleted = preferences.getStringList(_completedKey) ?? [];
    final notificationsRead =
        preferences.getBool(_notificationsReadKey) ?? false;
    if (!mounted) return;
    setState(() {
      if (encodedGoals != null) {
        final decoded = jsonDecode(encodedGoals) as List<dynamic>;
        goals
          ..clear()
          ..addAll(
            decoded.map(
              (item) =>
                  StudyGoal.fromJson(Map<String, dynamic>.from(item as Map)),
            ),
          );
      }
      completedTaskIds
        ..clear()
        ..addAll(savedCompleted);
      hasUnreadNotifications = !notificationsRead;
      if (encodedProfile != null) {
        academyProfile = AcademyStudentProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(encodedProfile) as Map),
        );
        insightGrade = academyProfile!.grade;
      }
    });
  }

  Future<void> _savePlan() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _goalsKey,
      jsonEncode(goals.map((goal) => goal.toJson()).toList()),
    );
    await preferences.setStringList(_completedKey, completedTaskIds.toList());
  }

  Future<void> _saveProfile() async {
    final profile = academyProfile;
    if (profile == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> _editProfile() async {
    final profile = await Navigator.push<AcademyStudentProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => AcademyMatchForm(initial: academyProfile),
      ),
    );
    if (profile != null && mounted) {
      setState(() {
        academyProfile = profile;
        insightGrade = profile.grade;
      });
      await _saveProfile();
    }
  }

  Future<void> _addGoal() async {
    final goal = await Navigator.push<StudyGoal>(
      context,
      MaterialPageRoute(builder: (_) => const GoalPlanForm()),
    );
    if (goal != null && mounted) {
      setState(() => goals.add(goal));
      await _savePlan();
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsReadKey, true);
    if (mounted) setState(() => hasUnreadNotifications = false);
  }

  void _toggleTask(String id, bool completed) {
    setState(
      () => completed ? completedTaskIds.add(id) : completedTaskIds.remove(id),
    );
    _savePlan();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = weeklyTasks;
    final insights = insightsForGrade(insightGrade);
    final completed = tasks
        .where((task) => completedTaskIds.contains(task.id))
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        _Top(
          initial: _profileInitial(widget.user),
          onHome: widget.onOpenHome,
          onNotifications: _openNotifications,
          onProfile: widget.onOpenProfile,
          hasUnreadNotifications: hasUnreadNotifications,
        ),
        const SizedBox(height: 18),
        Text(
          academyProfile == null
              ? '나의 진학 준비'
              : '${academyProfile!.school} · ${academyProfile!.grade}',
          style: const TextStyle(
            color: text,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          academyProfile == null
              ? '학생 정보를 등록하면 입시 전략과 맞춤 학원 추천을 시작할 수 있어요.'
              : '${academyProfile!.region} · ${academyProfile!.subjects.join(' · ')} 기준으로 입시 전략을 준비하고 있어요.',
          style: const TextStyle(color: mute, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 12),
        ValueAcademyHero(
          profile: academyProfile,
          onEditProfile: _editProfile,
          onOpenMap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ValueAcademyMapPage()),
          ),
          onQuickCheck: () => showQuickEscapeDiagnosis(context),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffD9E4F5)),
          ),
          child: Column(
            children: [
              TrustWalletCard(
                user: widget.user,
                onRequireLogin: widget.onRequireLogin,
                embedded: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                child: Row(
                  children: [
                    _Quick(
                      Icons.assignment_outlined,
                      '무료 진단',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LevelTest()),
                      ),
                      dark: false,
                    ),
                    _Quick(
                      Icons.insights_outlined,
                      '입시 분석',
                      () => openTicketProtectedFeature(
                        context: context,
                        user: widget.user,
                        onRequireLogin: widget.onRequireLogin,
                        featureName: '무료 대입전략 진단',
                        destination: const AdmissionForm(),
                      ),
                      dark: false,
                    ),
                    _Quick(
                      Icons.add_task_rounded,
                      '목표 추가',
                      _addGoal,
                      dark: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _GoalSnapshot(goal: goals.last, onAdd: _addGoal),
        ],
        const SizedBox(height: 23),
        Row(
          children: [
            const Expanded(
              child: Text(
                '이번 주 코치 플랜',
                style: TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (tasks.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyCoachPlan(
                      goals: goals,
                      completedTaskIds: completedTaskIds,
                      onToggle: _toggleTask,
                    ),
                  ),
                ),
                child: const Text('전체 보기'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          _EmptyCoachPlan(onAdd: _addGoal)
        else ...[
          _CoachProgress(completed: completed, total: tasks.length),
          const SizedBox(height: 10),
          ...tasks
              .take(3)
              .map(
                (task) => _CoachTaskCard(
                  task: task,
                  completed: completedTaskIds.contains(task.id),
                  onChanged: (value) => _toggleTask(task.id, value),
                ),
              ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                '새로운 인사이트',
                style: TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InsightsHub(initialGrade: insightGrade),
                ),
              ),
              child: const Text('중1~고3 전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (insights.isNotEmpty)
          _InsightCard(
            item: insights.first,
            compact: true,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InsightsHub(initialGrade: insightGrade),
              ),
            ),
          ),
        const SizedBox(height: 22),
        const _HomeAdSlot(),
      ],
    );
  }
}

class _HomeAdSlot extends StatelessWidget {
  const _HomeAdSlot();

  @override
  Widget build(BuildContext context) => Semantics(
    label: '광고. 고등 영어 루틴 7일 무료 체험',
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff183A72), Color(0xff2765BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AD · 스터디메이트',
                  style: TextStyle(
                    color: Color(0xffBFD6FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '고등 영어 루틴, 7일 무료 체험',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '매일 15분 · 오늘의 단어와 오답 복습',
                  style: TextStyle(color: Color(0xffD9E6FF), fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    ),
  );
}

String _profileInitial(SessionUser? user) {
  final name = user?.name.trim() ?? '';
  return name.isEmpty ? 'G' : name.substring(0, 1);
}

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      foregroundColor: text,
      title: const Text('알림'),
      actions: [
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('모든 알림을 읽음 처리했습니다.'))),
          child: const Text('모두 읽음'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: const [
        _NotificationCard(
          icon: Icons.auto_awesome_rounded,
          title: '이번 주 코치 플랜을 확인해 보세요',
          body: '목표를 추가하면 요일별 학습·오답·회고 과제가 자동으로 구성됩니다.',
          time: '오늘',
          highlighted: true,
        ),
        _NotificationCard(
          icon: Icons.receipt_long_rounded,
          title: '영수증 1건으로 진단 티켓 1매',
          body: '실명 회원이 영수증과 후기를 인증하면 대입전략 또는 고교탐색에 사용할 수 있어요.',
          time: '오늘',
        ),
        _NotificationCard(
          icon: Icons.school_outlined,
          title: '2026 입시 인사이트가 업데이트됐어요',
          body: '현재 학년을 기준으로 교육청·대학 공식 자료의 확인 포인트를 정리했습니다.',
          time: '어제',
        ),
      ],
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool highlighted;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xffEDF4FF) : surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: highlighted ? const Color(0xffC8DBFF) : const Color(0xffE7EAF0),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: highlighted ? lime : lavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: highlighted ? Colors.white : lime, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(time, style: const TextStyle(color: mute, fontSize: 9)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(color: mute, fontSize: 10, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GoalSnapshot extends StatelessWidget {
  final StudyGoal goal;
  final VoidCallback onAdd;
  const _GoalSnapshot({required this.goal, required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xffEAF1FF),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xffCFE0FF)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lime,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${goal.subject} · ${goal.target}',
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${goal.period} · 주 ${goal.sessionsPerWeek}회 · ${goal.weeklyHours}시간',
                style: const TextStyle(color: mute, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onAdd,
          tooltip: '목표 추가',
          icon: const Icon(Icons.add_circle_outline, color: lime),
        ),
      ],
    ),
  );
}

class _EmptyCoachPlan extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCoachPlan({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE2E6EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.route_outlined, color: lime, size: 27),
        const SizedBox(height: 10),
        const Text(
          '아직 실행할 목표가 없어요.',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '구체적인 목표를 만들면 요일별 학습·오답·회고 플랜을 자동으로 구성해 드려요.',
          style: TextStyle(color: mute, fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('첫 목표 만들기'),
        ),
      ],
    ),
  );
}

class _CoachProgress extends StatelessWidget {
  final int completed;
  final int total;
  const _CoachProgress({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELF-DIRECTED WEEK',
                  style: TextStyle(
                    color: Color(0xffAFC5FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$completed개 완료 · ${total - completed}개 남음',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: lime,
                    backgroundColor: Colors.white12,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachTaskCard extends StatelessWidget {
  final StudyTask task;
  final bool completed;
  final ValueChanged<bool> onChanged;
  const _CoachTaskCard({
    required this.task,
    required this.completed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: completed ? const Color(0xffAFC5FF) : const Color(0xffE2E6EE),
      ),
    ),
    child: CheckboxListTile(
      value: completed,
      onChanged: (value) => onChanged(value ?? false),
      activeColor: lime,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      secondary: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: completed ? lavender : mist,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          task.day,
          style: const TextStyle(color: lime, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          color: completed ? mute : text,
          fontWeight: FontWeight.w600,
          decoration: completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${task.minutes}분 · ${task.detail}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: mute, fontSize: 10, height: 1.4),
        ),
      ),
    ),
  );
}

class GoalPlanForm extends StatefulWidget {
  const GoalPlanForm({super.key});

  @override
  State<GoalPlanForm> createState() => _GoalPlanFormState();
}

class _GoalPlanFormState extends State<GoalPlanForm> {
  String area = '내신';
  String subject = '수학';
  String period = '8주';
  String preferredTime = '저녁';
  double weeklyHours = 5;
  double sessionsPerWeek = 5;
  final target = TextEditingController();
  final weakPoint = TextEditingController();
  final successMetric = TextEditingController();

  @override
  void dispose() {
    target.dispose();
    weakPoint.dispose();
    successMetric.dispose();
    super.dispose();
  }

  StudyGoal _previewGoal() => StudyGoal(
    id: 'preview',
    area: area,
    subject: subject,
    target: target.text.trim().isEmpty
        ? '구체적인 목표를 입력해 주세요'
        : target.text.trim(),
    period: period,
    weeklyHours: weeklyHours.round(),
    sessionsPerWeek: sessionsPerWeek.round(),
    preferredTime: preferredTime,
    weakPoint: weakPoint.text.trim(),
    successMetric: successMetric.text.trim(),
  );

  void _submit() {
    if (target.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('측정할 수 있는 목표를 입력해 주세요.')));
      return;
    }
    final preview = _previewGoal();
    Navigator.pop(
      context,
      StudyGoal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        area: preview.area,
        subject: preview.subject,
        target: preview.target,
        period: preview.period,
        weeklyHours: preview.weeklyHours,
        sessionsPerWeek: preview.sessionsPerWeek,
        preferredTime: preview.preferredTime,
        weakPoint: preview.weakPoint,
        successMetric: preview.successMetric,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewTasks = buildWeeklyTasks(_previewGoal());
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text(
          '자기주도 목표 만들기',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            '결과가 보이는 목표로\n잘게 나눠볼게요.',
            style: TextStyle(
              color: text,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '목표·시간·실행 횟수·성공 기준을 정하면 이번 주 코치 플랜이 자동으로 만들어집니다.',
            style: TextStyle(color: mute, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _FormLabel('목표 유형'),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: ['내신', '수능', '학습습관', '학생부', '독서·탐구']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: area == value,
                    selectedColor: lime,
                    labelStyle: TextStyle(
                      color: area == value ? Colors.white : text,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => area = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const _FormLabel('과목·영역'),
          DropdownButtonFormField<String>(
            initialValue: subject,
            decoration: _inputDecoration(),
            items: ['국어', '영어', '수학', '사회', '과학', '학생부', '학습습관']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => subject = value!),
          ),
          const SizedBox(height: 20),
          const _FormLabel('측정 가능한 결과 목표'),
          TextField(
            controller: target,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hint: '예: 수학 내신 2등급, 오답률 15% 이하'),
          ),
          const SizedBox(height: 20),
          const _FormLabel('현재 가장 어려운 점'),
          TextField(
            controller: weakPoint,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            decoration: _inputDecoration(hint: '예: 시간 안에 기하 응용 문제를 못 풀어요'),
          ),
          const SizedBox(height: 20),
          const _FormLabel('성공 기준'),
          TextField(
            controller: successMetric,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hint: '예: 20문제 중 17문제 이상 정답'),
          ),
          const SizedBox(height: 20),
          const _FormLabel('목표 기간'),
          Wrap(
            spacing: 7,
            children: ['4주', '8주', '12주', '이번 학기']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: period == value,
                    onSelected: (_) => setState(() => period = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                '주당 학습 시간',
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${weeklyHours.round()}시간',
                style: const TextStyle(
                  color: lime,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: weeklyHours,
            min: 2,
            max: 14,
            divisions: 12,
            activeColor: lime,
            onChanged: (value) => setState(() => weeklyHours = value),
          ),
          Row(
            children: [
              Text(
                '주당 실행 횟수',
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${sessionsPerWeek.round()}회',
                style: const TextStyle(
                  color: lime,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: sessionsPerWeek,
            min: 3,
            max: 6,
            divisions: 3,
            activeColor: lime,
            onChanged: (value) => setState(() => sessionsPerWeek = value),
          ),
          const SizedBox(height: 10),
          const _FormLabel('집중 시간대'),
          Wrap(
            spacing: 7,
            children: ['아침', '방과 후', '저녁', '주말']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: preferredTime == value,
                    onSelected: (_) => setState(() => preferredTime = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
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
                  'WEEKLY PLAN PREVIEW',
                  style: TextStyle(
                    color: Color(0xffAFC5FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                ...previewTasks
                    .take(4)
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                task.day,
                                style: const TextStyle(
                                  color: lime,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${task.title} · ${task.minutes}분',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(58),
            ),
            child: const Text(
              '목표 저장하고 주간 플랜 만들기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyCoachPlan extends StatefulWidget {
  final List<StudyGoal> goals;
  final Set<String> completedTaskIds;
  final void Function(String id, bool completed) onToggle;
  const WeeklyCoachPlan({
    super.key,
    required this.goals,
    required this.completedTaskIds,
    required this.onToggle,
  });

  @override
  State<WeeklyCoachPlan> createState() => _WeeklyCoachPlanState();
}

class _WeeklyCoachPlanState extends State<WeeklyCoachPlan> {
  late final Set<String> completed = {...widget.completedTaskIds};
  final reflection = TextEditingController();

  @override
  void dispose() {
    reflection.dispose();
    super.dispose();
  }

  void _toggle(String id, bool value) {
    setState(() => value ? completed.add(id) : completed.remove(id));
    widget.onToggle(id, value);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.goals.expand(buildWeeklyTasks).toList();
    final done = tasks.where((task) => completed.contains(task.id)).length;
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text(
          '이번 주 자기주도 플랜',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            '계획하고, 실행하고,\n스스로 점검해요.',
            style: TextStyle(
              color: text,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _CoachProgress(completed: done, total: tasks.length),
          const SizedBox(height: 16),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: widget.goals
                .map(
                  (goal) => Chip(
                    label: Text(
                      '${goal.subject} · ${goal.target}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: lavender,
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          ...tasks.map(
            (task) => _CoachTaskCard(
              task: task,
              completed: completed.contains(task.id),
              onChanged: (value) => _toggle(task.id, value),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xffE2E6EE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 자기주도 회고',
                  style: TextStyle(color: text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  '잘한 점 1개, 막힌 점 1개, 내일 바꿀 점 1개를 적어보세요.',
                  style: TextStyle(color: mute, fontSize: 11),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reflection,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    hint: '예: 문제를 끝까지 읽은 점은 좋았고, 오답 정리가 늦었다. 내일은 시작 10분 안에 복습부터 한다.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsHub extends StatefulWidget {
  final String initialGrade;
  const InsightsHub({super.key, required this.initialGrade});

  @override
  State<InsightsHub> createState() => _InsightsHubState();
}

class _InsightsHubState extends State<InsightsHub> {
  late String grade = widget.initialGrade;

  Future<void> _openSource(AdmissionInsight item) async {
    final opened = await launchUrl(
      Uri.parse(item.sourceUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('공식 원문을 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = insightsForGrade(grade);
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text(
          '2026 진로·입시 인사이트',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            '내 학년에 필요한\n공식 정보만 골라봐요.',
            style: TextStyle(
              color: text,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '교육부·대입정보포털·교육청 자료를 2026년 8월 기준으로 정리했습니다. 미확정 학년도는 방향 안내로만 활용하세요.',
            style: TextStyle(color: mute, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: insightGrades
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: grade == value,
                    selectedColor: lime,
                    labelStyle: TextStyle(
                      color: grade == value ? Colors.white : text,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => grade = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          ...items.map(
            (item) => _InsightCard(item: item, onOpen: () => _openSource(item)),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AdmissionInsight item;
  final VoidCallback onOpen;
  final bool compact;
  const _InsightCard({
    required this.item,
    required this.onOpen,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpen,
    borderRadius: BorderRadius.circular(21),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xffE2E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(
                  item.grade,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: lavender,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(
                  item.admissionYear,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: const Color(0xffFFF0EA),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.tag.toUpperCase(),
            style: const TextStyle(
              color: coral,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(
              color: text,
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            item.summary,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: const TextStyle(color: mute, fontSize: 11, height: 1.55),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: mist,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: lime, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.action,
                      style: const TextStyle(
                        color: text,
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.source,
                  style: const TextStyle(color: mute, fontSize: 9),
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: lime, size: 16),
            ],
          ),
        ],
      ),
    ),
  );
}
