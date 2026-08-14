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
