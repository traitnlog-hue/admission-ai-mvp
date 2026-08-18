import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/insight_data.dart';

void main() {
  test('2026 insights cover every middle and high school grade', () {
    expect(insightGrades, hasLength(6));
    for (final grade in insightGrades) {
      final items = insightsForGrade(grade);
      expect(items.length, greaterThanOrEqualTo(2));
      expect(
        items.every((item) => item.sourceUrl.startsWith('https://')),
        isTrue,
      );
    }
  });
}
