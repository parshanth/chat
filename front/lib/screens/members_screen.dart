import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/member_service.dart';

// ---------------------------------------------------------------------------
// Design tokens (local to this screen; promote to the shared theme file when
// you roll the art direction out to other screens).
// ---------------------------------------------------------------------------
class _C {
  static const bg = Color(0xFF101511);
  static const bgAlt = Color(0xFF171E18);
  static const surface = Color(0xFF202922);
  static const elevated = Color(0xFF29342B);
  static const text = Color(0xFFF5F4EC);
  static const textSecondary = Color(0xFFA8B4A8);
  static const textSubtle = Color(0xFF849184);
  static const border = Color(0xFF354237);
  static const accent = Color(0xFFD6F078);
  static const accent2 = Color(0xFF75C6A0);
  static const inputBg = Color(0xFFF4F3ED);
  static const inputText = Color(0xFF172016);
  static const inputHint = Color(0xFF687368);
  static const inputIcon = Color(0xFF455349);
  static const inputBorder = Color(0xFFD7DED6);
  static const inputFocus = Color(0xFF527B45);
  static const error = Color(0xFFFF8585);
}

// Display family: Manrope. Body family: DM Sans.
// Both are declared as bundled assets in pubspec.yaml (see notes).
const _displayFamily = 'Manrope';
const _bodyFamily = 'DMSans';

TextStyle _display(
  double size, {
  FontWeight weight = FontWeight.w800,
  Color color = _C.text,
  double letterSpacing = -0.4,
  double height = 1.1,
}) =>
    TextStyle(
      fontFamily: _displayFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle _body(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _C.textSecondary,
  double height = 1.35,
  double letterSpacing = 0,
}) =>
    TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle _meta({Color color = _C.textSubtle}) => TextStyle(
      fontFamily: _bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color,
    );

ButtonStyle _primaryButton() => FilledButton.styleFrom(
      backgroundColor: _C.accent,
      foregroundColor: _C.bg,
      disabledBackgroundColor: _C.accent.withValues(alpha: 0.4),
      disabledForegroundColor: _C.bg.withValues(alpha: 0.6),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _body(15, weight: FontWeight.w700, color: _C.bg),
    );

ButtonStyle _quietButton() => TextButton.styleFrom(
      foregroundColor: _C.textSecondary,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _body(15, weight: FontWeight.w600),
    );

void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: error ? _C.error : _C.border),
        ),
        content: Text(
          message,
          style: _body(14, color: error ? _C.error : _C.text),
        ),
      ),
    );
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: _body(15, color: _C.inputHint),
    prefixIcon: Icon(icon, color: _C.inputIcon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _C.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border(_C.inputBorder),
    enabledBorder: border(_C.inputBorder),
    focusedBorder: border(_C.inputFocus, 1.5),
    errorBorder: border(_C.error),
    focusedErrorBorder: border(_C.error, 1.5),
    errorStyle: _body(12, color: _C.error, weight: FontWeight.w600),
  );
}

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _service = MemberService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final members = await _service.getMembers();
      if (!mounted) return;

      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_search.isEmpty) return _members;

    return _members.where((member) {
      final name = (member['name'] ?? '').toString().toLowerCase();
      final phone = (member['phoneNumber'] ?? '').toString().toLowerCase();

      return name.contains(_search) || phone.contains(_search);
    }).toList();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return 'Not provided';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int get _baptisedCount =>
      _members.where((m) => _parseDate(m['baptismDate']) != null).length;

  int get _birthdaysThisMonth {
    final month = DateTime.now().month;
    return _members.where((m) => _parseDate(m['dob'])?.month == month).length;
  }

  Future<void> _openMemberForm({Map<String, dynamic>? member}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _MemberFormDialog(
        service: _service,
        member: member,
      ),
    );

    if (saved == true && mounted) {
      await _loadMembers();
    }
  }

  Future<void> _deleteMember(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _C.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _C.border),
        ),
        title: Text('Delete member?', style: _display(22)),
        content: Text(
          'Are you sure you want to delete ${member['name']}? '
          'This cannot be undone.',
          style: _body(15),
        ),
        actions: [
          TextButton(
            style: _quietButton(),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: _primaryButton().copyWith(
              backgroundColor: const WidgetStatePropertyAll(_C.error),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteMember(member['_id'].toString());
      if (!mounted) return;

      _snack(context, 'Member deleted successfully.');

      await _loadMembers();
    } catch (error) {
      if (!mounted) return;
      _snack(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _filteredMembers;
    final showStats = !_loading && _error == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openMemberForm(),
          backgroundColor: _C.accent,
          foregroundColor: _C.bg,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          icon: const Icon(Icons.person_add_alt_1, size: 20),
          label: Text(
            'Add member',
            style: _body(15, weight: FontWeight.w700, color: _C.bg),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                color: _C.bg,
                backgroundColor: _C.accent,
                onRefresh: _loadMembers,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildStats(showStats)),
                    SliverToBoxAdapter(child: _buildSearch()),
                    SliverToBoxAdapter(child: _buildDirectoryHeader(members)),
                    if (_loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.only(top: 56),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: CircularProgressIndicator(
                              color: _C.accent,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      )
                    else if (_error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorView(
                          message: _error!,
                          onRetry: _loadMembers,
                        ),
                      )
                    else if (members.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyView(
                          searching: _search.isNotEmpty,
                          onAdd: () => _openMemberForm(),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildMemberRow(
                            members[index],
                            isLast: index == members.length - 1,
                          ),
                          childCount: members.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHURCH REGISTER', style: _meta(color: _C.accent)),
                const SizedBox(height: 8),
                Text('Members', style: _display(42, letterSpacing: -1.2)),
                const SizedBox(height: 8),
                Text(
                  'Contact details and key dates for your congregation.',
                  style: _body(14.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadMembers,
            icon: const Icon(Icons.refresh, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: _C.text,
              disabledForegroundColor: _C.textSubtle,
              backgroundColor: _C.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _C.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool ready) {
    String v(int n) => ready ? '$n' : '–';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _C.bgAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _Stat(
                value: v(_members.length),
                label: 'TOTAL',
                valueColor: _C.accent,
              ),
              const _StatDivider(),
              _Stat(value: v(_baptisedCount), label: 'BAPTISED'),
              const _StatDivider(),
              _Stat(value: v(_birthdaysThisMonth), label: 'BIRTHDAYS THIS MONTH'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEARCH', style: _meta(color: _C.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            cursorColor: _C.inputFocus,
            style: _body(15, color: _C.inputText),
            decoration: _inputDecoration(
              hint: 'Search by name or phone',
              icon: Icons.search,
              suffix: _search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(
                        Icons.clear,
                        color: _C.inputIcon,
                        size: 20,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryHeader(List<Map<String, dynamic>> members) {
    final filtering = _search.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('DIRECTORY', style: _meta(color: _C.textSecondary)),
          const Spacer(),
          Text(
            _loading ? '' : '${members.length}',
            style: _display(20, color: _C.text, letterSpacing: -0.2),
          ),
          if (filtering && !_loading)
            Text(
              ' of ${_members.length}',
              style: _body(14, color: _C.textSubtle),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member, {required bool isLast}) {
    final name = (member['name'] ?? '').toString();
    final phone = (member['phoneNumber'] ?? '').toString();
    final baptised = _parseDate(member['baptismDate']) != null;

    return InkWell(
      onTap: () => _openMemberForm(member: member),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
        decoration: BoxDecoration(
          border: Border(
            top: const BorderSide(color: _C.border),
            bottom: isLast
                ? const BorderSide(color: _C.border)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _C.elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: _display(19, letterSpacing: 0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unnamed member' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _display(17, weight: FontWeight.w700, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: phone.isEmpty ? _C.textSubtle : _C.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          phone.isEmpty ? 'No phone number' : phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _body(
                            14,
                            color: phone.isEmpty
                                ? _C.textSubtle
                                : _C.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaPair(
                        label: 'DOB',
                        value: _formatDate(member['dob']),
                      ),
                      if (baptised)
                        _MetaPair(
                          label: 'BAPTISED',
                          value: _formatDate(member['baptismDate']),
                          labelColor: _C.accent2,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Member actions',
              color: _C.elevated,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _C.border),
              ),
              icon: const Icon(Icons.more_horiz, color: _C.textSecondary),
              onSelected: (action) {
                if (action == 'edit') {
                  _openMemberForm(member: member);
                } else if (action == 'delete') {
                  _deleteMember(member);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 18, color: _C.text),
                      const SizedBox(width: 10),
                      Text('Edit', style: _body(15, color: _C.text)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 18, color: _C.error),
                      const SizedBox(width: 10),
                      Text('Delete', style: _body(15, color: _C.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _Stat({
    required this.value,
    required this.label,
    this.valueColor = _C.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: _display(32, color: valueColor, letterSpacing: -1)),
            const SizedBox(height: 6),
            Text(
              label,
              style: _meta(color: _C.textSecondary).copyWith(
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      const VerticalDivider(width: 1, thickness: 1, color: _C.border);
}

class _MetaPair extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;

  const _MetaPair({
    required this.label,
    required this.value,
    this.labelColor = _C.textSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: _meta(color: labelColor).copyWith(fontSize: 10, letterSpacing: 1.2),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: _body(13, color: _C.textSecondary, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MemberFormDialog extends StatefulWidget {
  final MemberService service;
  final Map<String, dynamic>? member;

  const _MemberFormDialog({
    required this.service,
    this.member,
  });

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  DateTime? _dob;
  DateTime? _baptismDate;
  bool _saving = false;

  bool get _editing => widget.member != null;

  @override
  void initState() {
    super.initState();

    final member = widget.member;

    _nameController = TextEditingController(
      text: (member?['name'] ?? '').toString(),
    );
    _phoneController = TextEditingController(
      text: (member?['phoneNumber'] ?? '').toString(),
    );

    _dob = DateTime.tryParse((member?['dob'] ?? '').toString());
    _baptismDate =
        DateTime.tryParse((member?['baptismDate'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _dateValue(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<DateTime?> _pickDate(DateTime? currentDate) async {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _C.accent,
            onPrimary: _C.bg,
            surface: _C.elevated,
            onSurface: _C.text,
          ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: _C.elevated,
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_editing) {
        await widget.service.updateMember(
          id: widget.member!['_id'].toString(),
          name: _nameController.text,
          dob: _dateValue(_dob),
          phoneNumber: _phoneController.text,
          baptismDate: _dateValue(_baptismDate),
        );
      } else {
        await widget.service.createMember(
          name: _nameController.text,
          dob: _dateValue(_dob),
          phoneNumber: _phoneController.text,
          baptismDate: _dateValue(_baptismDate),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      _snack(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: _meta(color: _C.textSecondary)),
      );

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Material(
          color: _C.inputBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _saving ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.only(left: 14, right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.inputBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: _C.inputIcon,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateText(value),
                      style: _body(
                        15,
                        color: value == null ? _C.inputHint : _C.inputText,
                      ),
                    ),
                  ),
                  if (value != null)
                    IconButton(
                      tooltip: 'Clear $label'.toLowerCase(),
                      onPressed: _saving ? null : onClear,
                      icon: const Icon(
                        Icons.clear,
                        color: _C.inputIcon,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 112 < 420 ? screenWidth - 112 : 420.0;

    return AlertDialog(
      backgroundColor: _C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _C.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing ? 'EDIT RECORD' : 'NEW RECORD',
            style: _meta(color: _C.accent),
          ),
          const SizedBox(height: 6),
          Text(
            _editing ? 'Edit member' : 'Add member',
            style: _display(26, letterSpacing: -0.6),
          ),
        ],
      ),
      content: SizedBox(
        width: contentWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('FULL NAME *'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: _C.inputFocus,
                  style: _body(15, color: _C.inputText),
                  decoration: _inputDecoration(
                    hint: 'Name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 18),
                _label('PHONE NUMBER'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  cursorColor: _C.inputFocus,
                  style: _body(15, color: _C.inputText),
                  decoration: _inputDecoration(
                    hint: 'Optional',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                _dateField(
                  label: 'DATE OF BIRTH',
                  value: _dob,
                  onTap: () async {
                    final date = await _pickDate(_dob);
                    if (date != null && mounted) {
                      setState(() => _dob = date);
                    }
                  },
                  onClear: () => setState(() => _dob = null),
                ),
                const SizedBox(height: 18),
                _dateField(
                  label: 'BAPTISM DATE',
                  value: _baptismDate,
                  onTap: () async {
                    final date = await _pickDate(_baptismDate);
                    if (date != null && mounted) {
                      setState(() => _baptismDate = date);
                    }
                  },
                  onClear: () => setState(() => _baptismDate = null),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 24, 20),
      actions: [
        TextButton(
          style: _quietButton(),
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: _primaryButton(),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.bg,
                  ),
                )
              : Text(_editing ? 'Save changes' : 'Add member'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: _C.error),
            const SizedBox(height: 14),
            Text(
              'Could not load members',
              style: _display(20, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: _body(14)),
            const SizedBox(height: 20),
            FilledButton(
              style: _primaryButton(),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool searching;
  final VoidCallback onAdd;

  const _EmptyView({
    required this.searching,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: Icon(
                searching ? Icons.search_off : Icons.people_outline,
                size: 28,
                color: _C.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'No matching members' : 'No members yet',
              style: _display(21, letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try another name or phone number.'
                  : 'Add your first church member to get started.',
              textAlign: TextAlign.center,
              style: _body(14.5),
            ),
            if (!searching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: _primaryButton(),
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: const Text('Add member'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}