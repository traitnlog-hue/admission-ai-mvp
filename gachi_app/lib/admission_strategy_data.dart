class AdmissionTargetGroup {
  final String id;
  final String title;
  final String shortLabel;
  final String summary;
  final int colorValue;
  final List<String> universities;
  final List<String> majors;
  final List<String> coreSubjects;
  final List<String> evaluationFocus;
  final List<String> freeChecks;
  final List<String> premiumChecks;
  final List<String> routes;
  final String sourceName;
  final String sourceUrl;

  const AdmissionTargetGroup({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.summary,
    required this.colorValue,
    required this.universities,
    required this.majors,
    required this.coreSubjects,
    required this.evaluationFocus,
    required this.freeChecks,
    required this.premiumChecks,
    required this.routes,
    required this.sourceName,
    required this.sourceUrl,
  });
}

class AdmissionOfficialSource {
  final String title;
  final String description;
  final String url;

  const AdmissionOfficialSource({
    required this.title,
    required this.description,
    required this.url,
  });
}

const admissionOfficialSources = <AdmissionOfficialSource>[
  AdmissionOfficialSource(
    title: '교육부 2028 대입개편',
    description: '통합형 수능·내신 5등급체제 공식 안내',
    url: 'https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=97551&lev=0&m=020402&opType=N&s=moe&statusYN=W',
  ),
  AdmissionOfficialSource(
    title: '대입정보포털 어디가',
    description: '대학·전공·전형별 공식 정보 통합 탐색',
    url: 'https://www.adiga.kr',
  ),
  AdmissionOfficialSource(
    title: '서울대 2027·2028',
    description: '대학입학전형 시행계획·모집요강',
    url: 'https://admission.snu.ac.kr/undergraduate/notice',
  ),
  AdmissionOfficialSource(
    title: '연세대 2027·2028',
    description: '시행계획·전공 연계 권장과목 자료',
    url: 'https://admission.yonsei.ac.kr/seoul/admission/html/counsel/notice.asp?s_data=27',
  ),
  AdmissionOfficialSource(
    title: '고려대 2027',
    description: '대학입학전형 시행계획 공식 자료',
    url: 'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1712&BOARD_SEQ=5&CONTENTS_NO=2&MENU_ID=750&SITE_NO=2',
  ),
  AdmissionOfficialSource(
    title: '대교협 2027 기본사항',
    description: '학년도별 대입전형 운영 기준',
    url: 'https://www.kcue.or.kr/news/sub02/sub01.php?at=view&idx=2764313',
  ),
];

const admissionTargetGroups = <AdmissionTargetGroup>[
  AdmissionTargetGroup(
    id: 'sky',
    title: 'SKY',
    shortLabel: '서울대·연세대·고려대',
    summary: '대학별 평가 방식과 전공 연계 과목을 분리해 학생부·수능·면접 전략을 설계합니다.',
    colorValue: 0xff2455C3,
    universities: ['서울대학교', '연세대학교', '고려대학교'],
    majors: ['경영·경제', '컴퓨터·AI', '공학', '자연과학', '인문·사회', '자유전공'],
    coreSubjects: ['국어', '수학', '영어', '사회·과학', '전공 연계 선택과목'],
    evaluationFocus: ['교과 성취와 추이', '전공 연계 과목 이수', '탐구의 깊이', '면접·논술 대비'],
    freeChecks: ['내신과 모의고사의 강약 비교', '학생부 탐구 흐름 확인', '수시·정시 우선순위 진단'],
    premiumChecks: [
      '3개 대학 전형별 GAP 매트릭스',
      '전공별 권장과목 이수 점검',
      '학생부 문장별 근거 분석',
      '면접·논술 준비 캘린더',
    ],
    routes: ['학생부종합', '학생부교과·추천', '논술', '정시'],
    sourceName: '서울대학교 입학본부 2027·2028 전형자료',
    sourceUrl: 'https://admission.snu.ac.kr/undergraduate/notice',
  ),
  AdmissionTargetGroup(
    id: 'medical',
    title: '의치한약수',
    shortLabel: '의·치·한·약·수의',
    summary: '높은 학업 안정성뿐 아니라 과학 교과 선택, 수능최저, 면접과 지역인재 자격을 함께 확인합니다.',
    colorValue: 0xffC43B55,
    universities: ['의과대학', '치과대학', '한의과대학', '약학대학', '수의과대학'],
    majors: ['의예', '치의예', '한의예', '약학', '수의예'],
    coreSubjects: ['수학', '생명과학', '화학', '국어', '영어'],
    evaluationFocus: ['수능최저 충족 안정성', '과학 교과 위계', '생명윤리·의료 탐구', 'MMI·서류 면접'],
    freeChecks: ['내신·수능 안정성 비교', '과학 핵심과목 준비도', '의료계열 탐구 일관성 확인'],
    premiumChecks: [
      '대학별 수능최저 시뮬레이션',
      '지역인재 지원자격 점검',
      'MMI 예상 질문과 답변 구조',
      '6개 지원 조합 리스크 분석',
    ],
    routes: ['학생부종합', '학생부교과·지역인재', '논술', '정시'],
    sourceName: '대입정보포털 어디가 2027 전형정보',
    sourceUrl: 'https://www.adiga.kr',
  ),
  AdmissionTargetGroup(
    id: 'ai_semiconductor',
    title: 'AI·컴퓨터·반도체',
    shortLabel: '첨단 공학',
    summary: '수학·과학·정보 과목의 위계와 문제 해결 프로젝트를 중심으로 전공 준비도를 봅니다.',
    colorValue: 0xff6846C7,
    universities: ['주요 대학 공과대학', '첨단학과', '계약학과'],
    majors: ['컴퓨터공학', '인공지능', '데이터과학', '반도체', '전자전기'],
    coreSubjects: ['수학', '물리학', '화학', '정보', '영어'],
    evaluationFocus: ['수학·과학 성취', '정보·코딩 활용', '문제 정의와 실험', '프로젝트 결과물'],
    freeChecks: ['핵심교과 성취 확인', '프로젝트 경험 점검', '학종·정시 우선순위 진단'],
    premiumChecks: [
      '대학별 권장과목 이수 비교',
      '프로젝트 포트폴리오 구조화',
      '전공면접 질문 설계',
      '첨단학과 지원 조합 분석',
    ],
    routes: ['학생부종합', '학생부교과', '논술', '정시'],
    sourceName: '교육부 2028 모집단위별 반영과목 안내',
    sourceUrl: 'https://www.moe.go.kr/boardCnts/viewRenew.do?boardID=294&boardSeq=103113&lev=0&m=0204',
  ),
  AdmissionTargetGroup(
    id: 'business',
    title: '경영·경제',
    shortLabel: '상경계열',
    summary: '수학적 분석력, 사회 현상 해석과 데이터 기반 탐구를 연결해 상경계열 준비도를 진단합니다.',
    colorValue: 0xff168A73,
    universities: ['주요 대학 경영대학', '경제학부', '융합사회계열'],
    majors: ['경영학', '경제학', '통계학', '금융', '국제통상'],
    coreSubjects: ['수학', '국어', '영어', '경제', '사회문화'],
    evaluationFocus: ['수리·자료 해석', '사회문제 탐구', '논리적 글쓰기', '팀 프로젝트·리더십'],
    freeChecks: ['수학·국어 균형 확인', '경제·사회 탐구 경험', '수시·정시 경쟁력 비교'],
    premiumChecks: [
      '대학별 상경계열 전형 비교',
      '탐구 주제 차별화',
      '논술·면접 준비도 분석',
      '지원 조합 리스크 점검',
    ],
    routes: ['학생부종합', '학생부교과', '논술', '정시'],
    sourceName: '한국대학교육협의회 2027 대입전형 기본사항',
    sourceUrl:
        'https://www.kcue.or.kr/news/sub02/sub01.php?at=view&idx=2764313',
  ),
  AdmissionTargetGroup(
    id: 'bio',
    title: '바이오·생명',
    shortLabel: '생명·보건 연구',
    summary: '생명과학·화학의 교과 성취와 실험 설계, 데이터 해석 경험을 중심으로 준비합니다.',
    colorValue: 0xff2B7A52,
    universities: ['주요 대학 자연과학대학', '생명과학대학', '보건계열'],
    majors: ['생명과학', '생명공학', '화학', '식품영양', '보건정책'],
    coreSubjects: ['생명과학', '화학', '수학', '영어', '정보'],
    evaluationFocus: ['과학 교과 성취', '실험 설계와 안전', '데이터 해석', '윤리적 쟁점 탐구'],
    freeChecks: ['과학 핵심과목 확인', '실험·탐구 활동 점검', '자연계 전형 우선순위 진단'],
    premiumChecks: [
      '세부 전공별 과목 매칭',
      '실험보고서 근거 분석',
      '대학별 전형요소 비교',
      '4주 탐구 보완 로드맵',
    ],
    routes: ['학생부종합', '학생부교과', '논술', '정시'],
    sourceName: '서울대학교 2028 전공 연계 과목 선택 안내',
    sourceUrl: 'https://admission.snu.ac.kr/undergraduate/notice',
  ),
  AdmissionTargetGroup(
    id: 'humanities_media',
    title: '심리·미디어·사회',
    shortLabel: '인문사회 선호전공',
    summary: '읽기·쓰기·사회 조사와 사람·콘텐츠에 대한 탐구를 학생부의 일관된 이야기로 연결합니다.',
    colorValue: 0xffC06A22,
    universities: ['주요 대학 인문대학', '사회과학대학', '미디어계열'],
    majors: ['심리학', '미디어', '정치외교', '사회학', '교육학'],
    coreSubjects: ['국어', '영어', '사회문화', '윤리', '수학·통계'],
    evaluationFocus: ['읽기·쓰기 역량', '사회 조사 방법', '데이터 해석', '주제의 확장성'],
    freeChecks: ['국어·영어 성취 확인', '사회 탐구 흐름 점검', '학종·논술 우선순위 진단'],
    premiumChecks: [
      '전공별 탐구 키워드 맵',
      '학생부 활동 연결성 분석',
      '논술·면접 질문 설계',
      '대학별 지원 조합 비교',
    ],
    routes: ['학생부종합', '학생부교과', '논술', '정시'],
    sourceName: '연세대학교·고려대학교 2027·2028 전형자료',
    sourceUrl: 'https://admission.yonsei.ac.kr/seoul/admission/html/counsel/notice.asp?s_data=27',
  ),
];

AdmissionTargetGroup admissionTargetById(String id) =>
    admissionTargetGroups.firstWhere(
      (group) => group.id == id,
      orElse: () => admissionTargetGroups.first,
    );
