import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../services/attendance_report_service.dart';
import '../services/member_service.dart';
import '../utils/attendance_chart_data.dart';

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
  }) =>
      TextStyle(
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
  }) =>
      TextStyle(
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
// Shared helpers
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
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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
      color: onChanged == null
          ? _C.inputBg.withValues(alpha: 0.6)
          : _C.inputBg,
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
              Text('$value', style: _T.number(30, color: color)),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _T.body(
                  12,
                  weight: FontWeight.w600,
                  color: _C.textSubtle,
                ),
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
  bool _generatingReport = false;
  String? _reportInProgress;

  String? _error;
  String? _weekError;

  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _weeklyMembers = [];

  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _error = null;
      _weekError = null;
      _records = [];
      _selectedDate = null;
      _weeklyMembers = [];
    });

    try {
      final result = await _service.getAttendanceSummary(year: _selectedYear);
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final records =
          (data['records'] as List<dynamic>? ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map))
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

      if (_selectedDate != null) {
        await _loadWeek(_selectedDate!);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _message(error);
        _loadingSummary = false;
      });
    }
  }

  Future<void> _loadWeek(String date) async {
    setState(() {
      _loadingWeek = true;
      _weekError = null;
      _weeklyMembers = [];
    });

    try {
      final result = await _service.getAttendance(date);
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final rawMembers = data['members'] as List<dynamic>? ?? [];

      final weeklyMembers = rawMembers
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _weeklyMembers = weeklyMembers;
        _loadingWeek = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _weekError = _message(error);
        _loadingWeek = false;
      });
    }
  }

  String _memberName(Map<String, dynamic> member) {
    final value =
        (member['fullName'] ?? member['name'] ?? member['firstName'] ?? '')
            .toString()
            .trim();

    return value.isEmpty ? 'Unnamed member' : value;
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

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

  int _countStatus(String status) {
    return _weeklyMembers.where((member) {
      return (member['status']?.toString().toLowerCase() ?? 'unmarked') ==
          status;
    }).length;
  }

  int get _presentCount => _countStatus('present');

  int get _absentCount => _countStatus('absent');

  int get _unmarkedCount => _countStatus('unmarked');

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'Attendance summary',
                    style: _T.display(34, height: 1.05, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review any recorded Sunday, open a member’s history or '
                    'export a report.',
                    style: _T.body(15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  _labeled('Attendance year', _yearField()),
                  const SizedBox(height: 16),
                  _labeled('Recorded week', _weekSelector()),
                  const SizedBox(height: 32),
                  _heading('Weekly attendance'),
                  const SizedBox(height: 14),
                  _statStrip(_presentCount, _absentCount, _unmarkedCount),
                  const SizedBox(height: 14),
                  _weeklyAttendanceTable(),
                  const SizedBox(height: 32),
                  _memberHistoryBlock(),
                  const SizedBox(height: 32),
                  _reportsBlock(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _yearField() {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (index) => currentYear - 5 + index);

    return _lightDropdown<int>(
      value: years.contains(_selectedYear) ? _selectedYear : currentYear,
      items: years
          .map(
            (year) => DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            ),
          )
          .toList(),
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
    if (_loadingSummary && _records.isEmpty) {
      return _loadingState();
    }

    if (_error != null) {
      return _messageCard(
        _error!,
        icon: Icons.cloud_off_rounded,
        iconColor: _C.error,
        actionLabel: 'Retry',
        onAction: _loadSummary,
      );
    }

    if (_records.isEmpty) {
      return _messageCard(
        'No attendance weeks found for $_selectedYear.',
        icon: Icons.event_busy_rounded,
      );
    }

    final validDates = _records
        .map((record) => record['date']?.toString() ?? '')
        .toSet();

    return _lightDropdown<String>(
      value: validDates.contains(_selectedDate) ? _selectedDate : null,
      hint: 'Choose a recorded week',
      items: _records.map((record) {
        final date = record['date']?.toString() ?? '';
        final week = record['weekNumber']?.toString() ?? '—';

        return DropdownMenuItem<String>(
          value: date,
          child: Text(
            'Week $week · ${_formatDate(date)}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (date) {
        if (date == null) return;

        setState(() => _selectedDate = date);
        _loadWeek(date);
      },
    );
  }

  Widget _weeklyAttendanceTable() {
    if (_loadingWeek) {
      return _loadingState();
    }

    if (_weekError != null) {
      return _messageCard(
        _weekError!,
        icon: Icons.cloud_off_rounded,
        iconColor: _C.error,
        actionLabel: 'Retry',
        onAction: _selectedDate == null
            ? null
            : () => _loadWeek(_selectedDate!),
      );
    }

    if (_selectedDate == null || _records.isEmpty) {
      return _messageCard(
        'Select a year with recorded attendance to view the weekly table.',
        icon: Icons.table_chart_outlined,
      );
    }

    if (_weeklyMembers.isEmpty) {
      return _messageCard(
        'No members were returned for this attendance date.',
        icon: Icons.people_outline_rounded,
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(_selectedDate!),
                    style: _T.display(18),
                  ),
                ),
                Text('${_weeklyMembers.length} members', style: _T.body(13)),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),
          Container(
            color: _C.bg2,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('Member name', style: _T.label())),
                Text('Attendance', style: _T.label()),
              ],
            ),
          ),
          for (int i = 0; i < _weeklyMembers.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.border),
            _weeklyRow(_weeklyMembers[i]),
          ],
        ],
      ),
    );
  }

  Widget _weeklyRow(Map<String, dynamic> member) {
    final name = _memberName(member);
    final status =
        (member['status']?.toString() ?? 'unmarked').toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.body(15, weight: FontWeight.w600, color: _C.text),
            ),
          ),
          const SizedBox(width: 12),
          _StatusTag(status),
        ],
      ),
    );
  }

  Widget _memberHistoryBlock() {
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
          _heading('Member history'),
          const SizedBox(height: 6),
          Text(
            'Browse members and view their attendance charts.',
            style: _T.body(15, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: _accentButton(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        MemberHistoryScreen(initialYear: _selectedYear),
                  ),
                );
              },
              icon: const Icon(Icons.people_outline_rounded),
              label: const Text('View all members'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Download reports'),
        const SizedBox(height: 6),
        Text(
          'Export attendance to Excel for a selected week or month.',
          style: _T.body(15, height: 1.4),
        ),
        const SizedBox(height: 16),
        _downloadButtons(),
      ],
    );
  }

  Widget _downloadButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: _quietButton(),
            onPressed:
                _selectedDate == null || _loadingWeek || _generatingReport
                ? null
                : _downloadWeeklyReport,
            icon: _reportInProgress == 'weekly'
                ? _spinner(color: _C.accent)
                : const Icon(Icons.download_rounded),
            label: Text(
              _reportInProgress == 'weekly'
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
            icon: _reportInProgress == 'monthly'
                ? _spinner(color: _C.accent)
                : const Icon(Icons.calendar_month_rounded),
            label: Text(
              _reportInProgress == 'monthly'
                  ? 'Preparing monthly report...'
                  : 'Download monthly Excel report',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseMonthForExport() async {
    if (_generatingReport) return;
    int month = DateTime.now().month;

    final chosen = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _C.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _C.border),
          ),
          title: Text('Choose report month', style: _T.display(20)),
          content: _labeled(
            'Month',
            _lightDropdown<int>(
              value: month,
              items: List.generate(
                12,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(_monthName(index + 1)),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => month = value);
                }
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

    if (chosen != null && mounted) {
      await _downloadMonthlyReport(chosen);
    }
  }

  Future<void> _downloadWeeklyReport() async {
    final date = _selectedDate;
    if (date == null || _generatingReport) return;

    setState(() {
      _generatingReport = true;
      _reportInProgress = 'weekly';
    });
    try {
      final outcome = await _reportService.shareWeeklyReport(date: date);
      if (!mounted) return;
      _showReportOutcome(outcome, 'Weekly');
    } catch (error) {
      if (!mounted) return;
      _showReportError(error);
    } finally {
      if (mounted) {
        setState(() {
          _generatingReport = false;
          _reportInProgress = null;
        });
      }
    }
  }

  Future<void> _downloadMonthlyReport(int month) async {
    if (_generatingReport) return;
    final year = _selectedYear;

    setState(() {
      _generatingReport = true;
      _reportInProgress = 'monthly';
    });
    try {
      final outcome = await _reportService.shareMonthlyReport(
        year: year,
        month: month,
      );
      if (!mounted) return;
      _showReportOutcome(outcome, 'Monthly');
    } catch (error) {
      if (!mounted) return;
      _showReportError(error);
    } finally {
      if (mounted) {
        setState(() {
          _generatingReport = false;
          _reportInProgress = null;
        });
      }
    }
  }

  void _showReportOutcome(ReportShareOutcome outcome, String reportType) {
    final message = switch (outcome) {
      ReportShareOutcome.shared =>
        '$reportType Excel report is ready to share.',
      ReportShareOutcome.dismissed => 'Report sharing was cancelled.',
      ReportShareOutcome.unavailable =>
        'The share sheet is unavailable on this device.',
    };
    _showReportMessage(message);
  }

  void _showReportError(Object error) {
    _showReportMessage(
      error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', ''),
    );
  }

  void _showReportMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _messageCard(
    String message, {
    required IconData icon,
    Color iconColor = _C.text2,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(12),
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
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }
}

// ---------------------------------------------------------------------------
// Member history list
// ---------------------------------------------------------------------------
class MemberHistoryScreen extends StatefulWidget {
  const MemberHistoryScreen({super.key, required this.initialYear});

  final int initialYear;

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  final MemberService _memberService = MemberService();

  bool _loading = true;
  String? _error;
  String _search = '';
  late int _selectedYear;
  List<Map<String, dynamic>> _members = [];

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

        if (allMembers.isEmpty) {
          _error =
              'The server returned zero members. Check the members API '
              'response and confirm that members exist.';
        }
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
            (year) => DropdownMenuItem<int>(
              value: year,
              child: Text('$year'),
            ),
          )
          .toList(),
      onChanged: (year) {
        if (year != null) {
          setState(() => _selectedYear = year);
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
                      year: _selectedYear,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
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
        ),
      ),
    );
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
    required this.year,
  });

  final String memberId;
  final String memberName;
  final int year;

  @override
  State<MemberAttendanceDetailScreen> createState() =>
      _MemberAttendanceDetailScreenState();
}

class _MemberAttendanceDetailScreenState
    extends State<MemberAttendanceDetailScreen> {
  final AttendanceService _service = AttendanceService.instance;

  late int _selectedYear;
  late int _selectedMonth;
  bool _loading = true;
  String? _error;
  Map<String, String> _statusByDate = {};
  Set<String> _sessionDates = {};

  @override
  void initState() {
    super.initState();
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
      final result = await _service.getAttendanceSummary(
        year: _selectedYear,
        memberId: widget.memberId,
        includeMemberStatus: true,
      );
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final statusByDate = <String, String>{};
      final sessionDates = <String>{};

      for (final item in data['records'] as List<dynamic>? ?? []) {
        if (item is! Map) continue;
        final session = Map<String, dynamic>.from(item);
        final date = session['date']?.toString();
        final parsedDate = date == null ? null : DateTime.tryParse(date);
        if (parsedDate == null ||
            parsedDate.year != _selectedYear ||
            parsedDate.weekday != DateTime.sunday) {
          continue;
        }

        final key = AttendanceChartData.dateKey(parsedDate);
        sessionDates.add(key);
        statusByDate[key] = session['memberStatus']?.toString() ?? 'unmarked';
      }

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
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
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
                        Row(
                          children: [
                            _initialsBlock(
                              widget.memberName,
                              size: 64,
                              font: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.memberName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _T.display(28, height: 1.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _yearlyBlock(
                          present: present,
                          absent: absent,
                          unmarked: unmarked,
                          total: yearCounts.total,
                          percentage: percentage,
                        ),
                        const SizedBox(height: 32),
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
