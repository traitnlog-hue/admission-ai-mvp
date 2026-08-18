class AdmissionInsight {
  final String grade;
  final String admissionYear;
  final String tag;
  final String title;
  final String summary;
  final String action;
  final String source;
  final String sourceUrl;

  const AdmissionInsight({
    required this.grade,
    required this.admissionYear,
    required this.tag,
    required this.title,
    required this.summary,
    required this.action,
    required this.source,
    required this.sourceUrl,
  });
}

const insightGrades = ['중1', '중2', '중3', '고1', '고2', '고3'];

const admissionInsights = <AdmissionInsight>[
  AdmissionInsight(
    grade: '중1',
    admissionYear: '2032학년도',
    tag: '진로 탐색',
    title: '성적보다 먼저, 좋아하는 문제를 수집할 시기',
    summary: '2032학년도 대입 세부안은 아직 확정 전입니다. 중1은 직업 이름보다 흥미 분야와 잘하는 학습 방식을 기록하는 것이 우선입니다.',
    action: '커리어넷 진로검사 후 관심 분야 3개와 그 이유를 진로 노트에 적어보세요.',
    source: '교육부 지원 진로정보망 커리어넷',
    sourceUrl: 'https://www.career.go.kr/',
  ),
  AdmissionInsight(
    grade: '중1',
    admissionYear: '2032학년도',
    tag: '교육청 정보',
    title: '2026 서울교육 진로·학업 설계 지원',
    summary: '서울시교육청은 중·고등학생 대상 맞춤형 진로·진학 자료와 진로 체험, 학업 설계 상담을 운영합니다.',
    action: '학교 또는 교육청 진로 체험 일정 중 이번 학기 참여할 프로그램 하나를 선택하세요.',
    source: '서울특별시교육청 2026 주요업무',
    sourceUrl: 'https://www.sen.go.kr/resources/www/data/policydata1_9_2.pdf',
  ),
  AdmissionInsight(
    grade: '중2',
    admissionYear: '2031학년도',
    tag: '과목 설계',
    title: '고교 선택 전에 학습 성향부터 확인하세요',
    summary: '학교 유형보다 자신이 질문하고 탐구하는 방식, 교과별 강약점, 통학과 학습 환경을 먼저 정리해야 합니다.',
    action: '관심 고교 2곳의 교육과정과 동아리, 선택과목을 비교표로 만들어보세요.',
    source: '서울특별시교육청 진로·진학 지원',
    sourceUrl: 'https://www.sen.go.kr/resources/www/data/policydata1_9_2.pdf',
  ),
  AdmissionInsight(
    grade: '중2',
    admissionYear: '2031학년도',
    tag: '진로 활동',
    title: '진로 체험은 결과보다 질문을 남겨야 합니다',
    summary: '체험 횟수보다 체험 전 질문, 활동 중 발견, 이후 달라진 생각을 기록하면 고교 학업 설계의 근거가 됩니다.',
    action: '다음 진로 체험에서 확인할 질문 3개를 미리 작성하세요.',
    source: '교육부 지원 진로정보망 커리어넷',
    sourceUrl: 'https://www.career.go.kr/',
  ),
  AdmissionInsight(
    grade: '중3',
    admissionYear: '2030학년도',
    tag: '고교 선택',
    title: '고입 정보는 교육청 공식 자료로 확인하세요',
    summary: '지원 자격과 일정, 학교 유형별 전형 방식은 매년 달라질 수 있으므로 교육청 고입자료실의 최신 계획을 기준으로 판단해야 합니다.',
    action: '희망 고교의 통학 시간, 교육과정, 전형 일정, 지원 자격을 한 장에 정리하세요.',
    source: '서울특별시교육청 고입자료실',
    sourceUrl: 'https://www.sen.go.kr/user/bbs/BD_selectBbs.do?q_bbsSn=1068',
  ),
  AdmissionInsight(
    grade: '중3',
    admissionYear: '2030학년도',
    tag: '고교학점제',
    title: '진로와 연결된 선택과목 지도를 준비하세요',
    summary: '고교 입학 전 관심 계열의 기초 교과와 탐구 과목을 살펴보면 입학 후 과목 선택의 시행착오를 줄일 수 있습니다.',
    action: '관심 계열 2개를 정하고 각 계열에 필요한 고교 과목을 3개씩 찾아보세요.',
    source: '교육부 2028 대입 정보 안내',
    sourceUrl: 'https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=104960&lev=0',
  ),
  AdmissionInsight(
    grade: '고1',
    admissionYear: '2029학년도',
    tag: '학업 설계',
    title: '2029 대입은 과목 선택의 이유가 중요합니다',
    summary: '2022 개정 교육과정과 고교학점제 환경에서는 희망 전공과 교과 이수 흐름을 함께 설계해야 합니다.',
    action: '2·3학년 선택과목 후보를 전공 연계성, 흥미, 학업 부담 기준으로 점검하세요.',
    source: '서울특별시교육청 고1·2 집중 진학상담',
    sourceUrl: 'https://www.sen.go.kr/user/bbs/BD_selectBbs.do?q_bbsDocNo=20260410143308216&q_bbsSn=1028',
  ),
  AdmissionInsight(
    grade: '고1',
    admissionYear: '2029학년도',
    tag: '학생부',
    title: '수업에서 생긴 질문을 탐구로 확장하세요',
    summary: '활동 개수보다 수업 질문이 자료 조사, 비교, 해석, 후속 질문으로 이어지는 과정이 중요합니다.',
    action: '이번 달 교과 수업에서 생긴 질문 하나를 2주 탐구 주제로 발전시키세요.',
    source: '대입정보포털 어디가',
    sourceUrl: 'https://www.adiga.kr/',
  ),
  AdmissionInsight(
    grade: '고2',
    admissionYear: '2028학년도',
    tag: '대입 개편',
    title: '통합형 수능과 내신 5등급 체제를 확인하세요',
    summary: '2028학년도부터 국어·수학·사회·과학 선택과목 없는 통합형 수능과 내신 5등급 체제가 적용됩니다.',
    action: '희망 대학 모집단위의 반영과목과 권장과목을 공식 자료집에서 확인하세요.',
    source: '교육부 2028학년도 대입 안내',
    sourceUrl: 'https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=103113&lev=0&m=0204',
  ),
  AdmissionInsight(
    grade: '고2',
    admissionYear: '2028학년도',
    tag: '대학별 계획',
    title: '2028 대학별 시행계획이 공개됐습니다',
    summary: '대입정보포털 어디가에서 2028학년도 대학별 시행계획과 모집단위별 반영과목 자료를 확인할 수 있습니다.',
    action: '관심 대학 3곳의 전형, 반영과목, 수능최저를 비교표에 입력하세요.',
    source: '대입정보포털 어디가',
    sourceUrl: 'https://www.adiga.kr/uct/ces/archiveView.do?menuId=PCUCTCES1000&prtlBbsId=26997',
  ),
  AdmissionInsight(
    grade: '고3',
    admissionYear: '2027학년도',
    tag: '수시 준비',
    title: '2027 전형별 지원 조건을 최종 점검하세요',
    summary: '교과·학종·논술·정시 전형의 대학별 반영 방식과 수능최저, 제출 서류를 공식 시행계획으로 확인해야 합니다.',
    action: '지원 후보 대학 6곳의 원서 일정과 수능최저 충족 가능성을 이번 주에 점검하세요.',
    source: '대입정보포털 어디가 2027 자료',
    sourceUrl: 'https://www.adiga.kr/uct/ces/archiveView.do?menuId=PCUCTCES1000&prtlBbsId=23508',
  ),
  AdmissionInsight(
    grade: '고3',
    admissionYear: '2027학년도',
    tag: '교육청 자료',
    title: '교육청 수시 진학지도 자료를 활용하세요',
    summary: '서울시교육청은 2027 대입 수시 진학지도 길잡이와 대학별 분석 자료를 서울진로진학정보센터에 제공합니다.',
    action: '학교 진학상담 전 질문 목록과 최근 모의고사·학생부 핵심 내용을 정리하세요.',
    source: '서울특별시교육청 2027 수시 안내',
    sourceUrl: 'https://www.sen.go.kr/user/bbs/BD_selectBbs.do?q_bbsDocNo=20260626104834741&q_bbsSn=1028',
  ),
];

List<AdmissionInsight> insightsForGrade(String grade) =>
    admissionInsights.where((item) => item.grade == grade).toList();
