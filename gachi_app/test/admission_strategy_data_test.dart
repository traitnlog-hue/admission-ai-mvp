import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/admission_strategy_data.dart';

void main() {
  test('대입 목표군 데이터가 필수 정보를 갖춘다', () {
    expect(admissionTargetGroups, hasLength(6));
    expect(admissionTargetById('sky').universities, contains('서울대학교'));
    expect(
      admissionTargetById('medical').majors,
      containsAll(['의예', '치의예', '한의예', '약학', '수의예']),
    );

    for (final group in admissionTargetGroups) {
      expect(group.title, isNotEmpty);
      expect(group.majors, isNotEmpty);
      expect(group.coreSubjects, isNotEmpty);
      expect(group.evaluationFocus, isNotEmpty);
      expect(group.freeChecks, isNotEmpty);
      expect(group.premiumChecks, isNotEmpty);
      expect(group.routes, isNotEmpty);
      expect(Uri.parse(group.sourceUrl).scheme, 'https');
    }

    expect(admissionOfficialSources, hasLength(6));
    for (final source in admissionOfficialSources) {
      expect(source.title, isNotEmpty);
      expect(source.description, isNotEmpty);
      expect(Uri.parse(source.url).scheme, 'https');
    }
  });
}
