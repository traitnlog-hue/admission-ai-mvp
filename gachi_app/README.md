# GACHI Flutter MVP

학습 진단, 자기주도 목표 플랜, 무료·유료 입시 분석, 학원 추천을 제공하는 Flutter MVP입니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

분석 API는 저장소 루트의 FastAPI 서버를 사용합니다. 서버가 실행되지 않은 경우 앱은 명시적으로 표시된 로컬 규칙 기반 결과를 제공합니다.

## 로그인

현재 로그인은 UI·세션 흐름 검증을 위한 로컬 MVP 구현입니다. 이메일과 이름만 기기에 유지하며 비밀번호는 저장하지 않습니다. 운영 배포 전에는 서버 기반 인증, 이메일 검증, 비밀번호 재설정과 토큰 만료 처리가 필요합니다.

## 카카오맵

학원 추천 결과는 카카오맵 공식 검색 URL로 연결됩니다. 이 방식은 별도의 앱 키가 필요하지 않습니다. 앱 안에 지도를 직접 삽입하려면 카카오 JavaScript 또는 네이티브 지도 키와 허용 도메인을 별도로 설정해야 합니다.

## 결제

기본값은 실제 청구가 발생하지 않는 테스트 결제 모드입니다. 운영 결제 서버가 준비되면 다음과 같이 체크아웃 URL을 주입할 수 있습니다.

```bash
flutter run -d chrome \
  --dart-define=PAYMENT_CHECKOUT_URL=https://your-domain.example/checkout
```

앱은 `orderId`, `orderName`, `amount`, `method` 쿼리 파라미터를 전달합니다. 운영 결제에서는 반드시 서버에서 결제 승인, 금액 검증, 웹훅 검증과 사용자 권한 부여를 처리해야 합니다.
