part of 'attendance_summary_screen.dart';

class AttendanceLeaderboardScreen extends StatefulWidget {
  const AttendanceLeaderboardScreen({super.key, required this.year});

  final int year;

  @override
  State<AttendanceLeaderboardScreen> createState() =>
      _AttendanceLeaderboardScreenState();
}

class _AttendanceLeaderboardScreenState
    extends State<AttendanceLeaderboardScreen> {
  late int _year;
  String _order = 'present';
  List<_Json> _members = [];
  bool _loading = true;
  String? _error;
  int _requestId = 0;
  int _sessions = 0;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await AttendanceService.instance
          .getAttendanceLeaderboard(_year);
      final data = _Json.from(response['data'] as Map);
      final members = (data['members'] as List)
          .map((item) => _Json.from(item as Map))
          .toList();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _members = members;
        _sessions = (data['attendanceSessions'] as num).toInt();
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [..._members]
      ..sort((a, b) {
        final count = (b[_order] as num).compareTo(a[_order] as num);
        if (count != 0) return count;
        final name = _summaryMemberName(
          a,
        ).toLowerCase().compareTo(_summaryMemberName(b).toLowerCase());
        return name != 0
            ? name
            : _summaryMemberId(a)!.compareTo(_summaryMemberId(b)!);
      });
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar(
        'Attendance leaderboard',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _labeled(
                        'Attendance year',
                        _lightDropdown<int>(
                          value: _year,
                          items: [
                            for (var year = 2100; year >= 2000; year--)
                              DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null || value == _year) return;
                            setState(() => _year = value);
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _labeled(
                        'Order by',
                        _lightDropdown<String>(
                          value: _order,
                          items: const [
                            DropdownMenuItem(
                              value: 'present',
                              child: Text('Most present'),
                            ),
                            DropdownMenuItem(
                              value: 'absent',
                              child: Text('Most absent'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _order = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Highest to lowest • Ties ordered by name',
                        style: _T.body(13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only recorded marks count. Unmarked weeks are excluded.',
                        style: _T.body(13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? _loadingState()
                      : _error != null
                      ? _errorState(_error!, _load)
                      : RefreshIndicator(
                          color: _C.accent,
                          onRefresh: _load,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            itemCount: sorted.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    sorted.isEmpty
                                        ? 'No members found.'
                                        : _sessions == 0
                                        ? 'No attendance recorded for $_year. All ${sorted.length} members shown with zero counts.'
                                        : '${sorted.length} members • $_sessions recorded weeks',
                                    style: _T.body(14),
                                  ),
                                );
                              }
                              final member = sorted[index - 1];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _C.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _C.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$index',
                                      style: _T.display(20, color: _C.accent),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _summaryMemberName(member),
                                            style: _T.display(17),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 20,
                                            runSpacing: 8,
                                            children: [
                                              Text(
                                                'Present: ${member['present']}',
                                                style: _T.body(
                                                  14,
                                                  weight: FontWeight.w700,
                                                  color: _C.success,
                                                ),
                                              ),
                                              Text(
                                                'Absent: ${member['absent']}',
                                                style: _T.body(
                                                  14,
                                                  weight: FontWeight.w700,
                                                  color: _C.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
}
