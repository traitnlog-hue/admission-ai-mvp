part of 'main.dart';

class LevelTest extends StatefulWidget {
  const LevelTest({super.key});

  @override
  State<LevelTest> createState() => _LevelTestState();
}

class _LevelTestState extends State<LevelTest> {
  int step = 0;
  String subject = '수학';
  String grade = '고2';
  List<int?> answers = List<int?>.filled(20, null);

  List<LevelQuestion> get questions => levelQuestions[subject]!;
  int get answeredCount => answers.whereType<int>().length;

  @override
  Widget build(BuildContext context) {
    if (step == 0) return _buildSetup();
    if (step == 21) return _buildResult();
    return _buildExam();
  }

  Widget _buildSetup() => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, foregroundColor: text),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          const Text(
            'GACHI LEVEL',
            style: TextStyle(
              color: lime,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '실전처럼 풀어보는\n과목별 무료 진단',
            style: TextStyle(
              color: text,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '20문항 · 예상 20분 · 4지선다형\n기초부터 응용까지 영역별 강약점을 확인해요.',
            style: TextStyle(color: mute, height: 1.55),
          ),
          const SizedBox(height: 28),
          const _FormLabel('학년'),
          DropdownButtonFormField<String>(
            initialValue: grade,
            decoration: _inputDecoration(),
            items: const ['중1', '중2', '중3', '고1', '고2', '고3']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => grade = value!),
          ),
          const SizedBox(height: 22),
          const _FormLabel('진단 과목'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['국어', '영어', '수학']
                .map(
                  (value) => ChoiceChip(
                    label: Text('$value 20문항'),
                    selected: subject == value,
                    selectedColor: lime,
                    labelStyle: TextStyle(
                      color: subject == value ? Colors.white : text,
                      fontWeight: FontWeight.w800,
                    ),
                    onSelected: (_) => setState(() => subject = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffE2E6EE)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '응시 전 확인',
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 9),
                Text(
                  '• 한 문항에 하나의 답을 선택하세요.\n• 번호를 눌러 이전 문항을 다시 확인할 수 있어요.\n• 마지막 문항까지 풀면 영역별 결과가 제공됩니다.',
                  style: TextStyle(color: mute, fontSize: 12, height: 1.65),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() {
              answers = List<int?>.filled(20, null);
              step = 1;
            }),
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(58),
            ),
            child: Text(
              '$grade $subject 진단 시작',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildExam() {
    final question = questions[step - 1];
    final selected = answers[step - 1];
    return Scaffold(
      backgroundColor: const Color(0xffEEF1F6),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(
          '$grade $subject 진단평가',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Text(
                '$answeredCount / 20',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(
            children: [
              Text(
                '제1교시 · $subject',
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text('예상 20분', style: const TextStyle(color: mute, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: step / 20,
              minHeight: 6,
              color: lime,
              backgroundColor: const Color(0xffDCE2EC),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffD7DCE6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: navy,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$step',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${question.domain} · ${question.difficulty}',
                      style: const TextStyle(
                        color: lime,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  question.prompt,
                  style: const TextStyle(
                    color: text,
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                RadioGroup<int>(
                  groupValue: selected,
                  onChanged: (value) =>
                      setState(() => answers[step - 1] = value),
                  child: Column(
                    children: List.generate(
                      question.choices.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                          color: selected == index
                              ? const Color(0xffEAF1FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == index
                                ? lime
                                : const Color(0xffDDE2EA),
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: index,
                          activeColor: lime,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          title: Text(
                            '${index + 1}. ${question.choices[index]}',
                            style: const TextStyle(
                              color: text,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              20,
              (index) => InkWell(
                onTap: () => setState(() => step = index + 1),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: step == index + 1
                        ? navy
                        : answers[index] == null
                        ? Colors.white
                        : lavender,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: answers[index] == null
                          ? const Color(0xffCDD3DE)
                          : lime,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: step == index + 1 ? Colors.white : text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: step == 1 ? null : () => setState(() => step--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('이전 문제'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => setState(() => step == 20 ? step = 21 : step++),
                  style: FilledButton.styleFrom(
                    backgroundColor: step == 20 ? coral : lime,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(
                    step == 20 ? '답안 제출' : '다음 문제',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    var correct = 0;
    final misses = <String, int>{};
    for (var index = 0; index < questions.length; index++) {
      if (answers[index] == questions[index].answerIndex) {
        correct++;
      } else {
        misses.update(
          questions[index].domain,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final score = correct * 5;
    final weakAreas = misses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final level = score >= 85
        ? '상위권 심화'
        : score >= 65
        ? '핵심 개념 안정'
        : score >= 45
        ? '기초 보완 필요'
        : '개념 재정비 필요';
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: const Text(
          '진단 결과',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$grade · $subject',
                  style: const TextStyle(
                    color: Color(0xffAFC5FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  '$score점',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '20문항 중 $correct문항 정답 · $level',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '우선 보완 영역',
            style: TextStyle(
              color: text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...weakAreas
              .take(3)
              .map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffE2E6EE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: coral),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}문항 오답',
                        style: const TextStyle(color: mute, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '다음 학습: ${weakAreas.isEmpty ? subject : weakAreas.first.key} 개념을 20분 복습하고, 틀린 문제의 풀이 근거를 한 줄씩 기록해 보세요.',
              style: const TextStyle(
                color: text,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => setState(() {
              step = 0;
              answers = List<int?>.filled(20, null);
            }),
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text(
              '다른 과목 진단하기',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('홈으로 돌아가기'),
          ),
        ],
      ),
    );
  }
}
