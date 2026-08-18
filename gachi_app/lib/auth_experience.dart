part of 'main.dart';

class SessionUser {
  final String name;
  final String email;
  final bool isGuest;

  const SessionUser({
    required this.name,
    required this.email,
    this.isGuest = false,
  });
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
      } catch (_) {
        // 세션 저장이 실패해도 현재 실행에서는 로그인 상태를 유지한다.
      }
    }
    if (!mounted) return;
    setState(() => user = nextUser);
  }

  Future<void> _logout() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      await preferences.remove(_signedInKey);
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
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool createAccount = false;
  bool obscurePassword = true;
  bool submitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    final email = emailController.text.trim();
    final fallbackName = email.split('@').first;
    await widget.onAuthenticated(
      SessionUser(
        name: createAccount && nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : fallbackName,
        email: email,
      ),
      persist: true,
    );
    if (mounted) setState(() => submitting = false);
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
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Logo(),
                  const SizedBox(height: 40),
                  Text(
                    createAccount ? '학습 여정을\n시작해 볼까요?' : '다시 만나서\n반가워요.',
                    style: const TextStyle(
                      color: text,
                      fontSize: 31,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    createAccount
                        ? '계정을 만들고 진단 결과와 목표 플랜을 이어서 관리하세요.'
                        : '로그인하면 저장한 학생 정보와 분석 기록을 이어볼 수 있어요.',
                    style: const TextStyle(color: mute, fontSize: 12),
                  ),
                  const SizedBox(height: 26),
                  if (createAccount) ...[
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '학생 이름',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? '이름을 2자 이상 입력해 주세요.'
                          : null,
                    ),
                    const SizedBox(height: 13),
                  ],
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@') && email.contains('.')
                          ? null
                          : '올바른 이메일을 입력해 주세요.';
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) < 6
                        ? '비밀번호를 6자 이상 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: Text(
                      submitting
                          ? '확인 중...'
                          : createAccount
                          ? '무료 계정 만들기'
                          : '로그인',
                    ),
                  ),
                  const SizedBox(height: 9),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => createAccount = !createAccount),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lime,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(createAccount ? '이미 계정이 있어요' : '처음이에요 · 회원가입'),
                  ),
                  const SizedBox(height: 9),
                  TextButton(
                    onPressed: () => widget.onAuthenticated(
                      const SessionUser(
                        name: '체험 학생',
                        email: 'guest@gachi.local',
                        isGuest: true,
                      ),
                      persist: false,
                    ),
                    child: const Text('로그인 없이 둘러보기'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MVP 테스트용 로컬 로그인입니다. 비밀번호는 기기에 저장하지 않으며, 운영 전에는 서버 인증 연결이 필요합니다.',
                    style: TextStyle(color: mute, fontSize: 10, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
