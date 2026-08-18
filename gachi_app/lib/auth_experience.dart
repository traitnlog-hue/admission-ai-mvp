part of 'main.dart';

class SessionUser {
  final String name;
  final String email;
  final bool isGuest;
  final String authProvider;
  final String? authToken;
  final bool isIdentityVerified;
  final String? identityProvider;

  const SessionUser({
    required this.name,
    required this.email,
    this.isGuest = false,
    this.authProvider = 'local',
    this.authToken,
    this.isIdentityVerified = false,
    this.identityProvider,
  });
}

const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const _authApiBaseUrl = String.fromEnvironment(
  'AUTH_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

class GoogleAuthService {
  static final GoogleSignIn _signIn = GoogleSignIn.instance;
  static Future<void>? _initializing;

  static Future<void> prepare() => _initializing ??= _signIn.initialize(
    clientId: _googleClientId.isEmpty ? null : _googleClientId,
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );

  static Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _signIn.authenticationEvents;

  static SessionUser fromAccount(GoogleSignInAccount account) => SessionUser(
    name: account.displayName?.trim().isNotEmpty == true
        ? account.displayName!.trim()
        : account.email.split('@').first,
    email: account.email,
    authProvider: 'google',
  );

  static Future<SessionUser> authenticate() async {
    await prepare();
    if (!_signIn.supportsAuthenticate()) {
      throw const GoogleAuthSetupException(
        '웹에서는 Google이 제공하는 공식 로그인 버튼을 사용해야 합니다.',
      );
    }
    return fromAccount(await _signIn.authenticate());
  }

  static Future<void> signOut() async {
    try {
      await prepare();
      await _signIn.signOut();
    } catch (_) {
      // OAuth가 아직 설정되지 않은 환경에서도 앱 세션은 종료한다.
    }
  }
}

class GoogleAuthSetupException implements Exception {
  final String message;
  const GoogleAuthSetupException(this.message);
  @override
  String toString() => message;
}

class EmailAuthService {
  static Uri _uri(String path) => Uri.parse('$_authApiBaseUrl$path');

  static Future<SessionUser> authenticate({
    required bool createAccount,
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http
        .post(
          _uri(createAccount ? '/api/auth/register' : '/api/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            if (createAccount) 'name': name.trim(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EmailAuthException(body['detail']?.toString() ?? '로그인에 실패했습니다.');
    }
    return _fromResponse(body);
  }

  static Future<SessionUser> currentUser(String token) async {
    final response = await http
        .get(_uri('/api/auth/me'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw const EmailAuthException('로그인 세션이 만료되었습니다.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _fromResponse({...body, 'token': token});
  }

  static Future<void> logout(String token) async {
    try {
      await http
          .post(
            _uri('/api/auth/logout'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // 서버 연결과 관계없이 기기의 세션을 지운다.
    }
  }

  static SessionUser _fromResponse(Map<String, dynamic> body) {
    final user = body['user'] as Map<String, dynamic>;
    return SessionUser(
      name: user['name']?.toString() ?? 'GACHI 학생',
      email: user['email']?.toString() ?? '',
      authProvider: 'email',
      authToken: body['token']?.toString(),
      isIdentityVerified: user['identity_verified'] == true,
      identityProvider: user['identity_provider']?.toString(),
    );
  }
}

class EmailAuthException implements Exception {
  final String message;
  const EmailAuthException(this.message);
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
  static const _tokenKey = 'gachi.auth.token';
  static const _identityVerifiedKey = 'gachi.auth.identity_verified';

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
      if (preferences.getBool(_signedInKey) ?? false) {
        final provider = preferences.getString(_providerKey) ?? 'local';
        final token = preferences.getString(_tokenKey);
        if (provider == 'email' && token != null && token.isNotEmpty) {
          try {
            restoredUser = await EmailAuthService.currentUser(token);
          } catch (_) {
            await preferences.remove(_signedInKey);
            await preferences.remove(_tokenKey);
          }
        } else {
          restoredUser = SessionUser(
            name: preferences.getString(_nameKey) ?? 'GACHI 학생',
            email: preferences.getString(_emailKey) ?? '',
            authProvider: provider,
            isIdentityVerified:
                preferences.getBool(_identityVerifiedKey) ?? false,
          );
        }
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
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_signedInKey, true);
        await preferences.setString(_nameKey, nextUser.name);
        await preferences.setString(_emailKey, nextUser.email);
        await preferences.setString(_providerKey, nextUser.authProvider);
        await preferences.setBool(
          _identityVerifiedKey,
          nextUser.isIdentityVerified,
        );
        if (nextUser.authToken != null) {
          await preferences.setString(_tokenKey, nextUser.authToken!);
        }
      } catch (_) {
        // 저장소 오류가 있어도 현재 실행 중인 세션은 유지한다.
      }
    }
    if (mounted) setState(() => user = nextUser);
  }

  Future<void> _logout() async {
    if (user?.authProvider == 'google') await GoogleAuthService.signOut();
    if (user?.authProvider == 'email' && user?.authToken != null) {
      await EmailAuthService.logout(user!.authToken!);
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_signedInKey);
      await preferences.remove(_providerKey);
      await preferences.remove(_tokenKey);
    } catch (_) {}
    if (mounted) setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) return LoginPage(onAuthenticated: _authenticate);
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  StreamSubscription<GoogleSignInAuthenticationEvent>? googleSubscription;
  bool createAccount = false;
  bool submitting = false;
  bool obscurePassword = true;
  bool googleReady = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareGoogle();
  }

  Future<void> _prepareGoogle() async {
    if (kIsWeb && _googleClientId.isEmpty) return;
    try {
      await GoogleAuthService.prepare();
      googleSubscription = GoogleAuthService.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            await widget.onAuthenticated(
              GoogleAuthService.fromAccount(event.user),
              persist: true,
            );
          }
        },
        onError: (_) {
          if (mounted) {
            setState(
              () => errorMessage = 'Google 로그인에 실패했습니다. OAuth 설정을 확인해 주세요.',
            );
          }
        },
      );
      if (mounted) setState(() => googleReady = true);
    } catch (_) {
      if (mounted) setState(() => googleReady = false);
    }
  }

  @override
  void dispose() {
    googleSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      await widget.onAuthenticated(
        await GoogleAuthService.authenticate(),
        persist: true,
      );
    } on GoogleSignInException catch (_) {
      if (mounted) setState(() => errorMessage = 'Google 로그인을 완료하지 못했습니다.');
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();
    if (!email.contains('@')) {
      setState(() => errorMessage = '올바른 이메일 주소를 입력해 주세요.');
      return;
    }
    if (password.length < 8) {
      setState(() => errorMessage = '비밀번호는 8자 이상 입력해 주세요.');
      return;
    }
    if (createAccount && name.length < 2) {
      setState(() => errorMessage = '이름은 2자 이상 입력해 주세요.');
      return;
    }
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      final user = await EmailAuthService.authenticate(
        createAccount: createAccount,
        email: email,
        password: password,
        name: name,
      );
      await widget.onAuthenticated(user, persist: true);
    } on EmailAuthException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => errorMessage = '로그인 서버에 연결할 수 없습니다. API 서버 실행 상태를 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffD9DEE8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffD9DEE8)),
        ),
      );

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
                const SizedBox(height: 34),
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
                  '계정 하나로 진단 결과와 목표 플랜을 안전하게 이어서 관리하세요.',
                  style: TextStyle(color: mute, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 24),
                if (googleReady)
                  buildGoogleLoginButton(onPressed: _signInWithGoogle)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Google 로그인 준비 필요 · GOOGLE_CLIENT_ID와 허용 도메인을 설정해 주세요.',
                      style: TextStyle(color: Color(0xff8A5300), fontSize: 11),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '또는 이메일',
                          style: TextStyle(color: mute, fontSize: 11),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('로그인')),
                    ButtonSegment(value: true, label: Text('회원가입')),
                  ],
                  selected: {createAccount},
                  showSelectedIcon: false,
                  onSelectionChanged: submitting
                      ? null
                      : (value) => setState(() {
                          createAccount = value.first;
                          errorMessage = null;
                        }),
                ),
                const SizedBox(height: 16),
                if (createAccount) ...[
                  TextField(
                    key: const Key('email-name-field'),
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('이름', Icons.person_outline),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  key: const Key('email-address-field'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: _inputDecoration('이메일', Icons.mail_outline),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('email-password-field'),
                  controller: passwordController,
                  obscureText: obscurePassword,
                  onSubmitted: (_) => _submitEmail(),
                  decoration: _inputDecoration('비밀번호', Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('email-submit-button'),
                  onPressed: submitting ? null : _submitEmail,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    submitting
                        ? '처리 중...'
                        : createAccount
                        ? '이메일로 가입하기'
                        : '이메일로 로그인',
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
                const SizedBox(height: 8),
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
