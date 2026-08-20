import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'google_login_button.dart';
import 'insight_data.dart';
import 'admission_strategy_data.dart';
import 'level_test_data.dart';
import 'study_plan_models.dart';

part 'home_experience.dart';
part 'auth_experience.dart';
part 'commerce_experience.dart';
part 'admission_strategy_experience.dart';
part 'explore_experience.dart';
part 'level_test_experience.dart';
part 'local_value_experience.dart';
part 'admin_experience.dart';
part 'role_experience.dart';

const navy = Color(0xff101114),
    surface = Color(0xffFFFFFF),
    lime = Color(0xff0B63F6),
    lavender = Color(0xffEAF1FF),
    mist = Color(0xffF6F8FC),
    text = Color(0xff14161B),
    mute = Color(0xff778091),
    coral = Color(0xffFF5A1F);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();
  await SupabaseAuthService.initialize();
  runApp(const GachiApp());
}

class GachiApp extends StatelessWidget {
  final bool showIntro;

  const GachiApp({super.key, this.showIntro = true});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Paperlogy',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.12,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.4,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.1,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: -.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.55),
        bodyMedium: TextStyle(fontSize: 13, height: 1.55),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ).apply(bodyColor: text, displayColor: text),
      scaffoldBackgroundColor: mist,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        brightness: Brightness.light,
      ),
    ),
    home: showIntro ? const IntroPage() : const AuthGate(),
  );
}

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  Timer? _dismissTimer;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(milliseconds: 900), _leave);
  }

  void _leave() {
    if (!mounted || _isLeaving) return;
    setState(() => _isLeaving = true);
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff101C36),
    body: AnimatedOpacity(
      opacity: _isLeaving ? 0 : 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: const GachiBrandLogo(
                  width: 230,
                  color: Color(0xffEAF8FF),
                ),
              ),
              const Spacer(flex: 3),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'AI 진학 코치부터 맞춤 학원 찾기까지',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffC9D8F8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class GachiBrandLogo extends StatelessWidget {
  final double width;
  final Color? color;

  const GachiBrandLogo({super.key, required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/branding/gachi_wordmark.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    return Semantics(
      label: 'GACHI, 같이 배우고 가치를 키우다',
      image: true,
      child: color == null
          ? logo
          : ColorFiltered(
              colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
              child: logo,
            ),
    );
  }
}

class Shell extends StatefulWidget {
  final SessionUser? user;
  final VoidCallback? onLogout;

  const Shell({super.key, this.user, this.onLogout});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  bool showConsultantVerification = true;

  Widget get _roleHome {
    if (widget.user?.needsConsultantVerification == true &&
        showConsultantVerification) {
      return ConsultantVerificationPage(
        user: widget.user!,
        onDefer: () => setState(() => showConsultantVerification = false),
      );
    }
    return switch (widget.user?.role ?? AppUserRole.student) {
    AppUserRole.parent => ParentHome(user: widget.user),
    AppUserRole.consultant => ConsultantHome(user: widget.user),
    AppUserRole.admin => const AdminDashboardPage(),
    AppUserRole.student => Home(
      user: widget.user,
      onRequireLogin: widget.onLogout,
      onOpenHome: () => setState(() => index = 0),
      onOpenProfile: () => setState(() => index = 4),
    ),
    };
  }

  List<Widget> get pages => [
    _roleHome,
    Explore(
      user: widget.user,
      onRequireLogin: widget.onLogout,
      onOpenHome: () => setState(() => index = 0),
      onOpenCoach: () => setState(() => index = 3),
    ),
    Community(user: widget.user, onRequireLogin: widget.onLogout),
    Coach(
      user: widget.user,
      onRequireLogin: widget.onLogout,
      onOpenHome: () => setState(() => index = 0),
    ),
    Profile(
      user: widget.user,
      onLogout: widget.onLogout,
      onOpenHome: () => setState(() => index = 0),
    ),
  ];
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(child: pages[index]),
    floatingActionButton: Semantics(
      button: true,
      label: 'GACHI AI 코치 열기',
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: const Color(0xff2162DD),
          elevation: 8,
          shadowColor: const Color(0x550A327B),
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: () => Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => const ChatAssistantPage()),
            ),
            borderRadius: BorderRadius.circular(17),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 27,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xffFFFEFF),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xffDCE4F1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A243451),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _BottomNavButton(
              icon: Icons.home_outlined,
              label: '홈',
              selected: index == 0,
              onTap: () => setState(() => index = 0),
            ),
            _BottomNavButton(
              icon: Icons.explore_outlined,
              label: '탐색',
              selected: index == 1,
              onTap: () => setState(() => index = 1),
            ),
            _BottomNavButton(
              icon: Icons.forum_outlined,
              label: '커뮤니티',
              selected: index == 2,
              onTap: () => setState(() => index = 2),
            ),
            _BottomNavButton(
              icon: Icons.auto_awesome_outlined,
              label: '코치',
              selected: index == 3,
              onTap: () => setState(() => index = 3),
            ),
            _BottomNavButton(
              icon: Icons.person_outline,
              label: 'MY',
              selected: index == 4,
              onTap: () => setState(() => index = 4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BottomNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? lime : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x331463ED),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : const Color(0xff7B879D),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? lime : const Color(0xff7B879D),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LegacyHome extends StatelessWidget {
  const LegacyHome({super.key});
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
    children: [
      const _Top(),
      const SizedBox(height: 26),
      const Text(
        'Good evening, 지희',
        style: TextStyle(
          color: text,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        '오늘도 목표에 가까워지고 있어요.',
        style: TextStyle(color: mute, fontSize: 13),
      ),
      const SizedBox(height: 22),
      const _HeroCard(),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: _Metric('GACHI SCORE', '78', '+4 this week', lime)),
          const SizedBox(width: 12),
          Expanded(child: _Metric('NEXT GOAL', 'D-103', '2027 수시', lavender)),
        ],
      ),
      const SizedBox(height: 28),
      const _Section('Today’s focus'),
      const SizedBox(height: 10),
      const _FocusCard(),
      const SizedBox(height: 26),
      const _Section('Discover for you'),
      const SizedBox(height: 10),
      const _DiscoverRow(),
    ],
  );
}

class _Top extends StatelessWidget {
  final String initial;
  final VoidCallback? onHome;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool hasUnreadNotifications;

  const _Top({
    this.initial = '지',
    this.onHome,
    this.onNotifications,
    this.onProfile,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext c) => Row(
    children: [
      Expanded(child: _Logo(responsive: true, onTap: onHome)),
      Stack(
        clipBehavior: Clip.none,
        children: [
          _IconButton(
            Icons.notifications_none_rounded,
            key: const Key('header-notifications-button'),
            tooltip: '알림',
            onTap: onNotifications,
          ),
          if (hasUnreadNotifications)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(width: 8),
      Semantics(
        button: true,
        label: '마이페이지 열기',
        child: Material(
          color: lavender,
          shape: const CircleBorder(),
          child: InkWell(
            key: const Key('header-profile-button'),
            customBorder: const CircleBorder(),
            onTap: onProfile,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Logo extends StatelessWidget {
  final bool responsive;
  final VoidCallback? onTap;

  const _Logo({this.responsive = false, this.onTap});

  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (context, constraints) {
      const preferredWidth = 285.0;
      final logoWidth = responsive
          ? (constraints.maxWidth < preferredWidth
                ? constraints.maxWidth
                : preferredWidth)
          : preferredWidth;
      final logoHeight = logoWidth / 6;

      return Semantics(
        label: 'GACHI',
        button: onTap != null,
        image: true,
        // 원본 PNG의 투명 여백을 상쇄해 실제 워드마크 기준으로 20px을 맞춘다.
        child: GestureDetector(
          key: const Key('gachi-home-logo'),
          onTap: onTap,
          child: Transform.translate(
            offset: Offset(-logoWidth * 0.125, 0),
            child: SizedBox(
              width: logoWidth,
              height: logoHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/branding/gachi_horizontal_logo.png',
                    width: logoWidth,
                    height: logoHeight,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  Positioned(
                    // 원본 가로형 로고의 구분선·태그라인 잔여 픽셀을 완전히 숨긴다.
                    left: logoWidth * 0.5,
                    top: 0,
                    right: -80,
                    bottom: 0,
                    child: const ColoredBox(color: mist),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconButton(this.icon, {super.key, this.tooltip = '', this.onTap});

  @override
  Widget build(BuildContext c) => Semantics(
    button: true,
    label: tooltip,
    child: Material(
      color: surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: text, size: 20),
        ),
      ),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override
  Widget build(BuildContext c) => Container(
    height: 230,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff0B63F6), Color(0xff4A96FF)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'YOUR LEARNING OS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            Spacer(),
            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ],
        ),
        const Spacer(),
        const Text(
          '다음 선택을\n더 선명하게.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            height: 1.07,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const LevelTest()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: lime,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('무료 레벨 테스트'),
            ),
            const SizedBox(width: 10),
            const Text(
              '15 min',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  final String label, value, sub;
  final Color accent;
  const _Metric(this.label, this.value, this.sub, this.accent);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: mute,
            fontWeight: FontWeight.w600,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(sub, style: const TextStyle(fontSize: 10, color: mute)),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext c) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(),
      const Text(
        'View all',
        style: TextStyle(
          color: lime,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _FocusCard extends StatelessWidget {
  const _FocusCard();
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xff293850),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.functions, color: lime),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '수학 · 기하 응용',
                style: TextStyle(color: text, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                '목표 LEVEL 8까지 2단계 남았어요',
                style: TextStyle(color: mute, fontSize: 11),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: lime),
      ],
    ),
  );
}

class _DiscoverRow extends StatelessWidget {
  const _DiscoverRow();
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 154,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: const [
        _Discover(
          'GACHI HIGH',
          '고교 환경\n적합도 확인',
          lavender,
          Icons.account_tree_outlined,
        ),
        SizedBox(width: 12),
        _Discover('ADMISSION', '대입 전략\n심층 분석', coral, Icons.insights_outlined),
        SizedBox(width: 12),
        _Discover(
          'NEARBY',
          '내 주변\n교육기관',
          Color(0xff75C9FF),
          Icons.location_on_outlined,
        ),
      ],
    ),
  );
}

class _Discover extends StatelessWidget {
  final String tag, title;
  final Color color;
  final IconData icon;
  const _Discover(this.tag, this.title, this.color, this.icon);
  @override
  Widget build(BuildContext c) => Container(
    width: 170,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const Spacer(),
        Text(
          tag,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: text,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    ),
  );
}

class LegacyStudentHome extends StatefulWidget {
  const LegacyStudentHome({super.key});
  @override
  State<LegacyStudentHome> createState() => _LegacyStudentHomeState();
}

class _LegacyStudentHomeState extends State<LegacyStudentHome> {
  AcademyStudentProfile? academyProfile;
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
    children: [
      const _Top(),
      const SizedBox(height: 24),
      Row(
        children: [
          Text(
            academyProfile == null
                ? '나의 진학 준비'
                : '${academyProfile!.school} · ${academyProfile!.grade}',
            style: const TextStyle(
              color: text,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push<AcademyMatchFormResult>(
                c,
                MaterialPageRoute(
                  builder: (_) => AcademyMatchForm(initial: academyProfile),
                ),
              );
              if (result != null) {
                setState(
                  () => academyProfile = result.reset ? null : result.profile,
                );
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: Text(academyProfile == null ? '학생 정보 입력' : '정보 수정'),
            style: TextButton.styleFrom(
              foregroundColor: lime,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      Text(
        academyProfile == null
            ? '학생 정보를 등록하면 입시 전략과 맞춤 학원 추천을 시작할 수 있어요.'
            : '${academyProfile!.region} · ${academyProfile!.subjects.join(' · ')} 기준으로 입시 전략을 준비하고 있어요.',
        style: const TextStyle(color: mute, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 14),
      _StudentProfileCard(
        profile: academyProfile,
        onEdit: () async {
          final result = await Navigator.push<AcademyMatchFormResult>(
            c,
            MaterialPageRoute(
              builder: (_) => AcademyMatchForm(initial: academyProfile),
            ),
          );
          if (result != null) {
            setState(
              () => academyProfile = result.reset ? null : result.profile,
            );
          }
        },
      ),
      const SizedBox(height: 15),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _Quick(
              Icons.auto_awesome_outlined,
              '무료 진단',
              () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const LevelTest()),
              ),
            ),
            _Quick(
              Icons.insights_outlined,
              '입시 분석',
              () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const AdmissionForm()),
              ),
            ),
            _Quick(
              Icons.add,
              '목표 추가',
              () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const HighReport()),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 23),
      Row(
        children: [
          const Text(
            '이번 주 코치 플랜',
            style: TextStyle(
              color: text,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '전체 보기',
            style: TextStyle(
              color: lime,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _Plan('수학 기하 응용', '목표 LEVEL 8까지 2단계', .62, lavender),
      _Plan('학생부 탐구 정리', '알고리즘 발표 기록 보완', .38, coral),
      const SizedBox(height: 18),
      const Text(
        '새로운 인사이트',
        style: TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffE6E9EF)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMISSION NOTE',
              style: TextStyle(
                color: coral,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 7),
            Text(
              '2027 수시, 지금 확인해야 할 변화',
              style: TextStyle(
                color: text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '학생부 반영 방법과 수능최저를 미리 비교해보세요.',
              style: TextStyle(color: mute, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class AcademyStudentProfile {
  final String name;
  final String region;
  final String school;
  final String grade;
  final List<String> subjects;
  final String level;
  final String academyCondition;
  const AcademyStudentProfile({
    required this.name,
    required this.region,
    required this.school,
    required this.grade,
    required this.subjects,
    required this.level,
    required this.academyCondition,
  });

  Map<String, Object> toJson() => {
    'name': name,
    'region': region,
    'school': school,
    'grade': grade,
    'subjects': subjects,
    'level': level,
    'academyCondition': academyCondition,
  };

  factory AcademyStudentProfile.fromJson(Map<String, dynamic> json) =>
      AcademyStudentProfile(
        name: json['name'] as String,
        region: json['region'] as String,
        school: json['school'] as String,
        grade: json['grade'] as String,
        subjects: (json['subjects'] as List).cast<String>(),
        level: json['level'] as String,
        academyCondition: json['academyCondition'] as String,
      );
}

class AcademyMatchFormResult {
  final AcademyStudentProfile? profile;
  final bool reset;

  const AcademyMatchFormResult.saved(this.profile) : reset = false;
  const AcademyMatchFormResult.reset() : profile = null, reset = true;
}

class _StudentProfileCard extends StatelessWidget {
  final AcademyStudentProfile? profile;
  final VoidCallback onEdit;
  final bool embedded;

  const _StudentProfileCard({
    required this.profile,
    required this.onEdit,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext c) {
    final p = profile;
    final title = p == null ? '학생 정보 등록' : '${p.name} · ${p.grade}';
    final body = p == null
        ? '학교와 관심 과목을 입력해 맞춤 추천을 시작하세요.'
        : '${p.school} · ${p.region} · ${p.subjects.join('·')}';
    final radius = BorderRadius.circular(18);
    return Material(
      color: embedded ? Colors.transparent : surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: embedded
            ? BorderSide.none
            : const BorderSide(color: Color(0xffE2E6EE)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: embedded ? 18 : 14,
            vertical: embedded ? 16 : 13,
          ),
          child: Row(
            children: [
              Container(
                width: embedded ? 48 : 38,
                height: embedded ? 48 : 38,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  p == null
                      ? Icons.person_add_alt_1_outlined
                      : Icons.person_outline_rounded,
                  color: lime,
                  size: embedded ? 25 : 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: text,
                        fontSize: embedded ? 16 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: embedded ? 12 : 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p == null ? '등록' : '수정',
                style: TextStyle(
                  color: lime,
                  fontSize: embedded ? 12 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: mute,
                size: embedded ? 22 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AcademyMatchForm extends StatefulWidget {
  final AcademyStudentProfile? initial;
  const AcademyMatchForm({super.key, this.initial});
  @override
  State<AcademyMatchForm> createState() => _AcademyMatchFormState();
}

class _AcademyMatchFormState extends State<AcademyMatchForm> {
  static const _profileKey = 'gachi.student.profile';
  late final TextEditingController name;
  late final TextEditingController school;
  late final TextEditingController academyCondition;
  String region = '서울 강남구';
  String grade = '고2';
  String level = '개념은 안정적, 심화 보완 필요';
  late Set<String> subjects;
  bool hasRegisteredProfile = false;
  final regions = const [
    '서울 강남구',
    '서울 서초구',
    '서울 송파구',
    '서울 양천구',
    '서울 노원구',
    '서울 마포구',
    '서울 성북구',
    '서울 동작구',
    '기타 지역',
  ];
  final grades = const ['중1', '중2', '중3', '고1', '고2', '고3'];
  final levels = const ['기초부터 다시', '개념은 안정적, 심화 보완 필요', '상위권 심화·실전 중심'];
  final subjectOptions = const ['수학', '영어', '국어', '과학', '학생부·입시'];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    name = TextEditingController(text: p?.name ?? '');
    school = TextEditingController(text: p?.school ?? '');
    academyCondition = TextEditingController(text: p?.academyCondition ?? '');
    region = p?.region ?? region;
    grade = p?.grade ?? grade;
    level = p?.level ?? level;
    subjects = {
      ...(p?.subjects ?? ['수학', '학생부·입시']),
    };
    hasRegisteredProfile = p != null;
    if (p == null) _restoreSavedProfile();
  }

  /// 홈에서 전달된 프로필이 없더라도, 이미 등록된 학생 정보가 있으면
  /// 수정·초기화 화면으로 일관되게 동작하게 합니다.
  Future<void> _restoreSavedProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProfile = preferences.getString(_profileKey);
    if (rawProfile == null) return;
    try {
      final profile = AcademyStudentProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawProfile) as Map),
      );
      if (!mounted) return;
      setState(() {
        name.text = profile.name;
        school.text = profile.school;
        academyCondition.text = profile.academyCondition;
        region = profile.region;
        grade = profile.grade;
        level = profile.level;
        subjects = {...profile.subjects};
        hasRegisteredProfile = true;
      });
    } catch (_) {
      // 손상된 로컬 저장값은 새 학생 정보 입력 화면으로 유지합니다.
    }
  }

  @override
  void dispose() {
    name.dispose();
    school.dispose();
    academyCondition.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (name.text.trim().isEmpty ||
        school.text.trim().isEmpty ||
        subjects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름, 학교, 관심 과목을 입력해 주세요.')));
      return;
    }
    final profile = AcademyStudentProfile(
      name: name.text.trim(),
      region: region,
      school: school.text.trim(),
      grade: grade,
      subjects: subjects.toList(),
      level: level,
      academyCondition: academyCondition.text.trim(),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(profile.toJson()));
    List<Map<String, dynamic>> matches = [];
    try {
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/academy-recommendations'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'region': profile.region,
              'grade': profile.grade,
              'subjects': profile.subjects,
              'level': profile.level,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        matches = (jsonDecode(response.body)['items'] as List)
            .cast<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    if (!mounted) return;
    final saved = await Navigator.push<AcademyStudentProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => AcademyMatchResult(profile: profile, matches: matches),
      ),
    );
    if (saved != null && mounted) {
      Navigator.pop(context, AcademyMatchFormResult.saved(saved));
    }
  }

  Future<void> _resetProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('학생 정보를 초기화할까요?'),
        content: const Text(
          '이름, 지역, 학교, 학년, 관심 과목과 학원 조건이 모두 삭제됩니다.\n추천 기준도 새로 설정해야 해요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff2D3D62),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_profileKey);
    if (mounted) Navigator.pop(context, const AcademyMatchFormResult.reset());
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      title: const Text(
        '맞춤 학원 찾기',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        TextButton.icon(
          onPressed: _resetProfile,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('초기화'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xff4D5C78),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text(
          '학생 정보를 알려주세요.',
          style: TextStyle(
            color: text,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '통학권과 학습 상황에 맞는 추천 기준을 만들어요.',
          style: TextStyle(color: mute, fontSize: 12),
        ),
        const SizedBox(height: 22),
        const _FormLabel('이름'),
        TextField(
          controller: name,
          decoration: _inputDecoration(hint: '예: 이지희'),
        ),
        const SizedBox(height: 17),
        const _FormLabel('지역'),
        DropdownButtonFormField<String>(
          initialValue: region,
          decoration: _inputDecoration(),
          items: regions
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => region = value!),
        ),
        const SizedBox(height: 17),
        const _FormLabel('학교'),
        TextField(
          controller: school,
          decoration: _inputDecoration(hint: '예: ○○고등학교'),
        ),
        const SizedBox(height: 17),
        const _FormLabel('학년'),
        DropdownButtonFormField<String>(
          initialValue: grade,
          decoration: _inputDecoration(),
          items: grades
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => grade = value!),
        ),
        const SizedBox(height: 17),
        const _FormLabel('관심 과목 · 필요한 영역'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: subjectOptions
              .map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: subjects.contains(item),
                  selectedColor: lavender,
                  checkmarkColor: lime,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: subjects.contains(item) ? lime : text,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) => setState(
                    () => selected ? subjects.add(item) : subjects.remove(item),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 17),
        const _FormLabel('현재 학습 수준'),
        RadioGroup<String>(
          groupValue: level,
          onChanged: (value) => setState(() => level = value!),
          child: Column(
            children: levels
                .map(
                  (item) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: item,
                    activeColor: lime,
                    title: Text(
                      item,
                      style: const TextStyle(fontSize: 12, color: text),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        const _FormLabel('찾는 학원 조건'),
        TextField(
          controller: academyCondition,
          maxLines: 2,
          decoration: _inputDecoration(hint: '예: 소수정예, 주말 수업, 내신 대비'),
        ),
        const SizedBox(height: 15),
        FilledButton(
          onPressed: next,
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: navy,
            minimumSize: const Size.fromHeight(56),
          ),
          child: const Text(
            '맞춤 학원 추천 보기',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel(this.label);
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(color: text, fontWeight: FontWeight.w600),
    ),
  );
}

InputDecoration _inputDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: mute, fontSize: 12),
  filled: true,
  fillColor: surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xffE2E6EE)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xffE2E6EE)),
  ),
);

class AcademyMatchResult extends StatelessWidget {
  final AcademyStudentProfile profile;
  final List<Map<String, dynamic>> matches;
  const AcademyMatchResult({
    super.key,
    required this.profile,
    this.matches = const [],
  });
  @override
  Widget build(BuildContext c) {
    final subject = profile.subjects.first;
    final options = matches.isEmpty
        ? [
            (
              '통학 중심 $subject 전문반',
              '${profile.region} 기준 30분 이내 통학권 · ${profile.grade} ${profile.level}',
              '주 2~3회 · 레벨 진단 후 반 배정',
              '${profile.region} $subject 학원',
            ),
            (
              '$subject 심화·내신 관리반',
              '${profile.school} 재학생의 내신 일정에 맞춘 소수정예 수업',
              '학교별 시험범위·오답 관리 확인',
              '${profile.region} $subject 내신 학원',
            ),
            (
              '진학 전략 통합 컨설팅',
              '학생부·모의고사·희망 전공을 함께 보는 입시 관리',
              '상담 교사의 입시 데이터 출처 확인',
              '${profile.region} 입시 컨설팅',
            ),
          ]
        : matches
              .take(3)
              .map(
                (item) => (
                  item['name'] as String,
                  '${item['region']} · ${item['address']}',
                  '공식 교육청 공개정보 · 적합도 ${item['score']}점',
                  '${item['name']} ${item['address']}',
                ),
              )
              .toList();
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        title: const Text(
          '맞춤 학원 추천',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            '${profile.school} 학생을 위한\n추천 기준',
            style: const TextStyle(
              color: text,
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [profile.region, profile.grade, ...profile.subjects]
                .map(
                  (item) => Chip(
                    label: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: lavender,
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 17),
          KakaoMapPanel(
            query: '${profile.region} $subject 학원',
            placeCount: options.length,
          ),
          const SizedBox(height: 17),
          ...options.asMap().entries.map(
            (entry) => _AcademyOption(
              rank: entry.key + 1,
              title: entry.value.$1,
              body: entry.value.$2,
              check: entry.value.$3,
              mapQuery: entry.value.$4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xffFFF0EA),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              matches.isEmpty
                  ? '서버 연결 전 임시 추천입니다. 분석 서버 실행 후 서울교육청 공개 데이터를 기준으로 다시 조회하세요.'
                  : '서울교육청 공개 학원·교습소 정보를 기준으로 한 결과입니다. 실제 수강료·시간표·모집 상태는 상담 전 재확인하세요.',
              style: const TextStyle(
                color: Color(0xffA84A2F),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => Navigator.pop(c, profile),
            style: OutlinedButton.styleFrom(
              foregroundColor: lime,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: lime),
            ),
            child: const Text(
              '학생 정보 저장하고 홈으로',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyOption extends StatelessWidget {
  final int rank;
  final String title, body, check, mapQuery;
  const _AcademyOption({
    required this.rank,
    required this.title,
    required this.body,
    required this.check,
    required this.mapQuery,
  });
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE2E6EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MATCH $rank',
          style: const TextStyle(
            color: lime,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          style: const TextStyle(color: mute, fontSize: 11, height: 1.45),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: lime, size: 15),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                check,
                style: const TextStyle(
                  color: text,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => openKakaoMapSearch(c, mapQuery),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff3B3526),
            side: const BorderSide(color: Color(0xffE6D98A)),
            minimumSize: const Size.fromHeight(42),
          ),
          icon: const Icon(Icons.location_on_outlined, size: 17),
          label: const Text('카카오맵에서 위치 보기'),
        ),
      ],
    ),
  );
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback tap;
  final bool dark;

  const _Quick(this.icon, this.text, this.tap, {this.dark = true});

  @override
  Widget build(BuildContext c) => Expanded(
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: dark ? Colors.white : lime, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xff14161B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Plan extends StatelessWidget {
  final String title, sub;
  final double value;
  final Color color;
  const _Plan(this.title, this.sub, this.value, this.color);
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffE6E9EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: text, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(color: mute, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(color: mute, fontSize: 11)),
        const SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            color: color,
            backgroundColor: mist,
            minHeight: 5,
          ),
        ),
      ],
    ),
  );
}

class LegacyExplore extends StatelessWidget {
  const LegacyExplore({super.key});
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
    children: [
      const _Logo(),
      const SizedBox(height: 32),
      const Text(
        'What do you\nneed today?',
        style: TextStyle(
          color: text,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.05,
        ),
      ),
      const SizedBox(height: 22),
      _LegacyMenu(
        'GACHI LEVEL',
        '15분 무료 학습 진단',
        Icons.bolt_rounded,
        lime,
        () => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => const LevelTest()),
        ),
      ),
      _LegacyMenu(
        'GACHI ADMISSION',
        '대입 전략과 현재 GAP 분석',
        Icons.north_east_rounded,
        lavender,
        () => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => const AdmissionForm()),
        ),
      ),
      _LegacyMenu(
        'GACHI HIGH',
        '나에게 맞는 고교 환경 찾기',
        Icons.account_tree_outlined,
        coral,
        () => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => const HighReport()),
        ),
      ),
      _LegacyMenu(
        'COACH+',
        '전문가 컨설팅과 로드맵',
        Icons.auto_awesome_rounded,
        Color(0xff75C9FF),
        () => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => const Paywall()),
        ),
      ),
    ],
  );
}

class _LegacyMenu extends StatelessWidget {
  final String a, b;
  final IconData i;
  final Color col;
  final VoidCallback tap;
  const _LegacyMenu(this.a, this.b, this.i, this.col, this.tap);
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: col.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(i, color: col),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a,
                    style: TextStyle(color: text, fontWeight: FontWeight.w600),
                  ),
                  Text(b, style: const TextStyle(color: mute, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: mute, size: 15),
          ],
        ),
      ),
    ),
  );
}

class LegacyCommunity extends StatelessWidget {
  const LegacyCommunity({super.key});
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
    children: [
      const Text(
        'Real talk,\nreal progress.',
        style: TextStyle(
          color: text,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1.08,
        ),
      ),
      const SizedBox(height: 21),
      const _Forum(
        '정시, 지금부터 어디까지 가능할까요?',
        '고2 학생의 수시·정시 전략이 궁금합니다.',
        '입시 정보마당',
        '5 · 7',
      ),
      const _Forum(
        '수학 진도를 따라가기 힘들어요',
        '아이의 현재 수준에 맞는 학습 방법을 찾고 있어요.',
        '학습 고민',
        '12 · 9',
      ),
      const _Forum(
        '이번 주 교육활동 모아보기',
        '서울 지역 경시대회와 진로 프로그램을 정리했어요.',
        '교육 소식',
        '4 · 2',
      ),
    ],
  );
}

class _Forum extends StatelessWidget {
  final String a, b, c, d;
  const _Forum(this.a, this.b, this.c, this.d);
  @override
  Widget build(BuildContext x) => Container(
    margin: const EdgeInsets.only(bottom: 11),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          label: Text(
            c,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: navy,
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
        Text(
          a,
          style: const TextStyle(
            color: text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(b, style: const TextStyle(color: mute, height: 1.5)),
        const SizedBox(height: 13),
        Text(
          '1주 전     ♡ ${d.split(' · ').first}   💬 ${d.split(' · ').last}',
          style: const TextStyle(color: mute, fontSize: 10),
        ),
      ],
    ),
  );
}

class Coach extends StatelessWidget {
  final SessionUser? user;
  final VoidCallback? onRequireLogin;
  final VoidCallback? onOpenHome;

  const Coach({super.key, this.user, this.onRequireLogin, this.onOpenHome});

  Future<void> _openCoachPlus(BuildContext context) async {
    if (user != null && !user!.isGuest) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumAdmissionOffer()),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, color: lime, size: 30),
              const SizedBox(height: 12),
              const Text(
                'COACH+ 플랜은\n회원 전용이에요.',
                style: TextStyle(
                  color: text,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '회원가입 또는 로그인 후 프로그램 구성과 결제 내용을 확인할 수 있어요. 영수증 티켓은 사용하지 않습니다.',
                style: TextStyle(color: mute, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onRequireLogin?.call();
                  },
                  child: const Text('회원가입·로그인하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
    children: [
      _Logo(onTap: onOpenHome),
      const SizedBox(height: 26),
      Row(
        children: [
          const Expanded(
            child: Text(
              'COACH+',
              style: TextStyle(
                color: text,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '2027·2028 대입',
              style: TextStyle(
                color: lime,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      const Text(
        '성적과 학생부를 바탕으로 이번 주 입시 전략을 설계합니다.',
        style: TextStyle(color: mute, fontSize: 13),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff121A2E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -16,
              child: IgnorePointer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 22,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xff5FA5FF).withValues(alpha: .34),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xff5FA5FF).withValues(alpha: .54),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 92,
                      decoration: BoxDecoration(
                        color: lime.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT STRATEGY',
                  style: TextStyle(
                    color: Color(0xffAAC8FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  '목표 대학까지의\n다음 단계를 찾아요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '성적과 학생부를 바탕으로 지금 필요한 전략을 정리해요.',
                  style: TextStyle(
                    color: Color(0xffCAD7EE),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _openCoachPlus(c),
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: const Text('COACH+ 플랜 보기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffB8E8FF),
                    foregroundColor: const Color(0xff111D38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      CoachStrategyPanel(user: user, onRequireLogin: onRequireLogin),
      const SizedBox(height: 20),
      const Text(
        'COACH+가 함께 보는 항목',
        style: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      const _CoachFeature(
        Icons.school_outlined,
        '학생부 · 세특 분석',
        '탐구 흐름과 전공 연결성을 점검해요.',
      ),
      const _CoachFeature(
        Icons.auto_graph_rounded,
        '전형 적합도',
        '교과 · 학종 · 정시 · 논술 전략을 비교해요.',
      ),
      const _CoachFeature(
        Icons.route_outlined,
        '이번 주 Action Plan',
        '다음 시험과 학생부 보완의 우선순위를 정해요.',
      ),
      const SizedBox(height: 7),
      const Text(
        '대학별 지원 판단은 해당 연도 공식 모집요강과 입시결과를 확인한 뒤 제공됩니다.',
        style: TextStyle(color: mute, fontSize: 10, height: 1.5),
      ),
    ],
  );
}

class _CoachFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _CoachFeature(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffE6E9EF)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: lime, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(color: mute, fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

class CoachAdmissionIntake extends StatefulWidget {
  const CoachAdmissionIntake({super.key});
  @override
  State<CoachAdmissionIntake> createState() => _CoachAdmissionIntakeState();
}

class _CoachAdmissionIntakeState extends State<CoachAdmissionIntake> {
  final record = TextEditingController(
    text: '정보 과목에서 알고리즘 효율성을 탐구하고, 프로그래밍 동아리에서 데이터 분석 프로젝트를 진행함.',
  );
  final school = [2.0, 1.5, 2.0, 2.5, 1.5];
  final mock = [2.0, 1.0, 2.0, 2.0];
  final majorsByUniversity = const {
    '서울대학교': ['컴퓨터공학부', '전기·정보공학부', '산업공학과', '수리과학부'],
    '연세대학교': ['컴퓨터과학과', '인공지능학과', '전기전자공학부', '산업공학과'],
    '고려대학교': ['컴퓨터학과', '데이터과학과', '전기전자공학부', '산업경영공학부'],
    '성균관대학교': ['컴퓨터공학과', '글로벌AI융합학부', '지능형소프트웨어학과', '인공지능학과'],
    '한양대학교': ['컴퓨터소프트웨어학부', '인공지능학과', '정보시스템학과', '산업공학과'],
  };
  String university = '서울대학교';
  String major = '컴퓨터공학부';
  bool loading = false;
  @override
  void dispose() {
    record.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    for (var index = 0; index < school.length; index++) {
      school[index] = _normalizeGrade(school[index]);
    }
    for (var index = 0; index < mock.length; index++) {
      mock[index] = _normalizeGrade(mock[index]);
    }
    final body = {
      'admission_year': 2027,
      'grade': 2,
      'major': major,
      'target_university': university,
      'school_grades': {
        'korean': school[0],
        'math': school[1],
        'english': school[2],
        'social': school[3],
        'science': school[4],
      },
      'mock_grades': {
        'korean': mock[0],
        'math': mock[1],
        'english': mock[2],
        'inquiry': mock[3],
      },
      'record_text': record.text,
      'ai_record_analysis': false,
    };
    Map<String, dynamic> result;
    try {
      final res = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) throw Exception();
      result = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      result = _fallback(body);
    }
    if (!mounted) return;
    setState(() => loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CoachAdmissionResult(data: result)),
    );
  }

  Map<String, dynamic> _fallback(Map<String, dynamic> input) {
    final schoolAvg = school.reduce((a, b) => a + b) / 5;
    final mockAvg = mock.reduce((a, b) => a + b) / 4;
    int score(double g) => (112.5 - g * 12.5).clamp(0, 100).round();
    final academic = score(schoolAvg);
    final csat = score(mockAvg);
    final recordScore = record.text.length > 70 ? 76 : 62;
    return {
      'major': input['major'],
      'primary_strategy': csat >= academic ? '정시 중심 전략' : '학생부교과 중심 전략',
      'primary_reason': csat >= academic
          ? '모의고사 경쟁력이 안정적입니다. 수능 실전 성과를 중심으로 설계하세요.'
          : '내신과 핵심교과 성취가 현재의 강점입니다.',
      'secondary_strategy': '학생부종합 병행 전략',
      'secondary_reason': '전공 탐구의 과정과 결과를 학생부에 더 구체적으로 연결하세요.',
      'scores': [
        {'label': '학업역량', 'value': academic},
        {'label': '수능역량', 'value': csat},
        {'label': '과목선택', 'value': 78},
        {'label': '학생부역량', 'value': recordScore},
      ],
      'risks': [
        '대학별 수능최저와 교과 반영방법을 공식 모집요강에서 확인하세요.',
        '전공 관련 탐구를 질문–과정–결과 구조로 세특에 남기세요.',
      ],
      'action_plan': '이번 주에는 취약 과목 오답을 정리하고, 다음 세특에 전공 탐구의 근거를 보완하세요.',
      'offline': true,
    };
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      title: const Text(
        'GACHI 입시 전략 진단',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '무료 입시 분석',
              style: TextStyle(color: lime, fontSize: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '현재 기록을 입력해 주세요.',
          style: TextStyle(
            color: text,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '결제 없이 핵심 전략과 이번 주 보완 과제를 확인합니다.',
          style: TextStyle(color: mute, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const Text(
          '희망 대학교',
          style: TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: university,
          decoration: _inputDecoration(),
          items: majorsByUniversity.keys
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() {
            university = value!;
            major = majorsByUniversity[value]!.first;
          }),
        ),
        const SizedBox(height: 17),
        const Text(
          '희망 전공',
          style: TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(university),
          initialValue: major,
          decoration: _inputDecoration(),
          items: majorsByUniversity[university]!
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => major = value!),
        ),
        const SizedBox(height: 5),
        Text(
          '$university $major 기준으로 전공 핵심교과와 학생부 연결성을 진단합니다.',
          style: const TextStyle(color: mute, fontSize: 10),
        ),
        const SizedBox(height: 17),
        const Text(
          '내신 성적',
          style: TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        _GradeRow(
          labels: const ['국어', '수학', '영어', '사회', '과학'],
          values: school,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 17),
        const Text(
          '모의고사 성적',
          style: TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        _GradeRow(
          labels: const ['국어', '수학', '영어', '탐구'],
          values: mock,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 17),
        _Field(
          '학생부 · 세특 · 활동',
          TextField(
            controller: record,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '탐구, 세특, 동아리 활동을 입력하세요.',
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: loading ? null : submit,
          style: FilledButton.styleFrom(
            backgroundColor: lime,
            foregroundColor: navy,
            minimumSize: const Size.fromHeight(56),
          ),
          child: Text(
            loading ? '분석 중...' : '무료 입시 분석 시작',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field(this.label, this.child);
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _GradeRow extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final VoidCallback onChanged;
  const _GradeRow({
    required this.labels,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext c) => Row(
    children: List.generate(
      labels.length,
      (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels[i],
                style: const TextStyle(color: mute, fontSize: 10),
              ),
              DropdownButton<double>(
                isExpanded: true,
                value: _normalizeGrade(values[i]),
                items: List.generate(17, (x) {
                  final value = 1 + x * .5;
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value.toStringAsFixed(1)),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    values[i] = value;
                    onChanged();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

double _normalizeGrade(double value) =>
    ((value * 2).round() / 2).clamp(1.0, 9.0).toDouble();

class CoachAdmissionResult extends StatelessWidget {
  final Map<String, dynamic> data;
  const CoachAdmissionResult({super.key, required this.data});
  @override
  Widget build(BuildContext c) {
    final scores = (data['scores'] as List).cast<Map>();
    final risks = (data['risks'] as List).cast<String>();
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        title: const Text(
          '나의 입시 전략',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '무료 분석 결과',
                style: TextStyle(color: lime, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${data['major']} 지원 전략',
            style: const TextStyle(
              color: text,
              fontSize: 27,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (data['offline'] == true)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                '서버 연결 전 임시 진단 결과입니다.',
                style: TextStyle(color: coral, fontSize: 10),
              ),
            ),
          const SizedBox(height: 16),
          _StrategyCard(
            '1순위',
            data['primary_strategy'] as String,
            data['primary_reason'] as String,
            lime,
          ),
          const SizedBox(height: 9),
          _StrategyCard(
            '2순위',
            data['secondary_strategy'] as String,
            data['secondary_reason'] as String,
            lavender,
          ),
          const SizedBox(height: 20),
          const Text(
            '현재 역량',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scores
                .map(
                  (s) => SizedBox(
                    width: (MediaQuery.of(c).size.width - 48) / 2,
                    child: _ScoreCard(s['label'] as String, s['value'] as int),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'COACH+ 체크포인트',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...risks.map(
            (risk) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                '• $risk',
                style: const TextStyle(color: mute, fontSize: 12, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THIS WEEK ACTION PLAN',
                  style: TextStyle(
                    color: Color(0xffAFC5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  data['action_plan'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '더 구체적인 지원 전략이 필요하신가요?',
                  style: TextStyle(color: text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                const Text(
                  '대학·전형별 GAP, 학생부 보완 항목과 4주 실행 로드맵을 정밀 분석에서 이어보세요.',
                  style: TextStyle(color: mute, fontSize: 11, height: 1.5),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    c,
                    MaterialPageRoute(
                      builder: (_) => PremiumAdmissionOffer(freeResult: data),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lime,
                    side: const BorderSide(color: Color(0xffA9C4FC)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text('유료 컨설턴트 매칭 시작'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    c,
                    MaterialPageRoute(
                      builder: (_) => PremiumAdmissionOffer(freeResult: data),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: const Text('유료 정밀 분석 비교하기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String rank, title, body;
  final Color color;
  const _StrategyCard(this.rank, this.title, this.body, this.color);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: surface,
      border: Border.all(color: const Color(0xffE6E9EF)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            rank,
            style: TextStyle(
              color: color == lime ? lime : navy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: mute, fontSize: 11, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int value;
  const _ScoreCard(this.label, this.value);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: mute, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          '$value점',
          style: const TextStyle(
            color: text,
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100,
          color: lime,
          backgroundColor: lavender,
          minHeight: 5,
        ),
      ],
    ),
  );
}

class Profile extends StatelessWidget {
  final SessionUser? user;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenHome;

  const Profile({super.key, this.user, this.onLogout, this.onOpenHome});
  @override
  Widget build(BuildContext c) {
    final displayName = user?.name ?? 'GACHI 학생';
    final email = user?.isGuest == true
        ? '체험 모드'
        : (user?.email ?? '로그인 정보 없음');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        _Logo(onTap: onOpenHome),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 29,
                backgroundColor: lavender,
                child: Icon(Icons.person_outline_rounded, color: lime),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: text,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mute, fontSize: 12),
                    ),
                    if (user?.authProvider == 'google') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffEEF4FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Google 계정 연결됨',
                          style: TextStyle(color: lime, fontSize: 9),
                        ),
                      ),
                    ],
                    if (user != null && !user!.isGuest) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffE8F0FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${user!.role.label} 계정',
                          style: const TextStyle(color: lime, fontSize: 9),
                        ),
                      ),
                    ],
                    if (user?.authProvider == 'email') ...[
                      const SizedBox(height: 6),
                      Text(
                        user?.isIdentityVerified == true
                            ? '실명 인증 완료'
                            : '이메일 계정 · 실명 미인증',
                        style: TextStyle(
                          color: user?.isIdentityVerified == true
                              ? const Color(0xff147A50)
                              : mute,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _ProfileItem(
          _roleIcon(user?.role ?? AppUserRole.student),
          '나의 역할과 권한',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(builder: (_) => RoleWorkspacePage(user: user)),
          ),
        ),
        _ProfileItem(
          Icons.bookmark_outline,
          '저장한 목표 대학',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => const _ProfileInfoPage(
                title: '저장한 목표 대학',
                icon: Icons.bookmark_outline,
                emptyTitle: '아직 저장한 목표 대학이 없어요',
                emptyBody: '대입전략에서 관심 대학을 선택하면 이곳에서 한 번에 확인할 수 있어요.',
              ),
            ),
          ),
        ),
        _ProfileItem(
          Icons.map_outlined,
          '나의 학습 로드맵',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => const _ProfileInfoPage(
                title: '나의 학습 로드맵',
                icon: Icons.map_outlined,
                emptyTitle: '목표를 추가해 로드맵을 시작하세요',
                emptyBody: '홈의 목표 추가에서 기간·주간 시간·약점을 입력하면 실행 로드맵이 만들어집니다.',
              ),
            ),
          ),
        ),
        _ProfileItem(
          Icons.workspace_premium_outlined,
          '유료 정밀 입시 분석',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(builder: (_) => const PremiumAdmissionOffer()),
          ),
        ),
        _ProfileItem(
          Icons.receipt_long_outlined,
          '결제 및 컨설팅 내역',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(builder: (_) => const PurchaseHistoryPage()),
          ),
        ),
        _ProfileItem(
          user?.isIdentityVerified == true
              ? Icons.verified_user_rounded
              : Icons.badge_outlined,
          user?.isIdentityVerified == true ? '실명 인증 완료' : '실명 인증',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => IdentityVerificationPage(user: user),
            ),
          ),
        ),
        _ProfileItem(
          Icons.settings_outlined,
          '설정',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(builder: (_) => const GachiSettingsPage()),
          ),
        ),
        if (user?.isAdmin == true)
          _ProfileItem(
            Icons.admin_panel_settings_outlined,
            '운영자 대시보드',
            onTap: () => Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            ),
          ),
        if (onLogout != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              user?.isGuest == true
                  ? '체험 모드 종료'
                  : user?.authProvider == 'google'
                  ? 'Google 로그아웃'
                  : '로그아웃',
            ),
          ),
        ],
      ],
    );
  }
}

class IdentityVerificationPage extends StatefulWidget {
  final SessionUser? user;

  const IdentityVerificationPage({super.key, required this.user});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  bool loading = false;
  String? message;

  Future<void> _startVerification() async {
    final token = widget.user?.authToken;
    if (token == null || token.isEmpty) {
      setState(
        () => message = widget.user?.isGuest == true
            ? '실명 인증은 회원가입 후 이용할 수 있습니다.'
            : '현재 계정은 서버 세션이 연결되지 않았습니다. 이메일 계정으로 로그인하거나 Google 서버 인증 연동을 완료해 주세요.',
      );
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$_authApiBaseUrl/api/identity/start'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw EmailAuthException(
          body['detail']?.toString() ?? '실명 인증을 시작하지 못했습니다.',
        );
      }
      final uri = Uri.tryParse(body['verification_url']?.toString() ?? '');
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const EmailAuthException('인증 페이지를 열지 못했습니다.');
      }
    } on EmailAuthException catch (error) {
      if (mounted) setState(() => message = error.message);
    } catch (_) {
      if (mounted) setState(() => message = '인증 서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, title: const Text('실명 인증')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.user?.isIdentityVerified == true
                    ? Icons.verified_user_rounded
                    : Icons.badge_outlined,
                color: widget.user?.isIdentityVerified == true
                    ? const Color(0xff147A50)
                    : lime,
                size: 34,
              ),
              const SizedBox(height: 16),
              Text(
                widget.user?.isIdentityVerified == true
                    ? '본인확인이 완료됐어요'
                    : '안전한 후기와 진단을 위한 본인확인',
                style: const TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PASS·NICE·KCB 같은 본인확인 사업자의 인증 결과만 서버에서 확인합니다. 주민등록번호와 신분증 원본은 GACHI가 직접 수집하거나 저장하지 않습니다.',
                style: TextStyle(color: mute, fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 18),
              if (widget.user?.isIdentityVerified != true)
                FilledButton.icon(
                  key: const Key('start-identity-verification'),
                  onPressed: loading ? null : _startVerification,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(loading ? '연결 중...' : '휴대폰 본인인증 시작'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: const TextStyle(
                    color: Color(0xffA53C24),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '연동 전 체크리스트',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const _IdentityChecklistItem('본인확인 사업자 계약 및 심사'),
        const _IdentityChecklistItem('서버 콜백 서명 검증'),
        const _IdentityChecklistItem('인증 결과 최소 저장 및 보유기간 설정'),
      ],
    ),
  );
}

class _IdentityChecklistItem extends StatelessWidget {
  final String label;
  const _IdentityChecklistItem(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 18, color: mute),
        const SizedBox(width: 9),
        Text(label, style: const TextStyle(color: mute, fontSize: 12)),
      ],
    ),
  );
}

class _ProfileInfoPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyBody;

  const _ProfileInfoPage({
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyBody,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: lavender,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: lime, size: 29),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              emptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: mute, fontSize: 11, height: 1.6),
            ),
          ],
        ),
      ),
    ),
  );
}

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  String? orderId;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (mounted) {
        setState(
          () => orderId = preferences.getString('gachi.purchase.last_order'),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, title: const Text('결제 및 컨설팅 내역')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: orderId == null
          ? const _ProfileEmptyState(
              icon: Icons.receipt_long_outlined,
              title: '아직 결제 내역이 없어요',
              body: '스토어에서 정밀 입시 분석을 구매하면 주문 정보가 표시됩니다.',
            )
          : Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xff168A73)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GACHI 정밀 입시 분석',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '주문번호 $orderId',
                          style: const TextStyle(color: mute, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}

class GachiSettingsPage extends StatefulWidget {
  const GachiSettingsPage({super.key});

  @override
  State<GachiSettingsPage> createState() => _GachiSettingsPageState();
}

class _GachiSettingsPageState extends State<GachiSettingsPage> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, title: const Text('설정')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          value: notificationsEnabled,
          onChanged: (value) => setState(() => notificationsEnabled = value),
          tileColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('학습·입시 알림'),
          subtitle: const Text('코치 플랜과 입시 정보 업데이트를 알려드려요.'),
        ),
        const SizedBox(height: 9),
        const _ProfileItem(Icons.shield_outlined, '개인정보 처리방침'),
        const _ProfileItem(Icons.description_outlined, '서비스 이용약관'),
      ],
    ),
  );
}

class _ProfileEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ProfileEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: lime, size: 42),
        const SizedBox(height: 13),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: mute, fontSize: 11, height: 1.5),
        ),
      ],
    ),
  );
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ProfileItem(this.icon, this.title, {this.onTap});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: lime),
        title: Text(
          title,
          style: const TextStyle(color: text, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, color: mute),
      ),
    ),
  );
}

class LegacyLevelTest extends StatefulWidget {
  const LegacyLevelTest({super.key});
  @override
  State<LegacyLevelTest> createState() => _LegacyLevelTestState();
}

class _LegacyLevelTestState extends State<LegacyLevelTest> {
  int q = 0;
  String subject = '수학';
  String grade = '고2';
  final answers = [false, false, false];

  static const questionsBySubject = {
    '국어': [
      '문단의 중심 내용을 파악할 때 가장 먼저 확인할 것은?',
      '글쓴이의 주장과 근거를 구분하는 활동은?',
      '다음 중 비유적 표현이 쓰인 문장은?',
    ],
    '영어': [
      'I ___ a student. 빈칸에 알맞은 말은?',
      '다음 중 "책을 읽다"에 해당하는 표현은?',
      '문장의 주어와 동사를 찾는 활동은 무엇에 도움이 될까요?',
    ],
    '수학': ['x + 7 = 15일 때 x는?', '일차함수 y = 2x + 3의 기울기는?', '삼각형 내각의 합은?'],
  };

  @override
  Widget build(BuildContext c) {
    if (q == 0) return _buildSetup();
    if (q == 4) {
      return _Result(
        '$grade $subject LEVEL ${answers.where((v) => v).length + 4}',
        '$subject의 현재 개념 이해도를 확인했어요.\n다음 진단에서 약한 유형을 더 정확히 찾아볼까요?',
        lime,
      );
    }
    final t = questionsBySubject[subject]![q - 1];
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        foregroundColor: text,
        title: Text('$grade · $subject · $q / 3'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              t,
              style: const TextStyle(
                color: text,
                fontSize: 29,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            for (final pair in [('정답이에요', true), ('잘 모르겠어요', false)])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    answers[q - 1] = pair.$2;
                    q++;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: text,
                    minimumSize: const Size.fromHeight(58),
                    side: const BorderSide(color: Color(0xff43506A)),
                  ),
                  child: Text(pair.$1),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetup() => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, foregroundColor: text),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Text(
              'GACHI LEVEL',
              style: TextStyle(
                color: lime,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '학년과 과목을\n선택해 주세요.',
              style: TextStyle(
                color: text,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '선택한 학년 기준의 짧은 진단으로\n현재 학습 위치를 확인해요.',
              style: TextStyle(color: mute, height: 1.55),
            ),
            const SizedBox(height: 32),
            const Text(
              '학년',
              style: TextStyle(color: text, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: grade,
              isExpanded: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              items: const ['중1', '중2', '중3', '고1', '고2', '고3']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => grade = value!),
            ),
            const SizedBox(height: 24),
            const Text(
              '진단 과목',
              style: TextStyle(color: text, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['국어', '영어', '수학']
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value),
                      selected: subject == value,
                      selectedColor: lime,
                      labelStyle: TextStyle(
                        color: subject == value ? Colors.white : text,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => subject = value),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => setState(() => q = 1),
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: navy,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text(
                '$grade $subject 무료 진단 시작',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  final String title, body;
  final Color color;
  const _Result(this.title, this.body, this.color);
  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: mist,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'YOUR RESULT',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: text,
              fontSize: 36,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(color: mute, fontSize: 15, height: 1.6),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => const AdmissionForm()),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: navy,
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text(
              '내 진학 전략 확인하기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class AdmissionForm extends StatelessWidget {
  const AdmissionForm({super.key});
  @override
  Widget build(BuildContext c) => const AdmissionStrategyHub();
}

class HighReport extends StatelessWidget {
  const HighReport({super.key});
  @override
  Widget build(BuildContext c) => _Result(
    '일반고 적합도 92%',
    '현재 학습 성향과 목표를 고려했을 때\n일반고 환경에서의 성장이 기대됩니다.',
    coral,
  );
}

class Paywall extends StatelessWidget {
  const Paywall({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(backgroundColor: mist, foregroundColor: text),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COACH+',
            style: TextStyle(
              color: lime,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '가장 필요한\n다음 한 걸음.',
            style: TextStyle(
              color: text,
              fontSize: 35,
              height: 1.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          const _PayRow('심층 입시 분석', '대학 · 학과 · 전형별 GAP'),
          const _PayRow('개인 로드맵', '주간 학습 우선순위'),
          const _PayRow('전문가 컨설팅', '목표 전략 점검'),
          const Spacer(),
          FilledButton(
            onPressed: () => showDialog(
              context: c,
              builder: (_) => const AlertDialog(
                title: Text('상담 신청'),
                content: Text('결제·예약 기능을 연결하면 상담을 신청할 수 있습니다.'),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: navy,
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text(
              '상담 신청하기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PayRow extends StatelessWidget {
  final String a, b;
  const _PayRow(this.a, this.b);
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: lime, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a,
              style: const TextStyle(color: text, fontWeight: FontWeight.w600),
            ),
            Text(b, style: const TextStyle(color: mute, fontSize: 11)),
          ],
        ),
      ],
    ),
  );
}
