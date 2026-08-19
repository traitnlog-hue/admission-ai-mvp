# 진로입시 AI MVP

고등학생의 내신, 모의고사, 학생부·세특·활동, 희망 전공을 하나의 전략 화면에서 분석하는 FastAPI 기반 MVP입니다.

## 실행

프로젝트 폴더에서 가상환경을 만들고 의존성을 설치한 뒤 서버를 실행합니다.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn backend.app.main:app --reload
```

Flutter 앱은 기본적으로 `http://127.0.0.1:8000`의 API를 사용합니다. 다른 주소를
사용하려면 `--dart-define=AUTH_API_BASE_URL=https://api.example.com`을 추가하세요.

## 로그인과 실명인증 설정

- Supabase 이메일 로그인은 MVP 기본 프로젝트에 연결되어 바로 활성화됩니다.
  별도 Supabase 프로젝트로 배포할 때만 `SUPABASE_URL`과
  `SUPABASE_PUBLISHABLE_KEY`를 실행 옵션으로 덮어쓰세요. Dashboard의
  **Connect**에서 URL과 **Publishable key**를 복사하며, `service_role` 또는
  `sb_secret` 키는 앱에 절대 넣으면 안 됩니다.
  ```bash
  flutter run -d chrome \
    --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
    --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
  ```
  Supabase Dashboard의 **Authentication > Providers**에서 Email을 활성화하고,
  이메일 확인을 켠 경우 가입 뒤 확인 메일을 받은 사용자가 다시 로그인하도록
  안내됩니다. 웹 개발 주소 `http://127.0.0.1:7357`와 운영 도메인은
  **Authentication > URL Configuration**의 Redirect URLs에 등록하세요.
- 기존 FastAPI `/api/auth/*` 계정/세션 API는 로컬 개발 호환용으로 유지됩니다.
  운영 환경은 HTTPS를 적용하고 `GACHI_AUTH_PEPPER`를 서버 비밀값으로 설정하세요.
- 웹 Google 로그인은 Google Cloud에서 Web OAuth 클라이언트를 만든 뒤 실행 시
  `--dart-define=GOOGLE_CLIENT_ID=...apps.googleusercontent.com`을 전달해야 합니다.
  `http://localhost:7357`, 운영 도메인 등을 승인된 JavaScript 원본에 등록하세요.
- Android/iOS는 각 플랫폼 OAuth 설정 파일과 서명 인증서 등록이 별도로 필요합니다.
- 실명인증은 PASS/NICE/KCB 등 사업자 계약 후 서버의
  `IDENTITY_VERIFICATION_URL`을 설정해야 시작됩니다. 앱은 주민등록번호나 신분증
  원본을 직접 저장하지 않으며, 콜백의 서명 검증과 인증 상태 갱신은 운영 연동 시
  반드시 서버에서 처리해야 합니다.

그 후 `http://127.0.0.1:8000`으로 접속합니다. API 문서는 `http://127.0.0.1:8000/docs`에서 확인할 수 있습니다.

## 현재 범위

- 학업·수능·과목선택·학생부 역량 산출
- 교과·학종·정시·논술 전략 우선순위 제안
- 전공 키워드 기반 학생부 연결성 점검
- 개인별 액션 플랜 및 지원 전 확인사항
- 반응형 PC/모바일 UI
- `POST /api/analyze` REST API 및 `GET /api/health` 상태 확인 API
- 가상 대학 전형 데이터로 API 연동 흐름 검증
- SQLite 기반 `연도 × 대학 × 모집단위 × 전형` 입시 DB 스키마
- 전형별 출처 URL·검증일·데이터 상태(sample/verified) 관리

점수는 **전략 진단용 내부 값**이며 합격 가능성 또는 대학별 합격선을 의미하지 않습니다. 실제 대학 추천에는 해당 학년도 공식 모집요강, 전형별 모집인원, 교과 환산식, 수능최저, 전년도 입시결과를 포함한 검증된 DB와 서버 측 Rule Engine이 필요합니다.

## Vertex AI 입시 코칭 보조 (선택)

`POST /api/ai-admission-analysis`는 규칙 기반 분석 결과를 학생이 이해하기 쉬운 학습 코칭 문장으로 보조합니다. 이 API는 로그인한 회원만 사용할 수 있고, 합격 확률·합격선·특정 대학의 합격 가능성을 생성하지 않습니다.

- Vertex AI API를 사용 설정한 Google Cloud 프로젝트에서만 서버 환경변수를 설정합니다.
- 앱에 API 키를 넣지 않습니다. Cloud Run 배포 시 서비스 계정에 `Vertex AI User` 역할만 부여하고, 서비스 계정 키 파일은 만들지 않습니다.
- 기본 제한은 회원당 하루 3회·전체 하루 20회·응답 700 토큰입니다. Cloud Run은 `--max-instances=1`로 배포해 MVP 한도가 인스턴스 전체에 적용되게 합니다.
- 예산 알림은 비용을 자동으로 차단하지 않으므로, 무료 체험판을 유지하고 앱의 요청 제한도 반드시 함께 사용합니다.

```bash
export GOOGLE_CLOUD_PROJECT=mompass
export GOOGLE_CLOUD_LOCATION=global
export GACHI_AI_ANALYSIS_ENABLED=true
export GACHI_AI_DAILY_LIMIT=3
export GACHI_AI_GLOBAL_DAILY_LIMIT=20
export GACHI_VERTEX_MODEL=gemini-2.5-flash
uvicorn backend.app.main:app
```

## 테스트

```bash
pytest
```

## 입시 DB 운영 원칙

`backend/data/admissions.sqlite3`은 처음 실행할 때 가상 데이터를 자동 등록합니다. 실제 데이터를 넣을 때는 반드시 대학 공식 모집요강 또는 대학 입학처가 공시한 전년도 입시결과의 URL, 확인일, 전형별 변경사항을 함께 보관하고 `data_status`를 `verified`로 설정해야 합니다. 검증되지 않은 데이터는 실제 컨설팅 판단에 사용하지 않습니다.

## 무료 학원 추천 데이터

유료 API 없이 `backend/data/academies.free.csv`를 사용합니다. [전국학원및교습소표준데이터](https://www.data.go.kr/data/15096277/standard.do?recommendDataYn=Y)를 무료로 내려받아 필요한 서울 지역의 정상 운영 학원만 `academies.free.template.csv` 형식으로 정리해 저장하세요. `POST /api/academy-recommendations`는 지역·학년·과목·학습 수준을 기준으로 점수를 매기며, 학생 개인정보를 서버에 저장하지 않습니다.

### 공식 데이터 등록

[CSV 템플릿](/Users/jangchanmi/Documents/ChatGPT/입시%20컨설팅%20분석%20프로그램/backend/data/admissions.template.csv)을 복사해 공식 출처·검증일을 모두 채웁니다. `ADMIN_API_TOKEN`을 설정한 뒤 `POST /api/admin/import-admissions`에 CSV 본문과 `X-Admin-Token` 헤더를 전송하면 검증된 전형으로 등록 또는 갱신됩니다. 이 관리자 API는 인증 없이 운영하면 안 됩니다.
