import 'package:flutter_test/flutter_test.dart';
import 'package:route27_mobile/level_test_data.dart';

void main() {
  test('each subject has 20 valid multiple-choice questions', () {
    expect(levelQuestions.keys, containsAll(['국어', '영어', '수학']));

    for (final questions in levelQuestions.values) {
      expect(questions, hasLength(20));
      for (final question in questions) {
        expect(question.choices, hasLength(4));
        expect(question.answerIndex, inInclusiveRange(0, 3));
        expect(question.prompt, isNotEmpty);
      }
    }
  });
}
