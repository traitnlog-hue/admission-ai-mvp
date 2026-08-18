import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

const navy = Color(0xff101114),
    surface = Color(0xffFFFFFF),
    lime = Color(0xff0B63F6),
    lavender = Color(0xffEAF1FF),
    mist = Color(0xffF6F8FC),
    text = Color(0xff14161B),
    mute = Color(0xff778091),
    coral = Color(0xffFF5A1F);
void main() => runApp(const GachiApp());

class GachiApp extends StatelessWidget {
  const GachiApp({super.key});
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
    home: const AuthGate(),
  );
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
  List<Widget> get pages => [
    Home(
      user: widget.user,
      onRequireLogin: widget.onLogout,
      onOpenProfile: () => setState(() => index = 4),
    ),
    Explore(
      user: widget.user,
      onRequireLogin: widget.onLogout,
      onOpenCoach: () => setState(() => index = 3),
    ),
    Community(user: widget.user, onRequireLogin: widget.onLogout),
    Coach(user: widget.user, onRequireLogin: widget.onLogout),
    Profile(user: widget.user, onLogout: widget.onLogout),
  ];
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(child: pages[index]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        c,
        MaterialPageRoute(builder: (_) => const ChatAssistantPage()),
      ),
      backgroundColor: lime,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
      label: const Text('AI 챗봇'),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xff242F46),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xffB9C3D5),
                size: 25,
              ),
            ),
            labelTextStyle: WidgetStatePropertyAll(
              const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: NavigationBar(
            height: 74,
            backgroundColor: Colors.transparent,
            indicatorColor: lime,
            onDestinationSelected: (i) => setState(() => index = i),
            selectedIndex: index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                label: '탐색',
              ),
              NavigationDestination(
                icon: Icon(Icons.forum_outlined),
                label: '커뮤니티',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                label: '코치',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'MY',
              ),
            ],
          ),
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
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool hasUnreadNotifications;

  const _Top({
    this.initial = '지',
    this.onNotifications,
    this.onProfile,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext c) => Row(
    children: [
      const _Logo(),
      const Spacer(),
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
  const _Logo();
  @override
  Widget build(BuildContext c) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: lime, shape: BoxShape.circle),
        child: Center(
          child: Text(
            'G',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
      SizedBox(width: 9),
      Text(
        'GACHI',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
          color: text,
        ),
      ),
    ],
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
              final profile = await Navigator.push<AcademyStudentProfile>(
                c,
                MaterialPageRoute(
                  builder: (_) => AcademyMatchForm(initial: academyProfile),
                ),
              );
              if (profile != null) setState(() => academyProfile = profile);
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
          final profile = await Navigator.push<AcademyStudentProfile>(
            c,
            MaterialPageRoute(
              builder: (_) => AcademyMatchForm(initial: academyProfile),
            ),
          );
          if (profile != null) setState(() => academyProfile = profile);
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

class _StudentProfileCard extends StatelessWidget {
  final AcademyStudentProfile? profile;
  final VoidCallback onEdit;
  const _StudentProfileCard({required this.profile, required this.onEdit});
  @override
  Widget build(BuildContext c) {
    if (profile == null) {
      return InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_add_alt_1_outlined,
                color: lime,
                size: 28,
              ),
              const SizedBox(height: 12),
              const Text(
                '학생 정보를 등록해 주세요',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '지역, 학교, 관심 과목과 학습 수준을 입력하면 맞춤 학원 추천을 시작합니다.',
                style: TextStyle(color: mute, fontSize: 11, height: 1.45),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Text(
                    '학생 정보 입력',
                    style: TextStyle(color: lime, fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: lime),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final p = profile!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE2E6EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: mute, size: 20),
              ),
            ],
          ),
          Text(
            '${p.school} ${p.grade} | ${p.region}',
            style: const TextStyle(color: mute, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: mist,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _ProfileInfo('관심 과목', p.subjects.join('  ·  '), lime),
                const SizedBox(height: 9),
                _ProfileInfo('학습 수준', p.level, text),
                const SizedBox(height: 9),
                _ProfileInfo(
                  '학원 조건',
                  p.academyCondition.isEmpty
                      ? '입력한 조건으로 추천'
                      : p.academyCondition,
                  mute,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: navy,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text(
              '맞춤 학원 추천받기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _ProfileInfo(this.label, this.value, this.valueColor);
  @override
  Widget build(BuildContext c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 65,
        child: Text(
          label,
          style: const TextStyle(
            color: mute,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class AcademyMatchForm extends StatefulWidget {
  final AcademyStudentProfile? initial;
  const AcademyMatchForm({super.key, this.initial});
  @override
  State<AcademyMatchForm> createState() => _AcademyMatchFormState();
}

class _AcademyMatchFormState extends State<AcademyMatchForm> {
  late final TextEditingController name;
  late final TextEditingController school;
  late final TextEditingController academyCondition;
  String region = '서울 강남구';
  String grade = '고2';
  String level = '개념은 안정적, 심화 보완 필요';
  late Set<String> subjects;
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
    if (saved != null && mounted) Navigator.pop(context, saved);
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
  const _Quick(this.icon, this.text, this.tap);
  @override
  Widget build(BuildContext c) => Expanded(
    child: InkWell(
      onTap: tap,
      child: Column(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xff4B5569)),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(height: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
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

  const Coach({super.key, this.user, this.onRequireLogin});
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
    children: [
      const _Logo(),
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
          color: navy,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADMISSION SNAPSHOT',
              style: TextStyle(
                color: Color(0xffAFC5FF),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              '대입 전략을\n새로 진단해볼까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => openTicketProtectedFeature(
                context: c,
                user: user,
                onRequireLogin: onRequireLogin,
                featureName: '무료 대입전략 진단',
                destination: const AdmissionStrategyHub(),
              ),
              icon: const Icon(Icons.insights_outlined, size: 18),
              label: const Text('입시 전략 진단 시작'),
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: navy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
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

  const Profile({super.key, this.user, this.onLogout});
  @override
  Widget build(BuildContext c) {
    final displayName = user?.name ?? 'GACHI 학생';
    final email = user?.isGuest == true
        ? '체험 모드'
        : (user?.email ?? '로그인 정보 없음');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        const _Logo(),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
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
          Icons.settings_outlined,
          '설정',
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(builder: (_) => const GachiSettingsPage()),
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
