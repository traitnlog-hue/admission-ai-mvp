class StudyGoal {
  final String id;
  final String area;
  final String subject;
  final String target;
  final String period;
  final int weeklyHours;
  final int sessionsPerWeek;
  final String preferredTime;
  final String weakPoint;
  final String successMetric;

  const StudyGoal({
    required this.id,
    required this.area,
    required this.subject,
    required this.target,
    required this.period,
    required this.weeklyHours,
    required this.sessionsPerWeek,
    required this.preferredTime,
    required this.weakPoint,
    required this.successMetric,
  });
}

class StudyTask {
  final String id;
  final String goalId;
  final String day;
  final String title;
  final String detail;
  final int minutes;

  const StudyTask({
    required this.id,
    required this.goalId,
    required this.day,
    required this.title,
    required this.detail,
    required this.minutes,
  });
}

List<StudyTask> buildWeeklyTasks(StudyGoal goal) {
  const days = ['월', '화', '수', '목', '금', '토'];
  const titles = [
    '주간 목표 설계',
    '핵심 개념 학습',
    '유형 문제 적용',
    '취약점 집중 보완',
    '실전 점검',
    '주간 회고',
  ];
  final count = goal.sessionsPerWeek.clamp(3, 6);
  final minutes = (goal.weeklyHours * 60 / count).round();
  final details = [
    '${goal.target} 달성을 위한 이번 주 범위를 정하고 학습 자료를 준비해요.',
    '${goal.subject} 핵심 개념을 설명할 수 있을 때까지 학습해요.',
    '대표 유형을 풀고 풀이 과정에 근거를 표시해요.',
    '${goal.weakPoint.isEmpty ? '틀린 문제의 원인' : goal.weakPoint}을 중심으로 다시 학습해요.',
    '${goal.successMetric.isEmpty ? '스스로 정한 성공 기준' : goal.successMetric}을 확인해요.',
    '완료율과 오답을 기록하고 다음 주 계획을 한 문장으로 정리해요.',
  ];

  return List.generate(
    count,
    (index) => StudyTask(
      id: '${goal.id}-$index',
      goalId: goal.id,
      day: days[index],
      title: '${goal.subject} · ${titles[index]}',
      detail: details[index],
      minutes: minutes,
    ),
  );
}
