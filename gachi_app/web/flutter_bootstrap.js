// 로컬 MVP 검토 중에는 이전 웹 번들이 서비스 워커에 남아
// 화면 수정이 늦게 반영되지 않도록 서비스 워커를 등록하지 않습니다.
{{flutter_js}}
{{flutter_build_config}}

// 이전 서비스 워커가 이미 설치된 브라우저도 항상 새 main.dart.js를 받습니다.
_flutter.buildConfig.builds = _flutter.buildConfig.builds.map((build) =>
  build.mainJsPath == null
    ? build
    : {...build, mainJsPath: `${build.mainJsPath}?v=${Date.now()}`},
);

const loadGachiApp = () => _flutter.loader.load({});
const isLocalPreview =
  window.location.hostname === '127.0.0.1' ||
  window.location.hostname === 'localhost';

// 기존 Flutter 서비스 워커와 Cache Storage만 제거합니다. SharedPreferences가
// 사용하는 Local Storage(등록 학생 정보)는 삭제하지 않습니다.
if (isLocalPreview && 'serviceWorker' in navigator) {
  Promise.all([
    navigator.serviceWorker
      .getRegistrations()
      .then((registrations) => Promise.all(registrations.map((item) => item.unregister()))),
    window.caches
      .keys()
      .then((keys) => Promise.all(keys.map((key) => window.caches.delete(key)))),
  ]).finally(loadGachiApp);
} else {
  loadGachiApp();
}
