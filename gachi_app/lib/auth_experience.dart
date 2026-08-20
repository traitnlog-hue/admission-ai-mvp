part of 'main.dart';

enum AppUserRole {
  student,
  parent,
  consultant,
  admin;

  static AppUserRole fromClaim(Object? claim) => switch (claim?.toString()) {
    'parent' => AppUserRole.parent,
    'consultant' => AppUserRole.consultant,
    'admin' => AppUserRole.admin,
    _ => AppUserRole.student,
  };

  String get label => switch (this) {
    AppUserRole.student => '학생',
    AppUserRole.parent => '학부모',
    AppUserRole.consultant => '입시 전문가',
    AppUserRole.admin => '관리자',
  };
}

class SessionUser {
  final String name;
  final String email;
  final bool isGuest;
  final String authProvider;
  final String? authToken;
  final bool isIdentityVerified;
  final String? identityProvider;
  final AppUserRole role;
  final AppUserRole? requestedRole;

  const SessionUser({
    required this.name,
    required this.email,
    this.isGuest = false,
    this.authProvider = 'local',
    this.authToken,
    this.isIdentityVerified = false,
    this.identityProvider,
    this.role = AppUserRole.student,
    this.requestedRole,
  });

  bool get isAdmin => role == AppUserRole.admin;
  bool get needsConsultantVerification =>
      requestedRole == AppUserRole.consultant && role != AppUserRole.consultant;
}

class AccountRoleResult {
  final SessionUser user;
  final bool needsConsultantVerification;

  const AccountRoleResult({
    required this.user,
    required this.needsConsultantVerification,
  });
}

class AccountRoleException implements Exception {
  final String message;
  const AccountRoleException(this.message);
  @override
  String toString() => message;
}

const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const _authApiBaseUrl = String.fromEnvironment(
  'AUTH_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://pimaydummhqoacrezkco.supabase.co',
);
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_SkSQFi9-kQO5zki89gQMFw_Y_Oza1p2',
);

class SupabaseAuthService {
  static bool _initialized = false;

  static bool get isEnabled => _initialized;

  static String? get emailRedirectUrl => kIsWeb ? Uri.base.origin : null;

  static Future<void> initialize() async {
    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) return;
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
    _initialized = true;
  }

  static Future<SessionUser?> restoreUser() async {
    if (!isEnabled) return null;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return null;
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      final user = response.user ?? currentUser;
      return fromUser(user);
    } catch (_) {
      // 네트워크가 잠시 끊겨도 저장된 Supabase 세션은 사용할 수 있다.
      return fromUser(currentUser);
    }
  }

  static Future<SessionUser> authenticate({
    required bool createAccount,
    required String email,
    required String password,
    required String name,
    required AppUserRole requestedRole,
  }) async {
    if (!isEnabled) {
      throw const EmailAuthException('Supabase Auth 설정이 필요합니다.');
    }
    final response = createAccount
        ? await Supabase.instance.client.auth.signUp(
            email: email.trim(),
            password: password,
            data: {
              'full_name': name.trim(),
              'requested_account_type': requestedRole.name,
            },
            emailRedirectTo: emailRedirectUrl,
          )
        : await Supabase.instance.client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
    final signedInUser = response.user;
    if (signedInUser == null) {
      throw const EmailAuthException('Supabase 로그인을 완료하지 못했습니다.');
    }
    if (createAccount && response.session == null) {
      throw const EmailConfirmationRequired();
    }
    return fromUser(signedInUser);
  }

  /// 서버가 관리하는 app_metadata에만 기본 역할을 반영한다.
  /// 입시 전문가·관리자 역할은 여기서 절대 부여하지 않는다.
  static Future<AccountRoleResult> selectAccountRole(
    AppUserRole requestedRole,
  ) async {
    if (!isEnabled) {
      return AccountRoleResult(
        user: const SessionUser(name: 'GACHI 사용자', email: ''),
        needsConsultantVerification: requestedRole == AppUserRole.consultant,
      );
    }
    final result = await Supabase.instance.client.functions.invoke(
      'select-account-role',
      body: {'role': requestedRole.name},
    );
    if (result.data is Map && (result.data as Map)['error'] != null) {
      throw AccountRoleException((result.data as Map)['error'].toString());
    }
    final response = result.data is Map
        ? Map<String, dynamic>.from(result.data as Map)
        : const <String, dynamic>{};
    final refreshed = await Supabase.instance.client.auth.refreshSession();
    final next = refreshed.user ?? Supabase.instance.client.auth.currentUser;
    if (next == null) {
      throw const AccountRoleException('역할 변경 후 세션을 확인하지 못했습니다.');
    }
    return AccountRoleResult(
      user: fromUser(next),
      needsConsultantVerification: response['status'] == 'verification_required',
    );
  }

  static Future<void> logout() async {
    if (isEnabled) await Supabase.instance.client.auth.signOut();
  }

  static Future<void> sendPasswordReset(String email) async {
    if (!isEnabled) {
      throw const EmailAuthException('Supabase Auth 설정이 필요합니다.');
    }
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: emailRedirectUrl,
    );
  }

  /// 웹과 모바일 브라우저에서 Supabase가 관리하는 Google OAuth 흐름을 연다.
  /// Google Client Secret은 앱에 두지 않고 Supabase Auth에만 보관한다.
  static Future<void> signInWithGoogle() async {
    if (!isEnabled) {
      throw const EmailAuthException('Supabase Auth 설정이 필요합니다.');
    }
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: emailRedirectUrl,
      // Google 브라우저 세션이 남아 있어도 매번 계정을 직접 선택하게 한다.
      queryParams: const {'prompt': 'select_account'},
    );
  }

  static SessionUser fromUser(User user) {
    final metadataName = user.userMetadata?['full_name']?.toString().trim();
    final email = user.email ?? '';
    return SessionUser(
      name: metadataName?.isNotEmpty == true
          ? metadataName!
          : email.isNotEmpty
          ? email.split('@').first
          : 'GACHI 학생',
      email: email,
      authProvider: 'supabase',
      role: AppUserRole.fromClaim(user.appMetadata['gachi_role']),
      requestedRole: switch (user.userMetadata?['requested_account_type']
          ?.toString()) {
        'parent' => AppUserRole.parent,
        'consultant' => AppUserRole.consultant,
        'admin' => AppUserRole.admin,
        _ => AppUserRole.student,
      },
    );
  }
}

class EmailConfirmationRequired implements Exception {
  const EmailConfirmationRequired();
}

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
  static const _pendingRoleKey = 'gachi.auth.pending_role';

  bool loading = true;
  SessionUser? user;
  StreamSubscription<AuthState>? supabaseAuthSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSupabaseAuth();
    _restoreSession();
  }

  void _listenToSupabaseAuth() {
    if (!SupabaseAuthService.isEnabled) return;
    supabaseAuthSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) async {
          final signedInUser = state.session?.user;
          if (signedInUser != null) {
            var sessionUser = SupabaseAuthService.fromUser(signedInUser);
            try {
              final preferences = await SharedPreferences.getInstance();
              final roleName = preferences.getString(_pendingRoleKey);
              await preferences.remove(_pendingRoleKey);
              if (roleName != null) {
                final selected = AppUserRole.values
                    .where((role) => role.name == roleName)
                    .firstOrNull;
                if (selected != null) {
                  sessionUser = (await SupabaseAuthService.selectAccountRole(selected)).user;
                }
              }
            } catch (_) {
              // OAuth 콜백에서 역할 동기화가 늦어져도 현재 계정 세션은 유지한다.
            }
            await _authenticate(
              sessionUser,
              persist: false,
            );
          } else if (state.event == AuthChangeEvent.signedOut && mounted) {
            setState(() => user = null);
          }
        });
  }

  @override
  void dispose() {
    supabaseAuthSubscription?.cancel();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    SessionUser? restoredUser;
    try {
      restoredUser = await SupabaseAuthService.restoreUser();
      if (restoredUser != null) {
        if (!mounted) return;
        setState(() {
          user = restoredUser;
          loading = false;
        });
        return;
      }
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
    if (user?.authProvider == 'supabase') await SupabaseAuthService.logout();
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
  bool createAccount = false;
  bool submitting = false;
  bool obscurePassword = true;
  AppUserRole selectedRole = AppUserRole.student;
  String? errorMessage;
  String? confirmationMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      submitting = true;
      errorMessage = null;
      confirmationMessage = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_AuthGateState._pendingRoleKey, selectedRole.name);
      await SupabaseAuthService.signInWithGoogle();
    } on AuthException catch (error) {
      if (mounted) setState(() => errorMessage = _authErrorMessage(error));
    } on EmailAuthException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => errorMessage = 'Google 로그인 화면을 열지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
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
      confirmationMessage = null;
    });
    try {
      var user = SupabaseAuthService.isEnabled
          ? await SupabaseAuthService.authenticate(
              createAccount: createAccount,
              email: email,
              password: password,
              name: name,
              requestedRole: selectedRole,
            )
          : await EmailAuthService.authenticate(
              createAccount: createAccount,
              email: email,
              password: password,
              name: name,
            );
      if (SupabaseAuthService.isEnabled) {
        final roleResult = await SupabaseAuthService.selectAccountRole(selectedRole);
        user = roleResult.user;
        if (roleResult.needsConsultantVerification && mounted) {
          confirmationMessage = '입시 전문가 활동을 위해 경력 증명서·자격증 등 입증 자료를 제출해 주세요. 관리자 승인 전에는 전문가 권한이 부여되지 않습니다.';
        }
      }
      await widget.onAuthenticated(user, persist: true);
    } on EmailConfirmationRequired {
      if (mounted) {
        setState(() {
          createAccount = false;
          confirmationMessage = '인증 메일을 보냈어요. 메일의 확인 버튼을 누르면 이 화면으로 돌아와 자동 로그인됩니다. 메일을 확인한 뒤에는 이메일과 비밀번호로 로그인해 주세요.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => errorMessage = _authErrorMessage(error));
    } on AccountRoleException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } on EmailAuthException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = SupabaseAuthService.isEnabled
              ? 'Supabase Auth에 연결할 수 없습니다. 프로젝트 설정과 네트워크를 확인해 주세요.'
              : '로그인 서버에 연결할 수 없습니다. API 서버 실행 상태를 확인해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  String _authErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '이메일 또는 비밀번호가 맞지 않습니다. 비밀번호를 잊었다면 재설정 메일을 받아보세요.';
    }
    if (message.contains('email not confirmed')) {
      return '이메일 인증이 아직 완료되지 않았습니다. 받은편지함에서 인증 메일을 확인해 주세요.';
    }
    if (message.contains('email rate limit exceeded')) {
      return '요청이 잠시 제한되었습니다. 잠시 후 다시 시도해 주세요.';
    }
    return '로그인에 실패했습니다. ${error.message}';
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => errorMessage = '비밀번호 재설정 메일을 받을 이메일을 입력해 주세요.');
      return;
    }
    setState(() {
      submitting = true;
      errorMessage = null;
      confirmationMessage = null;
    });
    try {
      await SupabaseAuthService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          confirmationMessage = '비밀번호 재설정 메일을 보냈어요. 메일의 링크에서 새 비밀번호를 설정해 주세요.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => errorMessage = _authErrorMessage(error));
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = '재설정 메일을 보내지 못했습니다. 잠시 후 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _showFindEmailIdGuide() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('아이디 찾기'),
      content: const Text(
        'GACHI에서는 가입할 때 입력한 이메일 주소가 아이디입니다.\n\n'
        '개인정보 보호를 위해 앱에서 가입 이메일을 직접 조회하거나 표시하지 않습니다. '
        '가입 이메일을 기억하셨다면 입력란에 적은 뒤 비밀번호 찾기를 이용해 계정을 확인할 수 있어요.',
        style: TextStyle(height: 1.55),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );

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
                const SizedBox(height: 38),
                const Text(
                  '같이 + 가치',
                  style: TextStyle(
                    color: lime,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '같이 배우고,\n가치를 키우다',
                  style: TextStyle(
                    color: text,
                    fontSize: 32,
                    height: 1.18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '학생의 배움과 선택이 더 큰 가치로 이어지도록 함께합니다.',
                  style: TextStyle(color: mute, fontSize: 12, height: 1.55),
                ),
                if (SupabaseAuthService.isEnabled) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '이메일 계정은 Supabase Auth로 안전하게 관리됩니다.',
                    style: TextStyle(color: mute, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 24),
                buildGoogleLoginButton(onPressed: _signInWithGoogle),
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
                          confirmationMessage = null;
                        }),
                ),
                const SizedBox(height: 16),
                _RoleSelector(
                  title: createAccount ? '가입 유형을 선택해 주세요' : '로그인할 역할을 선택해 주세요',
                  roles: createAccount
                      ? const [
                          AppUserRole.student,
                          AppUserRole.parent,
                          AppUserRole.consultant,
                        ]
                      : AppUserRole.values,
                  selected: selectedRole,
                  onSelected: submitting
                      ? null
                      : (role) => setState(() {
                          selectedRole = role;
                          errorMessage = null;
                        }),
                ),
                if (selectedRole == AppUserRole.consultant) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '학원 관계자·강사·컨설턴트를 포함합니다. 가입 후 경력 증명서·자격증·입증 자료를 제출하면 관리자 검토를 거쳐 전문가 권한이 활성화됩니다.',
                    style: TextStyle(color: mute, fontSize: 10, height: 1.5),
                  ),
                ],
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
                if (!createAccount)
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          key: const Key('find-email-id-button'),
                          onPressed: submitting ? null : _showFindEmailIdGuide,
                          child: const Text('아이디 찾기'),
                        ),
                        const Text('·', style: TextStyle(color: mute)),
                        TextButton(
                          key: const Key('reset-password-button'),
                          onPressed: submitting ? null : _resetPassword,
                          child: const Text('비밀번호 찾기'),
                        ),
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
                if (confirmationMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffEAF7F0),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      confirmationMessage!,
                      style: const TextStyle(
                        color: Color(0xff176B47),
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

class _RoleSelector extends StatelessWidget {
  final String title;
  final List<AppUserRole> roles;
  final AppUserRole selected;
  final ValueChanged<AppUserRole>? onSelected;

  const _RoleSelector({
    required this.title,
    required this.roles,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: roles
            .map(
              (role) => ChoiceChip(
                label: Text(role.label),
                selected: selected == role,
                onSelected: onSelected == null ? null : (_) => onSelected!(role),
                showCheckmark: false,
                selectedColor: lavender,
                side: BorderSide(color: selected == role ? lime : const Color(0xffD9DEE8)),
                labelStyle: TextStyle(
                  color: selected == role ? lime : text,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class ConsultantVerificationPage extends StatefulWidget {
  final SessionUser user;
  final VoidCallback onDefer;

  const ConsultantVerificationPage({
    super.key,
    required this.user,
    required this.onDefer,
  });

  @override
  State<ConsultantVerificationPage> createState() =>
      _ConsultantVerificationPageState();
}

class _ConsultantVerificationPageState
    extends State<ConsultantVerificationPage> {
  final careerController = TextEditingController();
  String consultantType = 'admission_consultant';
  List<PlatformFile> files = [];
  bool submitting = false;
  bool completed = false;
  String? error;

  @override
  void dispose() {
    careerController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;
    setState(() {
      files = result.files.take(5).toList();
      error = null;
    });
  }

  String _contentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  String _safeFileName(String name) => name
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
      .replaceAll(RegExp(r'_+'), '_');

  Future<void> _submit() async {
    if (files.isEmpty) {
      setState(() => error = '경력 증명서, 자격증 또는 활동 입증 자료를 1개 이상 첨부해 주세요.');
      return;
    }
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      setState(() => error = '세션을 확인하지 못했습니다. 다시 로그인해 주세요.');
      return;
    }
    if (files.any((file) => file.bytes == null)) {
      setState(() => error = '첨부 파일을 읽지 못했습니다. 다시 선택해 주세요.');
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final paths = <String>[];
      for (final file in files) {
        final path = '${authUser.id}/${DateTime.now().microsecondsSinceEpoch}_${_safeFileName(file.name)}';
        final uploaded = await Supabase.instance.client.storage
            .from('consultant-verification')
            .uploadBinary(
              path,
              file.bytes!,
              fileOptions: FileOptions(
                contentType: _contentType(file.name),
                upsert: false,
              ),
            );
        paths.add(uploaded);
      }
      await Supabase.instance.client
          .from('consultant_verification_submissions')
          .insert({
            'user_id': authUser.id,
            'consultant_type': consultantType,
            'career_summary': careerController.text.trim().isEmpty
                ? null
                : careerController.text.trim(),
            'evidence_paths': paths,
          });
      if (mounted) setState(() => completed = true);
    } on StorageException catch (exception) {
      if (mounted) setState(() => error = '파일을 저장하지 못했습니다. ${exception.message}');
    } on PostgrestException catch (exception) {
      if (mounted) setState(() => error = '검증 신청을 저장하지 못했습니다. ${exception.message}');
    } catch (_) {
      if (mounted) setState(() => error = '제출 중 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  String get _typeLabel => switch (consultantType) {
    'academy_staff' => '학원 관계자',
    'instructor' => '강사',
    _ => '입시 전문가',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: widget.onDefer,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('입시 전문가 등록'),
      centerTitle: true,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
        children: [
          const Text(
            '입증 자료를 제출해 주세요.',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            '입시 전문가(학원 관계자·강사·컨설턴트)는 경력 증명서, 자격증 또는 활동 입증 자료를 제출하면 관리자 검토 후 활동 권한이 활성화됩니다.',
            style: TextStyle(color: mute, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, color: lime),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '제출 자료는 공개되지 않습니다. 본인과 관리자만 열람할 수 있으며, 검토 목적 외에는 사용하지 않습니다.',
                    style: TextStyle(color: Color(0xff35517D), fontSize: 11, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('등록 유형', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: consultantType,
            items: const [
              DropdownMenuItem(value: 'admission_consultant', child: Text('입시 컨설턴트')),
              DropdownMenuItem(value: 'academy_staff', child: Text('학원 관계자')),
              DropdownMenuItem(value: 'instructor', child: Text('강사')),
            ],
            onChanged: completed ? null : (value) => setState(() => consultantType = value!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text('경력·전문 분야 소개 (선택)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: careerController,
            enabled: !completed,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: '예: 학생부 종합전형 컨설팅 5년, 고3 수시 지원 전략 전문',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          const Text('입증 자료', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('PDF, JPG, PNG, WEBP · 최대 5개 · 파일당 10MB', style: TextStyle(color: mute, fontSize: 11)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: completed || submitting ? null : _pickFiles,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('경력 증명서·자격증·입증 자료 첨부'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...files.map((file) => Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.description_outlined, color: lime, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(file.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                Text('${(file.size / 1024 / 1024).toStringAsFixed(1)}MB', style: const TextStyle(color: mute, fontSize: 10)),
              ]),
            )),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Color(0xffA53C24), fontSize: 11, height: 1.5)),
          ],
          if (completed) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xffEAF7F0), borderRadius: BorderRadius.circular(14)),
              child: Text('$_typeLabel 등록 자료를 제출했어요. 관리자 검토가 완료되면 입시 전문가 화면이 활성화됩니다.', style: const TextStyle(color: Color(0xff176B47), fontSize: 12, height: 1.5)),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: completed || submitting ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: Text(submitting ? '제출 중...' : completed ? '검토 대기 중' : '검토 신청하기'),
          ),
          TextButton(onPressed: completed ? widget.onDefer : (submitting ? null : widget.onDefer), child: const Text('나중에 제출할게요')),
        ],
      ),
    ),
  );
}
