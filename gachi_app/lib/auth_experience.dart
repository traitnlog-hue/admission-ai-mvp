part of 'main.dart';

class SessionUser {
  final String name;
  final String email;
  final bool isGuest;
  final String authProvider;

  const SessionUser({
    required this.name,
    required this.email,
    this.isGuest = false,
    this.authProvider = 'local',
  });
}

const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class GoogleAuthService {
  static final GoogleSignIn _signIn = GoogleSignIn.instance;
  static Future<void>? _initializing;

  static Future<void> _initialize() => _initializing ??= _signIn.initialize(
    clientId: _googleClientId.isEmpty ? null : _googleClientId,
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );

  static Future<SessionUser> authenticate() async {
    if (kIsWeb && _googleClientId.isEmpty) {
      throw const GoogleAuthSetupException(
        '웹 Google 로그인을 사용하려면 GOOGLE_CLIENT_ID를 설정해 주세요. '
        'Android·iOS 앱은 등록된 OAuth 클라이언트 설정을 사용합니다.',
      );
    }
    await _initialize();
    if (!_signIn.supportsAuthenticate()) {
      throw const GoogleAuthSetupException(
        '웹 Google 로그인은 GOOGLE_CLIENT_ID와 공식 Google 로그인 버튼 설정이 필요합니다. '
        'Android·iOS 앱에서는 등록된 OAuth 클라이언트로 로그인할 수 있습니다.',
      );
    }
    final account = await _signIn.authenticate();
    return SessionUser(
      name: account.displayName?.trim().isNotEmpty == true
          ? account.displayName!.trim()
          : account.email.split('@').first,
      email: account.email,
      authProvider: 'google',
    );
  }

  static Future<void> signOut() async {
    try {
      await _initialize();
      await _signIn.signOut();
    } catch (_) {
      // OAuth 설정이 아직 없는 환경에서도 로컬 앱 세션은 종료한다.
    }
  }
}

class GoogleAuthSetupException implements Exception {
  final String message;

  const GoogleAuthSetupException(this.message);

  @override
  String toString() => message;
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _signedInKey = 'gachi.auth.signed_in';
  static const _nameKey = 'gachi.auth.name';
  static const _emailKey = 'gachi.auth.email';
  static const _providerKey = 'gachi.auth.provider';

  bool loading = true;
  SessionUser? user;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    SessionUser? restoredUser;
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      final signedIn = preferences.getBool(_signedInKey) ?? false;
      if (signedIn) {
        restoredUser = SessionUser(
          name: preferences.getString(_nameKey) ?? 'GACHI 학생',
          email: preferences.getString(_emailKey) ?? '',
          authProvider: preferences.getString(_providerKey) ?? 'local',
        );
      }
    } catch (_) {
      restoredUser = null;
    }
    if (!mounted) return;
    setState(() {
      user = restoredUser;
      loading = false;
    });
  }

  Future<void> _authenticate(
    SessionUser nextUser, {
    bool persist = true,
  }) async {
    if (persist) {
      try {
        final preferences = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 2),
        );
        await preferences.setBool(_signedInKey, true);
        await preferences.setString(_nameKey, nextUser.name);
        await preferences.setString(_emailKey, nextUser.email);
        await preferences.setString(_providerKey, nextUser.authProvider);
      } catch (_) {
        // 세션 저장이 실패해도 현재 실행에서는 로그인 상태를 유지한다.
      }
    }
    if (!mounted) return;
    setState(() => user = nextUser);
  }

  Future<void> _logout() async {
    await GoogleAuthService.signOut();
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      await preferences.remove(_signedInKey);
      await preferences.remove(_providerKey);
    } catch (_) {
      // 로컬 저장소가 응답하지 않아도 현재 세션은 종료한다.
    }
    if (!mounted) return;
    setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return LoginPage(onAuthenticated: _authenticate);
    }
    return Shell(user: user, onLogout: _logout);
  }
}

class LoginPage extends StatefulWidget {
  final Future<void> Function(SessionUser user, {required bool persist})
  onAuthenticated;

  const LoginPage({super.key, required this.onAuthenticated});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool submitting = false;
  String? errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      final user = await GoogleAuthService.authenticate();
      await widget.onAuthenticated(user, persist: true);
    } on GoogleAuthSetupException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } on GoogleSignInException catch (_) {
      if (mounted) {
        setState(
          () => errorMessage =
              'Google 로그인을 완료하지 못했습니다. OAuth 클라이언트 설정과 네트워크를 확인해 주세요.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => errorMessage = 'Google 로그인 연결을 시작할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Logo(),
                const SizedBox(height: 40),
                const Text(
                  '다시 만나서\n반가워요.',
                  style: TextStyle(
                    color: text,
                    fontSize: 31,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Google 계정으로 진단 결과와 목표 플랜을 안전하게 이어서 관리하세요.',
                  style: TextStyle(color: mute, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: submitting ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: text,
                    backgroundColor: surface,
                    side: const BorderSide(color: Color(0xffD9DEE8)),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xffE1E5EC)),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xff4285F4),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Text(submitting ? 'Google 연결 중...' : 'Google로 계속하기'),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF1EE),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Color(0xffA53C24),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                Center(
                  child: TextButton(
                    onPressed: () => widget.onAuthenticated(
                      const SessionUser(
                        name: '체험 학생',
                        email: 'guest@gachi.local',
                        isGuest: true,
                        authProvider: 'guest',
                      ),
                      persist: false,
                    ),
                    child: const Text('로그인 없이 둘러보기'),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    '계속하면 서비스 이용약관과 개인정보 처리방침에 동의하게 됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mute, fontSize: 9, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
