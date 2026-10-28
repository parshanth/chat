part of 'attendance_summary_screen.dart';

class _MemberAttendanceHistoryEntry {
  const _MemberAttendanceHistoryEntry({
    required this.date,
    required this.status,
  });

  final DateTime date;
  final String status;
}

Future<List<_MemberAttendanceHistoryEntry>> _loadMemberAttendanceHistory({
  required AttendanceService service,
  required int year,
  required String memberId,
}) async {
  final response = await service.getAttendanceSummary(
    year: year,
    memberId: memberId,
    includeMemberStatus: true,
  );
  final data = Map<String, dynamic>.from(response['data'] as Map);
  final records = data['records'] as List<dynamic>? ?? [];
  final history = <_MemberAttendanceHistoryEntry>[];

  for (final item in records) {
    if (item is! Map) continue;
    final session = Map<String, dynamic>.from(item);
    final rawDate = session['date']?.toString();
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (date == null || date.year != year || date.weekday != DateTime.sunday) {
      continue;
    }

    final status = session['memberStatus']?.toString().toLowerCase();
    history.add(
      _MemberAttendanceHistoryEntry(
        date: date,
        status: status == 'present' || status == 'absent'
            ? status!
            : 'unmarked',
      ),
    );
  }

  history.sort((a, b) => b.date.compareTo(a.date));
  return history;
}

String _formatMemberProfileDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return 'Not provided';

  final date = DateTime.tryParse(raw);
  if (date == null) return raw;

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

Future<void> _copyMemberPhoneNumber(BuildContext context, String phone) async {
  try {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Phone number copied.')));
  } on Exception {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to copy the phone number.')),
    );
  }
}

// ---------------------------------------------------------------------------
// Member history list
// ---------------------------------------------------------------------------
class AttendanceDetailsScreen extends StatefulWidget {
  const AttendanceDetailsScreen({super.key, required this.initialYear});

  final int initialYear;

  @override
  State<AttendanceDetailsScreen> createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  final MemberService _memberService = MemberService();

  bool _loading = true;
  String? _error;
  String _search = '';
  late int _selectedYear;
  List<Map<String, dynamic>> _members = [];
  final Map<String, Future<List<_MemberAttendanceHistoryEntry>>>
  _historyRequests = {};

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _loadMembers();
  }

  String _name(Map<String, dynamic> member) {
    final value =
        (member['fullName'] ?? member['name'] ?? member['firstName'] ?? '')
            .toString()
            .trim();

    return value.isEmpty ? 'Unnamed member' : value;
  }

  String? _id(Map<String, dynamic> member) {
    return (member['_id'] ?? member['id'] ?? member['memberId'])?.toString();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final allMembers = (await _memberService.getMembers())
          .map((member) => member.toJson())
          .toList();
      allMembers.sort(
        (a, b) => _name(a).toLowerCase().compareTo(_name(b).toLowerCase()),
      );

      if (!mounted) return;

      setState(() {
        _members = allMembers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  OutlineInputBorder _fieldBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((member) {
      return _name(member).toLowerCase().contains(_search.trim().toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar(
        'Member history',
        actions: [
          IconButton(
            tooltip: 'Refresh members',
            onPressed: _loading ? null : _loadMembers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _C.accent,
                      strokeWidth: 3,
                    ),
                  )
                : _error != null
                ? _errorState(_error!, _loadMembers)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Members',
                            style: _T.display(34, letterSpacing: -1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _labeled('Search members', _searchField()),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 112,
                              child: _labeled('Year', _yearField()),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${filtered.length} members',
                            style: _T.body(
                              14,
                              weight: FontWeight.w600,
                              color: _C.textSubtle,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  _members.isEmpty
                                      ? 'No members found.'
                                      : 'No members match your search.',
                                  style: _T.body(15),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) =>
                                    _memberTile(filtered[index]),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      style: _T.body(15, weight: FontWeight.w600, color: _C.inputText),
      cursorColor: _C.inputFocus,
      decoration: InputDecoration(
        hintText: 'Search by name',
        hintStyle: _T.body(15, color: _C.inputHint),
        filled: true,
        fillColor: _C.inputBg,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: _C.inputIcon),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () => setState(() => _search = ''),
                icon: const Icon(Icons.close_rounded, color: _C.inputIcon),
              ),
        border: _fieldBorder(_C.inputBorder),
        enabledBorder: _fieldBorder(_C.inputBorder),
        focusedBorder: _fieldBorder(_C.inputFocus, 1.8),
      ),
      onChanged: (value) => setState(() => _search = value),
    );
  }

  Widget _yearField() {
    return _lightDropdown<int>(
      value: _selectedYear,
      items: List.generate(11, (index) => DateTime.now().year - 5 + index)
          .map(
            (year) => DropdownMenuItem<int>(value: year, child: Text('$year')),
          )
          .toList(),
      onChanged: (year) {
        if (year != null) {
          setState(() {
            _selectedYear = year;
            _historyRequests.clear();
          });
        }
      },
    );
  }

  Widget _memberTile(Map<String, dynamic> member) {
    final name = _name(member);
    final id = _id(member);
    final enabled = id != null && id.isNotEmpty;

    return Material(
      color: _C.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _C.border),
      ),
      child: InkWell(
        onTap: !enabled
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemberAttendanceDetailScreen(
                      memberId: id,
                      memberName: name,
                      memberDetails: member,
                      year: _selectedYear,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _initialsBlock(name),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.display(16, letterSpacing: -0.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View attendance chart and history',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.body(13, color: _C.textSubtle),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled ? _C.text2 : _C.border,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _memberProfile(member, name, id),
              const SizedBox(height: 18),
              _attendanceHistory(id, enabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberProfile(Map<String, dynamic> member, String name, String? id) {
    final phone = member['phoneNumber']?.toString().trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _profileRow('Full name', name),
        _profileRow(
          'Phone number',
          phone.isEmpty ? null : phone,
          onTap: phone.isEmpty
              ? null
              : () => _copyMemberPhoneNumber(context, phone),
        ),
        _profileRow('Date of birth', _formatMemberProfileDate(member['dob'])),
        _profileRow(
          'Baptism date',
          _formatMemberProfileDate(member['baptismDate']),
        ),
        _profileRow(
          'Marriage date',
          _formatMemberProfileDate(member['marriageDate']),
          isLast: true,
        ),
      ],
    );
  }

  Widget _profileRow(
    String label,
    String? value, {
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: _T.body(12, color: _C.textSubtle)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value == null || value.isEmpty ? 'Not provided' : value,
                style: _T.body(13, weight: FontWeight.w600, color: _C.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceHistory(String? memberId, bool enabled) {
    if (!enabled || memberId == null) {
      return Text(
        'Attendance history is unavailable for this member.',
        style: _T.body(13, color: _C.textSubtle),
      );
    }

    final requestKey = '$_selectedYear:$memberId';
    final historyFuture = _historyRequests.putIfAbsent(
      requestKey,
      () => _loadMemberAttendanceHistory(
        service: AttendanceService.instance,
        year: _selectedYear,
        memberId: memberId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance history, $_selectedYear', style: _T.label()),
        const SizedBox(height: 10),
        FutureBuilder<List<_MemberAttendanceHistoryEntry>>(
          future: historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  _spinner(color: _C.accent),
                  const SizedBox(width: 10),
                  Text('Loading attendance history…', style: _T.body(13)),
                ],
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              );
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Unable to load attendance history: $error',
                      style: _T.body(13, color: _C.error),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retry attendance history',
                    onPressed: () {
                      setState(() => _historyRequests.remove(requestKey));
                    },
                    icon: const Icon(Icons.refresh_rounded, color: _C.text2),
                  ),
                ],
              );
            }

            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return Text(
                'No recorded attendance weeks for $_selectedYear.',
                style: _T.body(13, color: _C.textSubtle),
              );
            }

            return Column(
              children: history.map((entry) {
                final status = entry.status;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatHistoryDate(entry.date),
                          style: _T.body(13),
                        ),
                      ),
                      _StatusTag(status),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatHistoryDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Member attendance detail
// ---------------------------------------------------------------------------
class MemberAttendanceDetailScreen extends StatefulWidget {
  const MemberAttendanceDetailScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.memberDetails,
    required this.year,
  });

  final String memberId;
  final String memberName;
  final Map<String, dynamic> memberDetails;
  final int year;

  @override
  State<MemberAttendanceDetailScreen> createState() =>
      _MemberAttendanceDetailScreenState();
}

class _MemberAttendanceDetailScreenState
    extends State<MemberAttendanceDetailScreen> {
  final AttendanceService _service = AttendanceService.instance;

  late String _memberName;
  late Map<String, dynamic> _memberDetails;
  late int _selectedYear;
  late int _selectedMonth;
  bool _loading = true;
  bool _editingMember = false;
  String? _error;
  Map<String, String> _statusByDate = {};
  Set<String> _sessionDates = {};

  @override
  void initState() {
    super.initState();
    _memberName = widget.memberName;
    _memberDetails = widget.memberDetails;
    _selectedYear = widget.year;
    _selectedMonth = DateTime.now().month;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await _loadMemberAttendanceHistory(
        service: _service,
        year: _selectedYear,
        memberId: widget.memberId,
      );
      final statusByDate = <String, String>{
        for (final entry in history)
          AttendanceChartData.dateKey(entry.date): entry.status,
      };
      final sessionDates = history
          .map((entry) => AttendanceChartData.dateKey(entry.date))
          .toSet();

      if (!mounted) return;

      setState(() {
        _statusByDate = statusByDate;
        _sessionDates = sessionDates;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _selectYear(int? year) {
    if (year == null || year == _selectedYear) return;
    setState(() => _selectedYear = year);
    _loadHistory();
  }

  Future<void> _editMember() async {
    if (_editingMember) return;
    setState(() => _editingMember = true);

    try {
      final member = await showMemberEditDialog(
        context,
        Member.fromJson(_memberDetails),
      );
      if (member == null || !mounted) return;

      setState(() {
        _memberName = member.name;
        _memberDetails = member.toJson();
      });
    } finally {
      if (mounted) setState(() => _editingMember = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearSundays = AttendanceChartData.sundaysInYear(_selectedYear);
    final yearCounts = AttendanceChartCounts.fromStatuses(
      yearSundays.map(
        (date) => AttendanceChartData.statusForDate(date, _statusByDate),
      ),
    );
    final present = yearCounts.present;
    final absent = yearCounts.absent;
    final unmarked = yearCounts.unmarked;
    final percentage = yearCounts.attendancePercentage;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar(
        'Attendance details',
        actions: [
          IconButton(
            tooltip: 'Edit member',
            onPressed: _editingMember ? null : _editMember,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _C.accent,
                      strokeWidth: 3,
                    ),
                  )
                : _error != null
                ? _errorState(_error!, _loadHistory)
                : RefreshIndicator(
                    color: _C.accent,
                    backgroundColor: _C.surface,
                    onRefresh: _loadHistory,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        _memberHeaderCard(),
                        const SizedBox(height: 16),
                        _yearlyBlock(
                          present: present,
                          absent: absent,
                          unmarked: unmarked,
                          total: yearCounts.total,
                          percentage: percentage,
                        ),
                        const SizedBox(height: 24),
                        _heading('Monthly attendance'),
                        const SizedBox(height: 14),
                        _monthlyChart(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _memberHeaderCard() {
    final phone = _memberDetails['phoneNumber']?.toString().trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _initialsBlock(_memberName, size: 52, font: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _memberName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _T.display(22, height: 1.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final tileWidth = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _infoTile(
                    tileWidth,
                    Icons.phone_rounded,
                    'Phone',
                    phone.isEmpty ? 'Not provided' : phone,
                    onValueTap: phone.isEmpty
                        ? null
                        : () => _copyMemberPhoneNumber(context, phone),
                  ),
                  _infoTile(
                    tileWidth,
                    Icons.cake_rounded,
                    'Date of birth',
                    _formatMemberProfileDate(_memberDetails['dob']),
                  ),
                  _infoTile(
                    tileWidth,
                    Icons.water_drop_rounded,
                    'Baptism',
                    _formatMemberProfileDate(_memberDetails['baptismDate']),
                  ),
                  _infoTile(
                    tileWidth,
                    Icons.favorite_rounded,
                    'Marriage',
                    _formatMemberProfileDate(_memberDetails['marriageDate']),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    double width,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onValueTap,
  }) {
    final missing = value == 'Not provided';

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _C.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.body(
                    11,
                    weight: FontWeight.w600,
                    color: _C.textSubtle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onValueTap,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.body(
                13,
                weight: FontWeight.w600,
                color: missing ? _C.textSubtle : _C.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearlyBlock({
    required int present,
    required int absent,
    required int unmarked,
    required int total,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yearly attendance, $_selectedYear', style: _T.label()),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: _C.border,
                      color: _C.success,
                    ),
                    Center(
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: _T.number(30),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _legendRow(_C.success, 'Present', present),
                    const SizedBox(height: 12),
                    _legendRow(_C.error, 'Absent', absent),
                    const SizedBox(height: 12),
                    _legendRow(_C.textSubtle, 'Unmarked', unmarked),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$total Sundays in $_selectedYear',
                        style: _T.body(12, color: _C.textSubtle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlyChart() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final sundays = AttendanceChartData.sundaysInMonth(
      _selectedYear,
      _selectedMonth,
    );
    final statuses = sundays
        .map((date) => AttendanceChartData.statusForDate(date, _statusByDate))
        .toList();
    final counts = AttendanceChartCounts.fromStatuses(statuses);
    final hasRecords = sundays.any(
      (date) => _sessionDates.contains(AttendanceChartData.dateKey(date)),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _labeled(
                  'Month',
                  _lightDropdown<int>(
                    value: _selectedMonth,
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(months[index]),
                      ),
                    ),
                    onChanged: (month) {
                      if (month != null) {
                        setState(() => _selectedMonth = month);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 112, child: _labeled('Year', _yearField())),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _chartLegend(_C.success, 'Present'),
              _chartLegend(_C.error, 'Absent'),
              _chartLegend(_C.textSubtle, 'Unmarked'),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasRecords)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'No attendance records for this month. Sundays are shown as '
                'unmarked.',
                style: _T.body(13, color: _C.textSubtle, height: 1.4),
              ),
            ),
          if (sundays.isEmpty)
            Text('There are no Sundays in this month.', style: _T.body(14))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(sundays.length, (index) {
                final date = sundays[index];
                final status = statuses[index];

                return Expanded(
                  child: Tooltip(
                    message:
                        'Week ${index + 1} · '
                        '${months[_selectedMonth - 1]} ${date.day}: '
                        '${_stateLabel(status)}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Week ${index + 1}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.body(
                              12,
                              weight: FontWeight.w700,
                              color: _C.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            textAlign: TextAlign.center,
                            style: _T.body(12, color: _C.textSubtle),
                          ),
                          const SizedBox(height: 8),
                          _chartBar(status),
                          const SizedBox(height: 8),
                          Text(
                            _stateLabel(status),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.body(
                              11,
                              weight: FontWeight.w600,
                              color: _stateColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: 22),
          _statistics(counts, percentage: counts.attendancePercentage),
        ],
      ),
    );
  }

  // The icon inside each bar means state never depends on color alone.
  Widget _chartBar(String status) {
    final normalized = status.toLowerCase();
    final isUnmarked = normalized != 'present' && normalized != 'absent';

    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isUnmarked ? _C.border : _stateColor(normalized),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _stateIcon(normalized),
        size: 22,
        color: isUnmarked ? _C.text2 : _C.ink,
      ),
    );
  }

  Widget _yearField() {
    return _lightDropdown<int>(
      value: _selectedYear,
      items: List.generate(101, (index) => 2000 + index)
          .map(
            (year) => DropdownMenuItem<int>(value: year, child: Text('$year')),
          )
          .toList(),
      onChanged: _loading ? null : _selectYear,
    );
  }

  Widget _statistics(
    AttendanceChartCounts counts, {
    required double percentage,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statistic('Sundays', '${counts.total}'),
        _statistic('Present', '${counts.present}', color: _C.success),
        _statistic('Absent', '${counts.absent}', color: _C.error),
        _statistic('Unmarked', '${counts.unmarked}'),
        _statistic('Attendance', '${percentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _statistic(String label, String value, {Color color = _C.text}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: _T.number(20, color: color)),
          const SizedBox(height: 6),
          Text(
            label,
            style: _T.body(12, weight: FontWeight.w600, color: _C.textSubtle),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: _T.body(13, color: _C.text2)),
      ],
    );
  }

  Widget _legendRow(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: _T.body(14, weight: FontWeight.w600, color: _C.text2),
          ),
        ),
        Text('$value', style: _T.number(18)),
      ],
    );
  }
}
