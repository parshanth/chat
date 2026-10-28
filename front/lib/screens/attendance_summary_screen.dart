import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../services/attendance_service.dart';
import '../services/attendance_report_service.dart';
import '../services/member_service.dart';
import '../utils/attendance_chart_data.dart';
import 'members_screen.dart';

part 'attendance_details_screen.dart';

// ---------------------------------------------------------------------------
// Design tokens. Same values as the Add Attendance screen; move both copies
// into the shared theme file when you are ready to unify them.
// ---------------------------------------------------------------------------
class _C {
  static const bg = Color(0xFF101511);
  static const bg2 = Color(0xFF171E18);
  static const surface = Color(0xFF202922);
  static const elevated = Color(0xFF29342B);
  static const text = Color(0xFFF5F4EC);
  static const text2 = Color(0xFFA8B4A8);
  static const textSubtle = Color(0xFF849184);
  static const border = Color(0xFF354237);
  static const accent = Color(0xFFD6F078);
  static const inputBg = Color(0xFFF4F3ED);
  static const inputText = Color(0xFF172016);
  static const inputHint = Color(0xFF687368);
  static const inputIcon = Color(0xFF455349);
  static const inputBorder = Color(0xFFD7DED6);
  static const inputFocus = Color(0xFF527B45);
  static const error = Color(0xFFFF8585);
  static const success = Color(0xFF75D99A);
  static const ink = Color(0xFF101511);
}

class _T {
  static const _display = 'Manrope';
  static const _body = 'DMSans';

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = _C.text,
    double? height,
    double letterSpacing = -0.4,
  }) => TextStyle(
    fontFamily: _display,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle number(double size, {Color color = _C.text}) => TextStyle(
    fontFamily: _display,
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1,
    letterSpacing: -1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _C.text2,
    double? height,
  }) => TextStyle(
    fontFamily: _body,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle label({Color color = _C.text2}) => TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.2,
  );
}

// ---------------------------------------------------------------------------
// Shared helpers (also used by attendance_details_screen.dart)
// ---------------------------------------------------------------------------
Color _stateColor(String status) {
  switch (status.toLowerCase()) {
    case 'present':
      return _C.success;
    case 'absent':
      return _C.error;
    default:
      return _C.textSubtle;
  }
}

String _stateLabel(String status) {
  switch (status.toLowerCase()) {
    case 'present':
      return 'Present';
    case 'absent':
      return 'Absent';
    default:
      return 'Unmarked';
  }
}

IconData _stateIcon(String status) {
  switch (status.toLowerCase()) {
    case 'present':
      return Icons.check_rounded;
    case 'absent':
      return Icons.close_rounded;
    default:
      return Icons.remove_rounded;
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

PreferredSizeWidget _appBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: _C.bg,
    surfaceTintColor: Colors.transparent,
    foregroundColor: _C.text,
    elevation: 0,
    scrolledUnderElevation: 0,
    title: Text(title, style: _T.display(17)),
    actions: [...?actions, const SizedBox(width: 8)],
  );
}

Widget _heading(String title) => Text(title, style: _T.display(22));

Widget _labeled(String label, Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _T.label()),
      const SizedBox(height: 8),
      child,
    ],
  );
}

/// Warm-white dropdown that stays readable in both the field and the menu.
Widget _lightDropdown<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?>? onChanged,
  String? hint,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: onChanged == null ? _C.inputBg.withValues(alpha: 0.6) : _C.inputBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.inputBorder),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        value: value,
        hint: hint == null
            ? null
            : Text(hint, style: _T.body(15, color: _C.inputHint)),
        items: items,
        onChanged: onChanged,
        dropdownColor: _C.inputBg,
        borderRadius: BorderRadius.circular(12),
        iconEnabledColor: _C.inputIcon,
        iconDisabledColor: _C.inputIcon.withValues(alpha: 0.5),
        style: _T.body(15, weight: FontWeight.w600, color: _C.inputText),
      ),
    ),
  );
}

Widget _spinner({Color color = _C.ink}) => SizedBox(
  width: 18,
  height: 18,
  child: CircularProgressIndicator(strokeWidth: 2, color: color),
);

Widget _initialsBlock(String name, {double size = 44, double font = 16}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _C.elevated,
      borderRadius: BorderRadius.circular(size * 0.22),
      border: Border.all(color: _C.border),
    ),
    child: Text(_initials(name), style: _T.display(font, letterSpacing: 0.4)),
  );
}

Widget _loadingState() => const Padding(
  padding: EdgeInsets.all(28),
  child: Center(
    child: CircularProgressIndicator(color: _C.accent, strokeWidth: 3),
  ),
);

Widget _errorState(String message, VoidCallback onRetry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: _C.error),
            const SizedBox(height: 16),
            Text('Something went wrong', style: _T.display(26)),
            const SizedBox(height: 8),
            Text(message, style: _T.body(15, height: 1.4)),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              style: _accentButton(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}

ButtonStyle _accentButton() => FilledButton.styleFrom(
  backgroundColor: _C.accent,
  foregroundColor: _C.ink,
  disabledBackgroundColor: _C.accent.withValues(alpha: 0.3),
  disabledForegroundColor: _C.ink.withValues(alpha: 0.5),
  minimumSize: const Size(0, 52),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  textStyle: _T.display(15, letterSpacing: 0),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle _quietButton() => FilledButton.styleFrom(
  backgroundColor: _C.elevated,
  foregroundColor: _C.text,
  disabledBackgroundColor: _C.elevated.withValues(alpha: 0.5),
  disabledForegroundColor: _C.textSubtle,
  minimumSize: const Size(0, 52),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  textStyle: _T.display(15, letterSpacing: 0),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: _C.border),
  ),
);

ButtonStyle _outlineButton() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  disabledForegroundColor: _C.textSubtle,
  side: const BorderSide(color: _C.border, width: 1.4),
  minimumSize: const Size(0, 52),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  textStyle: _T.display(15, letterSpacing: 0),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

/// Three-column count strip: explicit label + large numeral per state.
Widget _statStrip(int present, int absent, int unmarked) {
  Widget cell(String label, int value, Color color) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: _T.number(label == 'Present' ? 34 : 30, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.body(12, weight: FontWeight.w600, color: _C.textSubtle),
          ),
        ],
      ),
    ),
  );

  return Container(
    decoration: BoxDecoration(
      color: _C.bg2,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          cell('Present', present, _C.success),
          const VerticalDivider(width: 1, color: _C.border),
          cell('Absent', absent, _C.error),
          const VerticalDivider(width: 1, color: _C.border),
          cell('Unmarked', unmarked, _C.text2),
        ],
      ),
    ),
  );
}

class _StatusTag extends StatelessWidget {
  const _StatusTag(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_stateIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _stateLabel(status),
            style: _T.body(12, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary-screen domain helpers
// ---------------------------------------------------------------------------

typedef _Json = Map<String, dynamic>;

/// Display name for a member map coming from the API.
String _summaryMemberName(_Json member) {
  final value =
      (member['fullName'] ?? member['name'] ?? member['firstName'] ?? '')
          .toString()
          .trim();
  return value.isEmpty ? 'Unnamed member' : value;
}

String? _summaryMemberId(_Json member) {
  final value = (member['_id'] ?? member['id'] ?? member['memberId'])
      ?.toString()
      .trim();
  return value == null || value.isEmpty ? null : value;
}

const _shortMonths = [
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

const _longMonths = [
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

String _summaryFormatDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
}

/// Members of one week, bucketed by status once instead of on every build.
class _WeekStats {
  const _WeekStats._({
    required this.present,
    required this.absent,
    required this.unmarked,
  });

  static const empty = _WeekStats._(present: [], absent: [], unmarked: []);

  factory _WeekStats.from(List<_Json> members) {
    final present = <_Json>[];
    final absent = <_Json>[];
    final unmarked = <_Json>[];

    for (final member in members) {
      switch (member['status']?.toString().trim().toLowerCase()) {
        case 'present':
          present.add(member);
        case 'absent':
          absent.add(member);
        default:
          unmarked.add(member);
      }
    }

    int byName(_Json a, _Json b) => _summaryMemberName(
      a,
    ).toLowerCase().compareTo(_summaryMemberName(b).toLowerCase());
    present.sort(byName);
    absent.sort(byName);

    return _WeekStats._(present: present, absent: absent, unmarked: unmarked);
  }

  final List<_Json> present;
  final List<_Json> absent;
  final List<_Json> unmarked;

  int get total => present.length + absent.length + unmarked.length;
}

// ---------------------------------------------------------------------------
// Attendance summary
// ---------------------------------------------------------------------------
class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  final AttendanceService _service = AttendanceService.instance;
  final AttendanceReportService _reportService = AttendanceReportService();

  late int _selectedYear;
  bool _loadingSummary = false;
  bool _loadingWeek = false;
  String? _reportInProgress; // 'weekly' | 'monthly' | null

  String? _error;
  String? _weekError;

  List<_Json> _records = [];
  _WeekStats _stats = _WeekStats.empty;

  String? _selectedDate;
  int? _selectedWeekNumber;
  int _weekRequestId = 0;

  bool get _generatingReport => _reportInProgress != null;

  int? get _displayedWeekNumber {
    if (_selectedWeekNumber != null) return _selectedWeekNumber;
    final selectedDate = _selectedDate;
    if (selectedDate == null) return null;

    for (final record in _records) {
      if (record['date']?.toString() == selectedDate) {
        return int.tryParse(record['weekNumber']?.toString() ?? '');
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadSummary();
  }

  // ---- Data ---------------------------------------------------------------

  Future<void> _loadSummary() async {
    _weekRequestId++;
    setState(() {
      _loadingSummary = true;
      _loadingWeek = false;
      _error = null;
      _weekError = null;
      _records = [];
      _selectedDate = null;
      _selectedWeekNumber = null;
      _stats = _WeekStats.empty;
    });

    try {
      final result = await _service.getAttendanceSummary(year: _selectedYear);
      final data = _Json.from(result['data'] as Map);
      final records =
          (data['records'] as List<dynamic>? ?? [])
              .map((item) => _Json.from(item as Map))
              .toList()
            ..sort(
              (a, b) => (b['date']?.toString() ?? '').compareTo(
                a['date']?.toString() ?? '',
              ),
            );

      if (!mounted) return;

      setState(() {
        _records = records;
        _selectedDate = records.isNotEmpty
            ? records.first['date']?.toString()
            : null;
        _loadingSummary = false;
      });

      if (_selectedDate != null) await _loadWeek(_selectedDate!);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _loadingSummary = false;
      });
    }
  }

  Future<void> _loadWeek(String date) async {
    final requestId = ++_weekRequestId;
    setState(() {
      _loadingWeek = true;
      _weekError = null;
      _stats = _WeekStats.empty;
      _selectedWeekNumber = null;
    });

    try {
      final result = await _service.getAttendance(date);
      final data = _Json.from(result['data'] as Map);
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((item) => _Json.from(item as Map))
          .toList();
      final weekNumber = int.tryParse(data['weekNumber']?.toString() ?? '');

      if (!mounted || requestId != _weekRequestId) return;

      setState(() {
        _stats = _WeekStats.from(members);
        _selectedWeekNumber = weekNumber;
        _loadingWeek = false;
      });
    } catch (error) {
      if (!mounted || requestId != _weekRequestId) return;
      setState(() {
        _weekError = _message(error);
        _loadingWeek = false;
      });
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  // ---- Actions ------------------------------------------------------------

  void _openMemberAttendanceDetails(_Json member) {
    final memberId = _summaryMemberId(member);
    if (memberId == null) {
      _toast('Attendance details are unavailable for this member.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberAttendanceDetailScreen(
          memberId: memberId,
          memberName: _summaryMemberName(member),
          memberDetails: member,
          year: _selectedYear,
        ),
      ),
    );
  }

  Future<void> _copyPhoneNumber(String phone) async {
    try {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) _toast('Phone number copied.');
    } catch (error) {
      if (mounted) _toast('Unable to copy the phone number.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _C.elevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _C.border),
          ),
          content: Text(
            message,
            style: _T.body(14, weight: FontWeight.w500, color: _C.text),
          ),
        ),
      );
  }

  Future<void> _runReport({
    required String kind,
    required String label,
    required Future<ReportShareOutcome> Function() task,
  }) async {
    if (_generatingReport) return;
    setState(() => _reportInProgress = kind);

    try {
      final outcome = await task();
      if (!mounted) return;
      _toast(switch (outcome) {
        ReportShareOutcome.shared => '$label Excel report is ready to share.',
        ReportShareOutcome.dismissed => 'Report sharing was cancelled.',
        ReportShareOutcome.unavailable =>
          'The share sheet is unavailable on this device.',
      });
    } catch (error) {
      if (!mounted) return;
      _toast(
        error
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('FormatException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _reportInProgress = null);
    }
  }

  Future<void> _downloadWeeklyReport() {
    final date = _selectedDate;
    if (date == null) return Future.value();
    return _runReport(
      kind: 'weekly',
      label: 'Weekly',
      task: () => _reportService.shareWeeklyReport(date: date),
    );
  }

  Future<void> _downloadMonthlyReport(int month) {
    final year = _selectedYear;
    return _runReport(
      kind: 'monthly',
      label: 'Monthly',
      task: () => _reportService.shareMonthlyReport(year: year, month: month),
    );
  }

  Future<void> _chooseMonthForExport() async {
    if (_generatingReport) return;
    var month = DateTime.now().month;

    final chosen = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _C.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _C.border),
          ),
          title: Text('Choose report month', style: _T.display(20)),
          content: _labeled(
            'Month',
            _lightDropdown<int>(
              value: month,
              items: [
                for (var i = 0; i < 12; i++)
                  DropdownMenuItem<int>(
                    value: i + 1,
                    child: Text(_longMonths[i]),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setDialogState(() => month = value);
              },
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _C.text2,
                textStyle: _T.body(15, weight: FontWeight.w700),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: _accentButton().copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
              ),
              onPressed: () => Navigator.pop(dialogContext, month),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );

    if (chosen != null && mounted) await _downloadMonthlyReport(chosen);
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar(
        'Attendance summary',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingSummary ? null : _loadSummary,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: RefreshIndicator(
              color: _C.accent,
              backgroundColor: _C.surface,
              onRefresh: _loadSummary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Text(
                    'Attendance summary',
                    style: _T.display(34, height: 1.05, letterSpacing: -1),
                  ),
                  const SizedBox(height: 24),
                  _filtersCard(),
                  const SizedBox(height: 28),
                  _weekSection(),
                  const SizedBox(height: 32),
                  _reportsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Filters ------------------------------------------------------------

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          _labeled('Attendance year', _yearField()),
          const SizedBox(height: 16),
          _labeled('Recorded week', _weekSelector()),
        ],
      ),
    );
  }

  Widget _yearField() {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (i) => currentYear - 5 + i);

    return _lightDropdown<int>(
      value: years.contains(_selectedYear) ? _selectedYear : currentYear,
      items: [
        for (final year in years)
          DropdownMenuItem<int>(value: year, child: Text('$year')),
      ],
      onChanged: _loadingSummary
          ? null
          : (year) {
              if (year == null) return;
              setState(() => _selectedYear = year);
              _loadSummary();
            },
    );
  }

  Widget _weekSelector() {
    final hint = _loadingSummary
        ? 'Loading weeks...'
        : _error != null
        ? 'Could not load weeks'
        : _records.isEmpty
        ? 'No weeks recorded for $_selectedYear'
        : 'Choose a recorded week';

    final validDates = _records.map((r) => r['date']?.toString() ?? '').toSet();
    final enabled = !_loadingSummary && _records.isNotEmpty;

    return _lightDropdown<String>(
      value: validDates.contains(_selectedDate) ? _selectedDate : null,
      hint: hint,
      items: [
        for (final record in _records)
          DropdownMenuItem<String>(
            value: record['date']?.toString() ?? '',
            child: Text(
              'Week ${record['weekNumber'] ?? '—'} · '
              '${_summaryFormatDate(record['date']?.toString() ?? '')}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: enabled
          ? (date) {
              if (date == null) return;
              setState(() => _selectedDate = date);
              _loadWeek(date);
            }
          : null,
    );
  }

  // ---- Week content (single state gate) -----------------------------------

  Widget _weekSection() {
    if (_loadingSummary || _loadingWeek) return _loadingState();

    if (_error != null) {
      return _InfoCard(
        message: _error!,
        icon: Icons.cloud_off_rounded,
        iconColor: _C.error,
        actionLabel: 'Retry',
        onAction: _loadSummary,
      );
    }

    final date = _selectedDate;

    if (_weekError != null) {
      return _InfoCard(
        message: _weekError!,
        icon: Icons.cloud_off_rounded,
        iconColor: _C.error,
        actionLabel: date == null ? null : 'Retry',
        onAction: date == null ? null : () => _loadWeek(date),
      );
    }

    if (date == null || _records.isEmpty) {
      return const _InfoCard(
        message: 'Select a recorded week to see who attended.',
        icon: Icons.event_busy_rounded,
      );
    }

    final week = _displayedWeekNumber;
    final weekLabel = week == null ? 'Selected week' : 'Week $week';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statStrip(
          _stats.present.length,
          _stats.absent.length,
          _stats.unmarked.length,
        ),
        const SizedBox(height: 32),
        _SectionHeader(
          title: 'Absentees',
          count: _stats.absent.length,
          color: _C.error,
        ),
        const SizedBox(height: 14),
        if (_stats.absent.isEmpty)
          _InfoCard(
            message: 'No absentees for $weekLabel.',
            icon: Icons.check_circle_outline_rounded,
            iconColor: _C.success,
          )
        else
          for (final member in _stats.absent) ...[
            _AbsenteeTile(
              member: member,
              name: _summaryMemberName(member),
              phone: member['phoneNumber']?.toString().trim() ?? '',
              onOpen: _openMemberAttendanceDetails,
              onCopyPhone: _copyPhoneNumber,
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 22),
        _PresentSection(
          key: ValueKey('present-$date'),
          members: _stats.present.map(_summaryMemberName).toList(),
        ),
      ],
    );
  }

  // ---- Reports ------------------------------------------------------------

  Widget _reportsCard() {
    final weeklyBusy = _reportInProgress == 'weekly';
    final monthlyBusy = _reportInProgress == 'monthly';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading('Download reports'),
          const SizedBox(height: 6),
          Text(
            'Export attendance to Excel for a selected week or month.',
            style: _T.body(15, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: _accentButton(),
              onPressed:
                  _selectedDate == null || _loadingWeek || _generatingReport
                  ? null
                  : _downloadWeeklyReport,
              icon: weeklyBusy
                  ? _spinner()
                  : const Icon(Icons.download_rounded),
              label: Text(
                weeklyBusy
                    ? 'Preparing weekly report...'
                    : 'Download weekly Excel report',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: _outlineButton(),
              onPressed: _loadingSummary || _generatingReport
                  ? null
                  : _chooseMonthForExport,
              icon: monthlyBusy
                  ? _spinner(color: _C.accent)
                  : const Icon(Icons.calendar_month_rounded),
              label: Text(
                monthlyBusy
                    ? 'Preparing monthly report...'
                    : 'Download monthly Excel report',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Presentational widgets
// ---------------------------------------------------------------------------

/// Title with a coloured count pill.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _heading(title),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: _T.body(13, weight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }
}

/// Absentee row: red-tinted so it reads as "absent" at a glance.
class _AbsenteeTile extends StatelessWidget {
  const _AbsenteeTile({
    required this.member,
    required this.name,
    required this.phone,
    required this.onOpen,
    required this.onCopyPhone,
  });

  final _Json member;
  final String name;
  final String phone;
  final ValueChanged<_Json> onOpen;
  final ValueChanged<String> onCopyPhone;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Semantics(
      button: true,
      label: 'View attendance details for $name',
      child: Material(
        color: Color.alphaBlend(_C.error.withValues(alpha: 0.07), _C.surface),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: _C.error.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onOpen(member),
          splashColor: _C.error.withValues(alpha: 0.12),
          highlightColor: _C.error.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _avatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _T.body(
                          16,
                          weight: FontWeight.w700,
                          color: _C.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone.isEmpty ? 'No phone number' : phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _T.body(
                          13,
                          color: phone.isEmpty ? _C.textSubtle : _C.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (phone.isNotEmpty)
                  IconButton(
                    tooltip: 'Copy phone number',
                    onPressed: () => onCopyPhone(phone),
                    color: _C.text2,
                    icon: const Icon(Icons.copy_rounded),
                  ),
                const _StatusTag('absent'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _C.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        _initials(name),
        style: _T.display(16, color: _C.error, letterSpacing: 0.4),
      ),
    );
  }
}

/// Collapsible roster of present members shown as compact chips.
class _PresentSection extends StatefulWidget {
  const _PresentSection({super.key, required this.members});

  final List<String> members;

  @override
  State<_PresentSection> createState() => _PresentSectionState();
}

class _PresentSectionState extends State<_PresentSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final members = widget.members;
    final canExpand = members.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: canExpand
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _C.success.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_rounded, color: _C.success),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Present', style: _T.display(17)),
                        const SizedBox(height: 3),
                        Text(
                          members.isEmpty
                              ? 'No one marked present'
                              : '${members.length} '
                                    '${members.length == 1 ? 'member' : 'members'}',
                          style: _T.body(13, color: _C.textSubtle),
                        ),
                      ],
                    ),
                  ),
                  if (canExpand)
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _C.text2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded && canExpand
                ? Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _C.border)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in members) _PresentChip(name: name),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _PresentChip extends StatelessWidget {
  const _PresentChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: _C.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _C.success.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.success.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: _T.display(10, color: _C.success, letterSpacing: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.body(13, weight: FontWeight.w600, color: _C.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty / error / info message with an optional action.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.message,
    required this.icon,
    this.iconColor = _C.text2,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: iconColor),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _T.body(14, color: _C.text, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _C.accent,
                textStyle: _T.body(14, weight: FontWeight.w700),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
