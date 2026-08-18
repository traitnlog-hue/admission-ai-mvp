part of 'main.dart';

class AdminOperation {
  final String id;
  final String type;
  final String title;
  final String detail;
  final String status;
  final DateTime createdAt;

  const AdminOperation({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.status,
    required this.createdAt,
  });

  factory AdminOperation.fromJson(Map<String, dynamic> json) => AdminOperation(
    id: json['id'].toString(),
    type: json['operation_type'].toString(),
    title: json['title'].toString(),
    detail: json['detail'].toString(),
    status: json['status'].toString(),
    createdAt:
        DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
  );
}

class AdminOperationsService {
  static Future<List<AdminOperation>> load() async {
    final rows = await Supabase.instance.client
        .from('admin_operations')
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => AdminOperation.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<void> updateStatus(String id, String status) async {
    await Supabase.instance.client
        .from('admin_operations')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool loading = true;
  String? error;
  List<AdminOperation> operations = const [];

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
      operations = await AdminOperationsService.load();
    } on PostgrestException {
      error = '운영자 권한을 확인하지 못했습니다. 다시 로그인해 주세요.';
    } catch (_) {
      error = '운영 데이터를 불러오지 못했습니다. 네트워크를 확인해 주세요.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _changeStatus(AdminOperation operation, String status) async {
    try {
      await AdminOperationsService.updateStatus(operation.id, status);
      await _load();
    } on PostgrestException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 권한이 없습니다. 다시 로그인해 주세요.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('상태를 변경하지 못했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = operations
        .where((item) => item.status == 'pending' || item.status == 'in_review')
        .length;
    final matches = operations
        .where(
          (item) =>
              item.type == 'consultant_match' && item.status != 'resolved',
        )
        .length;
    final resolved = operations
        .where(
          (item) => ['approved', 'assigned', 'resolved'].contains(item.status),
        )
        .length;
    return Scaffold(
      backgroundColor: mist,
      appBar: AppBar(
        backgroundColor: mist,
        title: const Text('운영자 대시보드'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                children: [
                  const Text(
                    '오늘의 운영 현황',
                    style: TextStyle(
                      color: text,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '후기·신고·매칭 요청을 확인하고 바로 처리하세요.',
                    style: TextStyle(color: mute, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _AdminMetric(
                        label: '처리 대기',
                        value: '$pending',
                        color: lime,
                      ),
                      const SizedBox(width: 10),
                      _AdminMetric(
                        label: '매칭 요청',
                        value: '$matches',
                        color: const Color(0xff7057E8),
                      ),
                      const SizedBox(width: 10),
                      _AdminMetric(
                        label: '처리 완료',
                        value: '$resolved',
                        color: const Color(0xff147A50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '운영 큐',
                          style: TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '관리자 전용',
                        style: TextStyle(color: mute, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (error != null)
                    _AdminEmpty(message: error!)
                  else if (operations.isEmpty)
                    const _AdminEmpty(message: '현재 처리할 운영 항목이 없습니다.')
                  else
                    ...operations.map(
                      (operation) => _AdminOperationCard(
                        operation: operation,
                        onChangeStatus: _changeStatus,
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'MVP에서는 예시 운영 항목으로 흐름을 확인합니다. 실제 후기·신고·상담 요청을 연결하면 동일한 큐에서 검수와 배정을 처리할 수 있어요.',
                    style: TextStyle(color: mute, fontSize: 11, height: 1.55),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AdminMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: mute, fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AdminOperationCard extends StatelessWidget {
  final AdminOperation operation;
  final Future<void> Function(AdminOperation operation, String status)
  onChangeStatus;

  const _AdminOperationCard({
    required this.operation,
    required this.onChangeStatus,
  });

  String get _typeLabel => switch (operation.type) {
    'academy_review' => '후기 검수',
    'community_report' => '커뮤니티 신고',
    'consultant_match' => '컨설턴트 매칭',
    _ => '고객 지원',
  };

  String get _statusLabel => switch (operation.status) {
    'pending' => '대기',
    'in_review' => '검토 중',
    'approved' => '승인',
    'hidden' => '숨김',
    'assigned' => '배정 완료',
    _ => '처리 완료',
  };

  String get _nextStatus => switch (operation.status) {
    'pending' => 'in_review',
    'in_review' =>
      operation.type == 'consultant_match' ? 'assigned' : 'approved',
    'approved' || 'assigned' => 'resolved',
    _ => 'resolved',
  };

  String get _actionLabel => switch (operation.status) {
    'pending' => '검토 시작',
    'in_review' => operation.type == 'consultant_match' ? '컨설턴트 배정' : '승인 처리',
    'approved' || 'assigned' => '처리 완료',
    _ => '완료됨',
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE1E6EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _typeLabel,
                style: const TextStyle(color: lime, fontSize: 10),
              ),
            ),
            const Spacer(),
            Text(
              _statusLabel,
              style: const TextStyle(color: mute, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          operation.title,
          style: const TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          operation.detail,
          style: const TextStyle(color: mute, fontSize: 11, height: 1.45),
        ),
        const SizedBox(height: 13),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: operation.status == 'resolved'
                ? null
                : () => onChangeStatus(operation, _nextStatus),
            child: Text(_actionLabel),
          ),
        ),
      ],
    ),
  );
}

class _AdminEmpty extends StatelessWidget {
  final String message;
  const _AdminEmpty({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(message, style: const TextStyle(color: mute, fontSize: 12)),
  );
}
