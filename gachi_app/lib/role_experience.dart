part of 'main.dart';

class ParentHome extends StatelessWidget {
  final SessionUser? user;
  const ParentHome({super.key, this.user});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
    children: [
      const _RoleTopBar(role: AppUserRole.parent),
      const SizedBox(height: 28),
      Text(
        '${user?.name ?? '학부모'}님,\n아이의 오늘을 함께 살펴볼까요?',
        style: const TextStyle(
          color: text,
          fontSize: 26,
          height: 1.22,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        '연결된 학생의 학습 흐름과 상담 진행 상황을 한곳에서 확인하세요.',
        style: TextStyle(color: mute, fontSize: 12, height: 1.45),
      ),
      const SizedBox(height: 18),
      _RoleHeroCard(
        icon: Icons.family_restroom_outlined,
        eyebrow: 'FAMILY DASHBOARD',
        title: '연결된 학생이 없어요',
        body: '학생 계정의 초대 코드로 연결하면 학습 플랜과 상담 요약을 확인할 수 있어요.',
        action: '학생 계정 연결',
        onTap: () => _showConnectionGuide(context),
      ),
      const SizedBox(height: 18),
      const Text(
        '학부모 관리 메뉴',
        style: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      const _RoleMenuCard(
        icon: Icons.auto_graph_rounded,
        title: '학습 리포트',
        body: '주간 학습 완료율과 회고를 확인해요.',
      ),
      const _RoleMenuCard(
        icon: Icons.chat_outlined,
        title: '상담 진행 현황',
        body: '입시 전문가 상담의 일정과 요약을 확인해요.',
      ),
      const _RoleMenuCard(
        icon: Icons.privacy_tip_outlined,
        title: '공유 범위 관리',
        body: '학생이 허용한 학습·상담 정보만 표시돼요.',
      ),
    ],
  );

  void _showConnectionGuide(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '학생 계정 연결',
              style: TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '학생의 동의와 초대 코드가 있어야만 연결할 수 있습니다. 현재 MVP에서는 연결 UI만 제공하며 실제 학생 정보는 공유되지 않습니다.',
              style: TextStyle(color: mute, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class ConsultantHome extends StatelessWidget {
  final SessionUser? user;
  const ConsultantHome({super.key, this.user});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
    children: [
      const _RoleTopBar(role: AppUserRole.consultant),
      const SizedBox(height: 28),
      Text(
        '${user?.name ?? '입시 전문가'}님,\n오늘의 상담 흐름을 확인하세요.',
        style: const TextStyle(
          color: text,
          fontSize: 26,
          height: 1.22,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 18),
      _RoleHeroCard(
        icon: Icons.groups_2_outlined,
        eyebrow: 'CONSULTANT WORKSPACE',
        title: '새 매칭 요청 0건',
        body: '관리자 승인 후 배정된 학생의 상담 요청이 이곳에 표시됩니다.',
        action: '상담 운영 안내',
        onTap: () => _showConsultantGuide(context),
      ),
      const SizedBox(height: 18),
      const Text(
        '입시 전문가 관리 메뉴',
        style: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      const _RoleMenuCard(
        icon: Icons.calendar_month_outlined,
        title: '상담 일정',
        body: '확정된 상담 일정과 사전 질문을 관리해요.',
      ),
      const _RoleMenuCard(
        icon: Icons.assignment_outlined,
        title: '학생 상담 노트',
        body: '학생별 상담 기록과 다음 과제를 정리해요.',
      ),
      const _RoleMenuCard(
        icon: Icons.verified_user_outlined,
        title: '프로필·전문 분야',
        body: '운영 승인 후 공개될 소개 정보를 관리해요.',
      ),
    ],
  );

  void _showConsultantGuide(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '입시 전문가 운영 안내',
              style: TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '입시 전문가 계정은 운영자 검토·승인 후 활성화됩니다. MVP에서는 일정과 상담 노트를 실제 학생에게 전송하지 않습니다.',
              style: TextStyle(color: mute, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class RoleWorkspacePage extends StatelessWidget {
  final SessionUser? user;
  const RoleWorkspacePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? AppUserRole.student;
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(backgroundColor: mist, title: const Text('나의 역할과 권한')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _RoleHeroCard(
            icon: _roleIcon(role),
            eyebrow: 'CURRENT ROLE',
            title: '${role.label} 계정',
            body: _roleDescription(role),
            action: role == AppUserRole.admin ? '운영자 대시보드 열기' : '역할별 이용 안내',
            onTap: () {
              if (role == AppUserRole.admin) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleAdminPage()),
                );
              } else {
                _showRoleGuide(context, role);
              }
            },
          ),
          const SizedBox(height: 20),
          const Text(
            '역할별 서비스 범위',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...AppUserRole.values.map(
            (item) => _RolePermissionRow(role: item, active: role == item),
          ),
          const SizedBox(height: 18),
          const Text(
            '역할은 앱에서 직접 변경할 수 없습니다. Supabase의 관리자 전용 권한 정보로 관리하며, 역할 변경 뒤에는 다시 로그인해야 적용됩니다.',
            style: TextStyle(color: mute, fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ManagedRoleUser {
  final String id;
  final String name;
  final String email;
  final AppUserRole role;
  const ManagedRoleUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory ManagedRoleUser.fromJson(Map<String, dynamic> json) =>
      ManagedRoleUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '이름 없음',
        email: json['email']?.toString() ?? '',
        role: AppUserRole.fromClaim(json['role']),
      );
}

class RoleAdminService {
  static Future<List<ManagedRoleUser>> loadUsers() async {
    final response = await Supabase.instance.client.functions.invoke(
      'manage-roles',
      method: HttpMethod.get,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final users = (data['users'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              ManagedRoleUser.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  static Future<void> updateRole({
    required String userId,
    required AppUserRole role,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'manage-roles',
      body: {'userId': userId, 'role': role.name},
    );
  }
}

class RoleAdminPage extends StatefulWidget {
  const RoleAdminPage({super.key});

  @override
  State<RoleAdminPage> createState() => _RoleAdminPageState();
}

class _RoleAdminPageState extends State<RoleAdminPage> {
  bool loading = true;
  String? error;
  List<ManagedRoleUser> users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      users = await RoleAdminService.loadUsers();
    } on FunctionException catch (exception) {
      error = exception.status == 403
          ? '관리자 권한이 있는 계정만 역할을 관리할 수 있습니다.'
          : '계정 목록을 불러오지 못했습니다.';
    } catch (_) {
      error = '계정 목록을 불러오지 못했습니다. 네트워크를 확인해 주세요.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateRole(ManagedRoleUser user, AppUserRole nextRole) async {
    if (user.role == nextRole) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('계정 역할 변경'),
        content: Text(
          '${user.name} 계정을 ${nextRole.label} 역할로 변경할까요?\n\n대상 사용자는 다시 로그인하면 새 화면과 권한이 적용됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('변경'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    try {
      await RoleAdminService.updateRole(userId: user.id, role: nextRole);
      if (!mounted) return;
      setState(() {
        users = users
            .map(
              (item) => item.id == user.id
                  ? ManagedRoleUser(
                      id: item.id,
                      name: item.name,
                      email: item.email,
                      role: nextRole,
                    )
                  : item,
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('역할을 변경했습니다. 대상 계정은 다시 로그인하면 적용됩니다.')),
      );
    } on FunctionException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exception.status == 403 ? '관리자 권한이 없습니다.' : '역할을 변경하지 못했습니다.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('역할을 변경하지 못했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: mist,
    appBar: AppBar(
      backgroundColor: mist,
      title: const Text('계정 역할 관리'),
      actions: [
        IconButton(
          onPressed: loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? _RoleAdminError(message: error!, onRetry: _load)
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                '사용자 역할 관리',
                style: TextStyle(
                  color: text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '역할 변경은 서버에서 관리자 권한을 다시 확인한 뒤 처리되며, 모든 변경은 이력으로 남습니다.',
                style: TextStyle(color: mute, fontSize: 11, height: 1.45),
              ),
              const SizedBox(height: 16),
              ...users.map(
                (user) => _ManagedRoleUserCard(
                  user: user,
                  onChanged: (role) => _updateRole(user, role),
                ),
              ),
            ],
          ),
  );
}

class _RoleAdminError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _RoleAdminError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, color: mute, size: 34),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mute, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );
}

class _ManagedRoleUserCard extends StatelessWidget {
  final ManagedRoleUser user;
  final ValueChanged<AppUserRole> onChanged;
  const _ManagedRoleUserCard({required this.user, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xffE0E7F2)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(_roleIcon(user.role), color: lime, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: mute, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<AppUserRole>(
          value: user.role,
          underline: const SizedBox(),
          items: AppUserRole.values
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.label, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: (role) {
            if (role != null) onChanged(role);
          },
        ),
      ],
    ),
  );
}

class _RoleTopBar extends StatelessWidget {
  final AppUserRole role;
  const _RoleTopBar({required this.role});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const GachiBrandLogo(width: 104),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: lavender,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '${role.label} 모드',
          style: const TextStyle(
            color: lime,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _RoleHeroCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  const _RoleHeroCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xffA9C8FF), size: 28),
        const SizedBox(height: 14),
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xffA9C8FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xffC7D0E2),
            fontSize: 11,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 15),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xffBCE7FF),
            foregroundColor: navy,
          ),
          child: Text(action),
        ),
      ],
    ),
  );
}

class _RoleMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _RoleMenuCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffE0E7F2)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: lime, size: 21),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(color: mute, fontSize: 10, height: 1.35),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: mute),
      ],
    ),
  );
}

class _RolePermissionRow extends StatelessWidget {
  final AppUserRole role;
  final bool active;
  const _RolePermissionRow({required this.role, required this.active});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: active ? lavender : surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: active ? const Color(0xffB9D3FF) : const Color(0xffE0E7F2),
      ),
    ),
    child: Row(
      children: [
        Icon(_roleIcon(role), color: active ? lime : mute, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.label,
                style: const TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _roleDescription(role),
                style: const TextStyle(color: mute, fontSize: 9, height: 1.35),
              ),
            ],
          ),
        ),
        if (active)
          const Icon(Icons.check_circle_rounded, color: lime, size: 20),
      ],
    ),
  );
}

IconData _roleIcon(AppUserRole role) => switch (role) {
  AppUserRole.student => Icons.school_outlined,
  AppUserRole.parent => Icons.family_restroom_outlined,
  AppUserRole.consultant => Icons.support_agent_outlined,
  AppUserRole.admin => Icons.admin_panel_settings_outlined,
};

String _roleDescription(AppUserRole role) => switch (role) {
  AppUserRole.student => '학습 플랜·진단·입시 전략을 직접 관리합니다.',
  AppUserRole.parent => '학생이 동의한 학습 리포트와 상담 현황을 확인합니다.',
  AppUserRole.consultant => '배정된 학생의 상담 일정·노트를 관리합니다.',
  AppUserRole.admin => '승인·제보·매칭 요청 등 운영 업무를 관리합니다.',
};

void _showRoleGuide(BuildContext context, AppUserRole role) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${role.label} 역할 안내',
                style: const TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _roleDescription(role),
                style: const TextStyle(color: mute, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
