from backend.app.engine import analyze
from backend.app.models import Grades, MockGrades, StudentProfile


def test_returns_four_scores_and_recommendations():
    result = analyze(StudentProfile(
        admission_year=2027,
        grade=2,
        major="컴퓨터공학",
        school_grades=Grades(korean=2.0, math=1.5, english=2.2, social=2.3, science=1.7),
        mock_grades=MockGrades(korean=2, math=1, english=2, inquiry=2),
        record_text="알고리즘과 데이터 분석을 탐구하고 프로그래밍 프로젝트를 발표함",
    ))
    assert len(result.scores) == 4
    assert len(result.track_scores) == 4
    assert result.recommendations
    assert all(item.is_sample_data for item in result.recommendations)


def test_recommendations_have_source_aware_status():
    result = analyze(StudentProfile(
        admission_year=2028, grade=2, major="컴퓨터공학",
        school_grades=Grades(korean=2, math=2, english=2, social=2, science=2),
        mock_grades=MockGrades(korean=2, math=2, english=2, inquiry=2),
    ))
    assert result.recommendations[0].is_sample_data is True
