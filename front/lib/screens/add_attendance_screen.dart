import 'package:flutter/material.dart';

import '../services/attendance_service.dart';

class _C {
  static const bg = Color(0xFF101511), table = Color(0xFF171E18);
  static const header = Color(0xFF202922);
  static const text = Color(0xFFF5F4EC), text2 = Color(0xFFA8B4A8);
  static const textSubtle = Color(0xFF849184), border = Color(0xFF354237);
  static const rowBorder = Color(0xFF263028);
  static const accent = Color(0xFFD6F078), inputBg = Color(0xFFF4F3ED);
  static const inputText = Color(0xFF172016), inputHint = Color(0xFF687368);
  static const inputIcon = Color(0xFF455349), inputBorder = Color(0xFFD7DED6);
  static const error = Color(0xFFFF8585), success = Color(0xFF75D99A);
  static const presentFill = Color(0xFF2E7D4F), absentFill = Color(0xFFA83A3A);
  static const neutral = Color(0xFF8A948A);
  static const ink = Color(0xFF101511);
}

class _T {
  static TextStyle display(double size, {Color color = _C.text, double? height}) =>
      TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: height,
        letterSpacing: -0.4,
      );
  static TextStyle number(double size, {Color color = _C.text}) => TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _C.text2,
    double? height,
  }) =>
      TextStyle(
        fontFamily: 'DMSans',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
  static TextStyle columnHead() => const TextStyle(
        fontFamily: 'DMSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _C.text2,
        letterSpacing: 0.9,
      );
}

class AddAttendanceScreen extends StatefulWidget {
  const AddAttendanceScreen({super.key});
  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final AttendanceService _service = AttendanceService.instance;
  final TextEditingController _search = TextEditingController();
  final Set<String> _savingIds = <String>{};
  DateTime _selectedDate = _nextSunday(DateTime.now());
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  String _query = '';
  bool _loading = false;
  String? _error;

  static DateTime _nextSunday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.add(Duration(days: (DateTime.sunday - day.weekday) % 7));
  }

  String get _dateString =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _visibleMembers {
    final query = _query.trim().toLowerCase();
    return query.isEmpty
        ? _members
        : _members
            .where((m) =>
                (m['name']?.toString() ?? '').toLowerCase().contains(query))
            .toList();
  }

  int get _presentCount => _members.where((m) => _status(m) == 'present').length;
  int get _absentCount => _members.where((m) => _status(m) == 'absent').length;
  int get _unmarkedCount => _members.length - _presentCount - _absentCount;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text));
    _loadAttendance();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _loading = true;
      _error = null;
      _savingIds.clear();
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
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Sunday attendance date',
      selectableDayPredicate: (date) => date.weekday == DateTime.sunday,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _C.accent,
            onPrimary: _C.ink,
            surface: _C.header,
            onSurface: _C.text,
          ),
          datePickerTheme: const DatePickerThemeData(backgroundColor: _C.header),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _C.accent),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _selectedDate = DateTime(picked.year, picked.month, picked.day),
    );
    await _loadAttendance();
  }

  Future<void> _setStatus(Map<String, dynamic> member, String status) async {
    final id = _id(member);
    if (id == null || _savingIds.contains(id)) return;
    final oldStatus = _status(member);
    if (oldStatus == status) return;
    setState(() {
      _savingIds.add(id);
      _error = null;
      member['status'] = status;
    });
    try {
      await _service.updateMemberAttendance(
        date: _dateString,
        memberId: id,
        status: status,
      );
      if (!mounted) return;
      setState(() => _savingIds.remove(id));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        member['status'] = oldStatus;
        _savingIds.remove(id);
        _error = _errorText(error);
      });
    }
  }

  String? _id(Map<String, dynamic> member) {
    final id = (member['_id'] ?? member['id'])?.toString();
    return id == null || id.isEmpty ? null : id;
  }

  String _status(Map<String, dynamic> member) {
    final status = member['status']?.toString().toLowerCase();
    return status == 'present' || status == 'absent' ? status! : 'unmarked';
  }

  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  String _formattedDate(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.bg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _C.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Add attendance', style: _T.display(17)),
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
                      : _register(),
        ),
      );

  // ---------------------------------------------------------------- register

  Widget _register() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 600;
              return Padding(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 4, wide ? 24 : 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _toolbar(wide),
                    const SizedBox(height: 10),
                    _summary(),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      _errorBanner(_error!),
                    ],
                    const SizedBox(height: 10),
                    Expanded(child: _table(wide)),
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget _toolbar(bool wide) {
    final date = _dateField();
    final search = _searchField();
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: date),
          const SizedBox(width: 10),
          Expanded(flex: 6, child: search),
        ],
      );
    }
    return Column(children: [date, const SizedBox(height: 8), search]);
  }

  Widget _dateField() => Material(
        color: _C.inputBg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _C.inputBorder),
        ),
        child: InkWell(
          onTap: _savingIds.isEmpty ? _chooseDate : null,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 19, color: _C.inputIcon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formattedDate(_selectedDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.body(14,
                        weight: FontWeight.w700, color: _C.inputText),
                  ),
                ),
                Text('Sundays', style: _T.body(12, color: _C.inputHint)),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded,
                    size: 20, color: _C.inputIcon),
              ],
            ),
          ),
        ),
      );

  Widget _searchField() => SizedBox(
        height: 44,
        child: TextField(
          controller: _search,
          cursorColor: _C.inputText,
          style: _T.body(14, weight: FontWeight.w600, color: _C.inputText),
          decoration: InputDecoration(
            hintText: 'Search members by name',
            hintStyle: _T.body(14, color: _C.inputHint),
            prefixIcon:
                const Icon(Icons.search_rounded, size: 20, color: _C.inputIcon),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: _search.clear,
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: _C.inputIcon),
                  ),
            filled: true,
            fillColor: _C.inputBg,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: _inputBorder(),
            enabledBorder: _inputBorder(),
            focusedBorder: _inputBorder(_C.accent, 1.5),
          ),
        ),
      );

  OutlineInputBorder _inputBorder([Color color = _C.inputBorder, double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _summary() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _C.table,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            _stat('Present', _presentCount, _C.success),
            _statDivider(),
            _stat('Absent', _absentCount, _C.error),
            _statDivider(),
            _stat('Unmarked', _unmarkedCount, _C.neutral),
          ],
        ),
      );

  Widget _statDivider() => Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: _C.border,
      );

  Widget _stat(String label, int value, Color color) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text('$value', style: _T.number(17, color: _C.text)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _T.body(12, weight: FontWeight.w600, color: _C.text2),
              ),
            ),
          ],
        ),
      );

  // ------------------------------------------------------------------- table

  Widget _table(bool wide) {
    final btnW = wide ? 96.0 : 70.0;
    final btnH = wide ? 34.0 : 32.0;
    final rowH = wide ? 48.0 : 46.0;
    final gap = wide ? 8.0 : 6.0;
    final hPad = wide ? 16.0 : 10.0;
    final attendW = btnW * 2 + gap;
    final members = _visibleMembers;

    return Container(
      decoration: BoxDecoration(
        color: _C.table,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header — same paddings/widths as rows so columns line up.
          Container(
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            decoration: const BoxDecoration(
              color: _C.header,
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                Expanded(child: Text('MEMBER NAME', style: _T.columnHead())),
                const SizedBox(width: 20), // saving-indicator slot
                SizedBox(
                  width: attendW,
                  child: Text(
                    'ATTENDANCE',
                    textAlign: TextAlign.center,
                    style: _T.columnHead(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? _noMatches()
                : ListView.builder(
                    itemCount: members.length,
                    itemExtent: rowH,
                    itemBuilder: (_, i) => _memberRow(
                      members[i],
                      isLast: i == members.length - 1,
                      hPad: hPad,
                      btnW: btnW,
                      btnH: btnH,
                      gap: gap,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(
    Map<String, dynamic> member, {
    required bool isLast,
    required double hPad,
    required double btnW,
    required double btnH,
    required double gap,
  }) {
    final id = _id(member);
    final saving = id != null && _savingIds.contains(id);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _C.rowBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member['name']?.toString() ?? 'Unnamed member',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _T.body(14,
                  weight: FontWeight.w600, color: _C.text, height: 1.2),
            ),
          ),
          SizedBox(
            width: 20,
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        color: _C.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : null,
            ),
          ),
          _statusButton(member, 'present', btnW, btnH, saving),
          SizedBox(width: gap),
          _statusButton(member, 'absent', btnW, btnH, saving),
        ],
      ),
    );
  }

  Widget _statusButton(
    Map<String, dynamic> member,
    String status,
    double width,
    double height,
    bool saving,
  ) {
    final selected = _status(member) == status;
    final present = status == 'present';
    final fill = present ? _C.presentFill : _C.absentFill;
    final tint = present ? _C.success : _C.error;
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: selected ? fill : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: selected ? tint.withValues(alpha: .7) : _C.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: saving
              ? null
              : () => _setStatus(member, selected ? 'unmarked' : status),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(
                    present ? Icons.check_rounded : Icons.close_rounded,
                    size: 14,
                    color: _C.text,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  present ? 'Present' : 'Absent',
                  maxLines: 1,
                  style: _T.body(
                    12,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _C.text : _C.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ states

  Widget _noMatches() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_outlined,
                  size: 32, color: _C.text2),
              const SizedBox(height: 10),
              Text('No matching members', style: _T.display(18)),
              const SizedBox(height: 4),
              Text('Try another name or clear the search.',
                  textAlign: TextAlign.center, style: _T.body(13)),
            ],
          ),
        ),
      );

  Widget _emptyView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 40, color: _C.text2),
              const SizedBox(height: 16),
              Text('No members found', style: _T.display(24)),
              const SizedBox(height: 8),
              Text('Add members before taking attendance.',
                  style: _T.body(15)),
            ],
          ),
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: _C.error),
              const SizedBox(height: 16),
              Text('Could not load attendance', style: _T.display(24)),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: _T.body(15),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: _C.ink,
                ),
                onPressed: _loadAttendance,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _errorBanner(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _C.error.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.error.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: _T.body(13, weight: FontWeight.w500, color: _C.text),
              ),
            ),
          ],
        ),
      );
}