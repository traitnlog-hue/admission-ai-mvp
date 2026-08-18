import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/study_plan_models.dart';

void main() {
  test('goal creates an executable weekly plan', () {
    const goal = StudyGoal(
      id: 'goal-1',
      area: '내신',
      subject: '수학',
      target: '내신 2등급',
      period: '8주',
      weeklyHours: 5,
      sessionsPerWeek: 5,
      preferredTime: '저녁',
      weakPoint: '기하 응용',
      successMetric: '20문제 중 17문제 정답',
    );

    final tasks = buildWeeklyTasks(goal);

    expect(tasks, hasLength(5));
    expect(tasks.every((task) => task.goalId == goal.id), isTrue);
    expect(tasks.every((task) => task.minutes == 60), isTrue);
    expect(tasks.map((task) => task.day).toSet(), hasLength(5));
  });
}
