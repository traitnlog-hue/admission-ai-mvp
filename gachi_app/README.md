# GACHI Flutter MVP

학습 진단, 자기주도 목표 플랜, 무료·유료 입시 분석, 학원 추천을 제공하는 Flutter MVP입니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

분석 API는 저장소 루트의 FastAPI 서버를 사용합니다. 서버가 실행되지 않은 경우 앱은 명시적으로 표시된 로컬 규칙 기반 결과를 제공합니다.

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
