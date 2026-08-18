# GACHI Flutter MVP

학습 진단, 자기주도 목표 플랜, 무료·유료 입시 분석, 학원 추천을 제공하는 Flutter MVP입니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

분석 API는 저장소 루트의 FastAPI 서버를 사용합니다. 서버가 실행되지 않은 경우 앱은 명시적으로 표시된 로컬 규칙 기반 결과를 제공합니다.

## 로그인 실행 옵션

```bash
flutter run -d chrome \
  --web-port 7357 \
  --dart-define=AUTH_API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### Supabase 이메일 로그인

MVP 기본 프로젝트에는 Supabase Auth가 연결되어 있습니다. 별도 Supabase
프로젝트로 배포할 때만 프로젝트 URL과 **Publishable key**를 Dart define으로
덮어씁니다. 이 키는 클라이언트 노출용 키이며, `service_role`·`sb_secret` 키를
모바일 또는 웹 앱에 넣으면 안 됩니다.

```bash
flutter run -d chrome \
  --web-port 7357 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

Supabase Dashboard에서 Email provider를 활성화하고, `http://127.0.0.1:7357`와
운영 도메인을 **Authentication > URL Configuration > Redirect URLs**에 등록하세요.
이메일 확인이 켜진 프로젝트는 회원가입 뒤 확인 메일을 받은 사용자가 로그인할 수
있습니다. 확인 링크로 앱에 돌아오면 Supabase 세션을 감지해 자동 로그인합니다.

웹 Google 로그인은 커스텀 버튼이 아니라 Google Identity Services 공식 버튼을
렌더링합니다. Google Cloud의 승인된 JavaScript 원본에 로컬 및 운영 도메인이
등록되어 있어야 합니다. 이메일 로그인은 루트 FastAPI 서버의 계정 API를
사용하며, 실명인증은 계약한 본인확인 사업자의 서버 URL을 설정한 뒤 활성화됩니다.

## 로그인

앱 로그인·로그아웃은 공식 `google_sign_in` SDK에 연결되어 있습니다. 체험 모드는 로그인 없이 UX를 확인하기 위한 별도 흐름입니다.

Android는 Google Cloud/Firebase에 실제 패키지명과 debug·release·Play App Signing SHA 인증서를 등록하고 `android/app/google-services.json`을 추가하거나, Web OAuth 클라이언트 ID를 `GOOGLE_SERVER_CLIENT_ID`로 전달해야 합니다.

```bash
flutter run -d android \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID
```

iOS는 OAuth iOS 클라이언트와 URL Scheme을 `ios/Runner/Info.plist`에 등록해야 합니다. 웹은 Web OAuth 클라이언트 ID와 Google 공식 웹 버튼 구성이 추가로 필요합니다. 운영 서비스에서는 앱에서 받은 Google ID 토큰을 서버에서 검증하고 자체 세션을 발급해야 합니다.

## 카카오맵

학원 추천 결과는 카카오맵 공식 검색 URL로 연결됩니다. 이 방식은 별도의 앱 키가 필요하지 않습니다. 앱 안에 지도를 직접 삽입하려면 카카오 JavaScript 또는 네이티브 지도 키와 허용 도메인을 별도로 설정해야 합니다.

## 결제

Android·iOS 결제는 공식 `in_app_purchase` SDK를 사용하며 Google Play Billing과 Apple StoreKit에 연결됩니다. 기본 상품 ID는 `gachi_admission_pro`입니다. 실제 청구를 열기 전에 두 스토어에 같은 상품을 등록하고, 영수증을 서버에서 검증하는 API를 연결해야 합니다.

```bash
flutter run -d android \
  --dart-define=STORE_PRODUCT_ID=gachi_admission_pro \
  --dart-define=PURCHASE_VERIFICATION_URL=https://api.example.com/purchases/verify
```

검증 API는 앱이 전송하는 `productId`, `purchaseId`, `source`, `serverVerificationData`를 Google Play Developer API 또는 App Store Server API로 검증하고 성공 시 `{ "valid": true }`를 반환해야 합니다. 검증 URL이 없으면 앱은 실제 구매를 시작하지 않습니다. 구매 복원 기능도 포함되어 있습니다.

웹 체크아웃을 별도로 운영할 경우 기존 URL 연결도 사용할 수 있습니다.

```bash
flutter run -d chrome \
  --dart-define=PAYMENT_CHECKOUT_URL=https://your-domain.example/checkout
```

앱은 `orderId`, `orderName`, `amount`, `method` 쿼리 파라미터를 전달합니다. 웹 결제도 반드시 서버에서 승인 금액과 웹훅을 검증한 뒤 사용자 권한을 부여해야 합니다.
