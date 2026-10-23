import 'package:flutter/material.dart';

import '../services/attendance_service.dart';

/// Design tokens for this screen. If the app already has a shared theme file,
/// these can be moved there unchanged.
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
  static const accent2 = Color(0xFF75C6A0);
  static const inputBg = Color(0xFFF4F3ED);
  static const inputText = Color(0xFF172016);
  static const inputHint = Color(0xFF687368);
  static const inputIcon = Color(0xFF455349);
  static const inputBorder = Color(0xFFD7DED6);
  static const error = Color(0xFFFF8585);
  static const success = Color(0xFF75D99A);
  static const ink = Color(0xFF101511); // dark text on light/accent fills
}

/// Type system: Manrope for display and numerals, DM Sans for body text.
/// Declare both families in pubspec.yaml (see report). If a family is not
/// bundled, Flutter falls back to the platform font without errors.
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

  static TextStyle number(
    double size, {
    Color color = _C.text,
    FontWeight weight = FontWeight.w800,
  }) =>
      TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: weight,
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
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle label({Color color = _C.text2}) => TextStyle(
        fontFamily: _body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );
}

class AddAttendanceScreen extends StatefulWidget {
  const AddAttendanceScreen({super.key});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _service = AttendanceService.instance;

  DateTime _selectedDate = _nextSunday(DateTime.now());
  List<Map<String, dynamic>> _members = [];

  int _currentIndex = 0;
  bool _loading = false;
  bool _saving = false;
  bool _showSuccess = false;
  String? _error;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  static DateTime _nextSunday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.add(Duration(days: (DateTime.sunday - day.weekday) % 7));
  }

  String get _dateString {
    final year = _selectedDate.year.toString().padLeft(4, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<int> get _unmarkedIndices => [
        for (int i = 0; i < _members.length; i++)
          if (_members[i]['status'] == 'unmarked') i,
      ];

  int get _presentCount =>
      _members.where((m) => m['status'] == 'present').length;

  int get _absentCount =>
      _members.where((m) => m['status'] == 'absent').length;

  int get _completedCount => _presentCount + _absentCount;

  int get _remainingCount => _members.length - _completedCount;

  double get _progress =>
      _members.isEmpty ? 0 : _completedCount / _members.length;

  Map<String, dynamic>? get _currentMember {
    if (_members.isEmpty || _currentIndex >= _members.length) return null;
    return _members[_currentIndex];
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadAttendance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Sunday attendance date',
      selectableDayPredicate: (date) => date.weekday == DateTime.sunday,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _C.accent,
              onPrimary: _C.ink,
              surface: _C.surface,
              onSurface: _C.text,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: _C.surface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _C.accent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });

    await _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _loading = true;
      _error = null;
      _showSuccess = false;
    });

    try {
      final result = await _service.getAttendance(_dateString);
      final data = result['data'] as Map<String, dynamic>;
      final rawMembers = data['members'] as List<dynamic>;

      if (!mounted) return;

      setState(() {
        _members = rawMembers
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        _currentIndex = _findNextUnmarked(-1);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _findNextUnmarked(int afterIndex) {
    for (int i = afterIndex + 1; i < _members.length; i++) {
      if (_members[i]['status'] == 'unmarked') return i;
    }

    // Wrap around if there are unmarked members before the current position.
    for (int i = 0; i <= afterIndex && i < _members.length; i++) {
      if (_members[i]['status'] == 'unmarked') return i;
    }

    return _members.length;
  }

  Future<void> _markAttendance(String status) async {
    final member = _currentMember;

    if (member == null || _saving) return;

    final memberId = (member['_id'] ?? member['id'])?.toString();

    if (memberId == null || memberId.isEmpty) {
      setState(() => _error = 'Member ID is missing.');
      return;
    }

    final oldStatus = member['status'] as String? ?? 'unmarked';
    final oldIndex = _currentIndex;

    setState(() {
      _saving = true;
      _error = null;
      _showSuccess = false;
      member['status'] = status;
    });

    try {
      await _service.updateMemberAttendance(
        date: _dateString,
        memberId: memberId,
        status: status,
      );

      if (!mounted) return;

      await _animationController.forward();
      await _animationController.reverse();

      if (!mounted) return;

      setState(() {
        _currentIndex = _findNextUnmarked(oldIndex);
        _saving = false;
        _showSuccess = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        member['status'] = oldStatus;
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _undoLastSelection() async {
    if (_saving || _completedCount == 0) return;

    final index = _members.lastIndexWhere(
      (member) => member['status'] == 'present' ||
          member['status'] == 'absent',
    );

    if (index < 0) return;

    final member = _members[index];
    final memberId = (member['_id'] ?? member['id'])?.toString();

    if (memberId == null || memberId.isEmpty) return;

    final previousStatus = member['status'] as String;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.updateMemberAttendance(
        date: _dateString,
        memberId: memberId,
        status: 'unmarked',
      );

      if (!mounted) return;

      setState(() {
        member['status'] = 'unmarked';
        _currentIndex = index;
        _saving = false;
        _showSuccess = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        member['status'] = previousStatus;
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formattedDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final member = _currentMember;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _C.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Add attendance', style: _T.display(17)),
        actions: [
          IconButton(
            tooltip: 'Undo last marked member',
            onPressed: _undoLastSelection,
            icon: const Icon(Icons.undo_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _C.accent,
                  strokeWidth: 3,
                ),
              )
            : _error != null && _members.isEmpty
                ? _errorView()
                : _members.isEmpty
                    ? _emptyView()
                    : _buildAttendanceBody(member),
      ),
    );
  }

  Widget _buildAttendanceBody(Map<String, dynamic>? member) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Sunday attendance',
              style: _T.display(34, height: 1.05, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              'Mark each member present or absent. Every choice saves '
              'as you go.',
              style: _T.body(15, height: 1.4),
            ),
            const SizedBox(height: 24),
            _dateField(),
            const SizedBox(height: 28),
            _progressSection(),
            const SizedBox(height: 28),
            if (_error != null) ...[
              _messageCard(_error!, isError: true),
              const SizedBox(height: 16),
            ],
            if (_showSuccess) ...[
              _messageCard('Attendance saved.'),
              const SizedBox(height: 16),
            ],
            if (member == null) _completedView() else _memberCard(member),
          ],
        ),
      ),
    );
  }

  // Warm-white input-style selector with an external label.
  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance date', style: _T.label()),
        const SizedBox(height: 8),
        Material(
          color: _C.inputBg,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _C.inputBorder),
          ),
          child: InkWell(
            onTap: _saving ? null : _chooseDate,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 22,
                    color: _C.inputIcon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formattedDate(_selectedDate),
                      style: _T.body(
                        16,
                        weight: FontWeight.w700,
                        color: _C.inputText,
                      ),
                    ),
                  ),
                  Text(
                    'Sundays only',
                    style: _T.body(13, color: _C.inputHint),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: _C.inputIcon,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$_completedCount', style: _T.number(60, color: _C.accent)),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'of ${_members.length} members marked',
                  style: _T.body(
                    15,
                    weight: FontWeight.w600,
                    color: _C.text2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 350),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: _C.accent,
                backgroundColor: _C.border,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _C.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _stat('Present', _presentCount, _C.success),
                const VerticalDivider(width: 1, color: _C.border),
                _stat('Absent', _absentCount, _C.error),
                const VerticalDivider(width: 1, color: _C.border),
                _stat('Unmarked', _remainingCount, _C.text2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: _T.number(24, color: color)),
            const SizedBox(height: 6),
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
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final name = member['name']?.toString() ?? 'Unnamed member';
    final phone = member['phoneNumber']?.toString() ?? '';
    final status = member['status']?.toString() ?? 'unmarked';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(member['_id'] ?? member['id'] ?? name),
        padding: const EdgeInsets.all(22),
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
                Expanded(
                  child: Text(
                    'Member ${_currentIndex + 1} of ${_members.length}',
                    style: _T.label(),
                  ),
                ),
                if (status != 'unmarked') _statusTag(status),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _C.elevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.border),
                    ),
                    child: Text(
                      _initials(name),
                      style: _T.display(22, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _T.display(26, height: 1.1),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: _C.textSubtle,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                phone,
                                overflow: TextOverflow.ellipsis,
                                style: _T.body(14, color: _C.text2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: _C.border),
            const SizedBox(height: 20),
            Text('Mark attendance', style: _T.label()),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _presentButton(
                    onPressed: _saving ? null : () => _markAttendance('present'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _absentButton(
                    onPressed: _saving ? null : () => _markAttendance('absent'),
                  ),
                ),
              ],
            ),
            if (_saving) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: _C.accent,
                  backgroundColor: _C.border,
                ),
              ),
              const SizedBox(height: 8),
              Text('Saving attendance...', style: _T.body(13)),
            ],
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _saving ? null : _undoLastSelection,
              style: TextButton.styleFrom(
                foregroundColor: _C.text2,
                disabledForegroundColor: _C.textSubtle,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                textStyle: _T.body(14, weight: FontWeight.w600),
              ),
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Undo last selection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTag(String status) {
    final isPresent = status == 'present';
    final color = isPresent ? _C.success : _C.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check_rounded : Icons.close_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isPresent ? 'Present' : 'Absent',
            style: _T.body(12, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _presentButton({required VoidCallback? onPressed}) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded, size: 22),
        label: const Text('Present'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _C.success,
          foregroundColor: _C.ink,
          disabledBackgroundColor: _C.success.withValues(alpha: 0.3),
          disabledForegroundColor: _C.ink.withValues(alpha: 0.5),
          textStyle: _T.display(16, letterSpacing: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _absentButton({required VoidCallback? onPressed}) {
    return SizedBox(
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, size: 22),
        label: const Text('Absent'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _C.error,
          disabledForegroundColor: _C.error.withValues(alpha: 0.4),
          backgroundColor: _C.error.withValues(alpha: 0.08),
          side: BorderSide(
            color: onPressed == null
                ? _C.error.withValues(alpha: 0.3)
                : _C.error,
            width: 1.4,
          ),
          textStyle: _T.display(16, letterSpacing: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // The one solid accent block on the screen: the finished state.
  Widget _completedView() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _C.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.task_alt_rounded, size: 40, color: _C.ink),
          const SizedBox(height: 18),
          Text(
            'Attendance complete',
            style: _T.display(28, color: _C.ink, height: 1.1),
          ),
          const SizedBox(height: 10),
          Text(
            'All ${_members.length} members are marked for '
            '${_formattedDate(_selectedDate)}.',
            style: _T.body(15, color: _C.ink, height: 1.4),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _loadAttendance,
            style: FilledButton.styleFrom(
              backgroundColor: _C.ink,
              foregroundColor: _C.accent,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: _T.display(15, letterSpacing: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Refresh attendance'),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: _C.text2,
              ),
              const SizedBox(height: 16),
              Text('No members found', style: _T.display(26)),
              const SizedBox(height: 8),
              Text(
                'Add members before taking attendance.',
                style: _T.body(15, height: 1.4),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: _loadAttendance,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.text,
                  side: const BorderSide(color: _C.border, width: 1.4),
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: _T.display(15, letterSpacing: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: _C.error),
              const SizedBox(height: 16),
              Text('Could not load attendance', style: _T.display(26)),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Please try again.',
                style: _T.body(15, height: 1.4),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _loadAttendance,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: _C.ink,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: _T.display(15, letterSpacing: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageCard(String message, {bool isError = false}) {
    final color = isError ? _C.error : _C.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _T.body(14, weight: FontWeight.w500, color: _C.text),
            ),
          ),
        ],
      ),
    );
  }
}