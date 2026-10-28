import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../services/member_service.dart';
import 'attendance_summary_screen.dart';

// ---------------------------------------------------------------------------
// Design tokens (local to this screen; promote to the shared theme file when
// you roll the art direction out to other screens).
// ---------------------------------------------------------------------------
class _C {
  static const bg = Color(0xFF090A0B);
  static const bg2 = Color(0xFF0F1113);
  static const surface = Color(0xFF151719);
  static const elevated = Color(0xFF1C1F22);
  static const text = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFA1A5AA);
  static const textSubtle = Color(0xFF747A80);
  static const border = Color(0xFF292D31);
  static const accent = Color(0xFFD6F078);
  static const ink = Color(0xFF171918);
  static const success = Color(0xFF75D99A);
  static const inputBg = Color(0xFFF0F0EC);
  static const inputText = Color(0xFF171918);
  static const inputHint = Color(0xFF737871);
  static const inputIcon = Color(0xFF505650);
  static const inputBorder = Color(0xFFD3D6CF);
  static const inputFocus = Color(0xFF777F70);
  static const error = Color(0xFFFF8585);
}

// Radii: 12 inputs/buttons, 16 tiles, 20 cards/dialogs.
const double _rControl = 12;
const double _rTile = 16;
const double _rCard = 20;

const _maxContentWidth = 1000.0;
const _gutter = 20.0;
const _fastAnim = Duration(milliseconds: 200);

// Display family: Manrope. Body family: DM Sans.
// Both are declared as bundled assets in pubspec.yaml.
const _displayFamily = 'Manrope';
const _bodyFamily = 'DMSans';

TextStyle _display(
  double size, {
  FontWeight weight = FontWeight.w800,
  Color color = _C.text,
  double letterSpacing = -0.6,
  double height = 1.1,
}) => TextStyle(
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
  double height = 1.45,
  double letterSpacing = 0,
}) => TextStyle(
  fontFamily: _bodyFamily,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  fontFeatures: const [FontFeature.tabularFigures()],
);

TextStyle _meta({Color color = _C.textSubtle}) => TextStyle(
  fontFamily: _bodyFamily,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.6,
  height: 1.2,
  color: color,
);

Color _tint(Color color, double alpha) => color.withValues(alpha: alpha);

BoxDecoration _cardDecoration({double radius = _rTile}) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_C.surface, Color.alphaBlend(_tint(_C.elevated, 0.7), _C.surface)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _C.border),
  boxShadow: [
    BoxShadow(
      color: _C.bg.withValues(alpha: 0.24),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ],
);

ButtonStyle _primaryButton() => FilledButton.styleFrom(
  backgroundColor: _C.accent,
  foregroundColor: _C.ink,
  disabledBackgroundColor: _tint(_C.accent, 0.4),
  disabledForegroundColor: _tint(_C.ink, 0.6),
  minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 24),
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rControl)),
  textStyle: _body(15, weight: FontWeight.w700, color: _C.ink),
);

ButtonStyle _secondaryButton() => FilledButton.styleFrom(
  backgroundColor: _C.elevated,
  foregroundColor: _C.text,
  disabledBackgroundColor: _tint(_C.elevated, 0.5),
  disabledForegroundColor: _C.textSubtle,
  minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_rControl),
    side: const BorderSide(color: _C.border),
  ),
  textStyle: _body(15, weight: FontWeight.w600, color: _C.text),
);

ButtonStyle _destructiveButton() => FilledButton.styleFrom(
  backgroundColor: _tint(_C.error, 0.14),
  foregroundColor: _C.error,
  minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_rControl),
    side: BorderSide(color: _tint(_C.error, 0.3)),
  ),
  textStyle: _body(15, weight: FontWeight.w700, color: _C.error),
);

void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rControl),
          side: BorderSide(color: error ? _tint(_C.error, 0.4) : _C.border),
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
        borderRadius: BorderRadius.circular(_rControl),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: _body(15, color: _C.inputHint),
    prefixIcon: Icon(icon, color: _C.inputIcon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _C.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(_C.inputBorder),
    enabledBorder: border(_C.inputBorder),
    focusedBorder: border(_C.inputFocus, 1.5),
    errorBorder: border(_C.error),
    focusedErrorBorder: border(_C.error, 1.5),
    errorStyle: _body(12, color: _C.error, weight: FontWeight.w600),
  );
}

const _monthNames = [
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

String _formatDate(DateTime? date, {String empty = 'Not provided'}) {
  if (date == null) return empty;
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _service = MemberService();
  final TextEditingController _searchController = TextEditingController();

  List<Member> _members = [];
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

  List<Member> get _filteredMembers {
    if (_search.isEmpty) return _members;

    return _members.where((member) {
      final name = member.name.toLowerCase();
      final phone = member.phoneNumber.toLowerCase();

      return name.contains(_search) || phone.contains(_search);
    }).toList();
  }

  Future<void> _openMemberForm({Member? member}) async {
    final saved = await showDialog<Member>(
      context: context,
      builder: (_) => _MemberFormDialog(service: _service, member: member),
    );

    if (saved != null && mounted) {
      await _loadMembers();
    }
  }

  Future<void> _deleteMember(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteMemberDialog(name: member.name),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteMember(member.id);
      if (!mounted) return;

      _snack(context, 'Member deleted successfully.');

      await _loadMembers();
    } catch (error) {
      if (!mounted) return;
      _snack(context, error.toString(), error: true);
    }
  }

  void _openAttendanceDetails(Member member) {
    if (member.id.isEmpty) {
      _snack(
        context,
        'Attendance details are unavailable for this member.',
        error: true,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberAttendanceDetailScreen(
          memberId: member.id,
          memberName: member.name.isEmpty ? 'Unnamed member' : member.name,
          memberDetails: member.toJson(),
          year: DateTime.now().year,
        ),
      ),
    );
  }

  void _onRefresh() {
    HapticFeedback.selectionClick();
    _loadMembers();
  }

  void _onAdd() {
    HapticFeedback.lightImpact();
    _openMemberForm();
  }

  @override
  Widget build(BuildContext context) {
    final members = _filteredMembers;
    final columns = MediaQuery.sizeOf(context).width >= 800 ? 2 : 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.bg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _C.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Members', style: _display(18, letterSpacing: -0.3)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _onRefresh,
                icon: const Icon(Icons.refresh, size: 22),
                style: IconButton.styleFrom(
                  foregroundColor: _C.text,
                  disabledForegroundColor: _C.textSubtle,
                  backgroundColor: _C.surface,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_rControl),
                    side: const BorderSide(color: _C.border),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onAdd,
          backgroundColor: _C.accent,
          foregroundColor: _C.ink,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rTile),
          ),
          icon: const Icon(Icons.person_add_alt_1, size: 20),
          label: Text(
            'Add member',
            style: _body(15, weight: FontWeight.w700, color: _C.ink),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_C.bg, _C.bg2],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: RefreshIndicator(
                  color: _C.ink,
                  backgroundColor: _C.accent,
                  onRefresh: _loadMembers,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SearchField(
                          controller: _searchController,
                          hasText: _search.isNotEmpty,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _DirectoryHeader(
                          loading: _loading,
                          shown: members.length,
                          total: _members.length,
                          filtering: _search.isNotEmpty,
                        ),
                      ),
                      ..._buildContent(members, columns),
                      const SliverToBoxAdapter(child: SizedBox(height: 112)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(List<Member> members, int columns) {
    if (_loading) {
      return [
        _collectionSliver(
          columns: columns,
          count: 6,
          itemBuilder: (context, index) => const _SkeletonTile(),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateView(
            icon: Icons.cloud_off_outlined,
            tone: _C.error,
            title: 'Could not load members',
            message: _error!,
            action: FilledButton(
              style: _primaryButton(),
              onPressed: _onRefresh,
              child: const Text('Try again'),
            ),
          ),
        ),
      ];
    }

    if (members.isEmpty) {
      final searching = _search.isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateView(
            icon: searching ? Icons.search_off : Icons.people_outline,
            tone: _C.accent,
            title: searching ? 'No matching members' : 'No members yet',
            message: searching
                ? 'Try another name or phone number.'
                : 'Add your first church member to get started.',
            action: searching
                ? null
                : FilledButton.icon(
                    style: _primaryButton(),
                    onPressed: _onAdd,
                    icon: const Icon(Icons.person_add_alt_1, size: 20),
                    label: const Text('Add member'),
                  ),
          ),
        ),
      ];
    }

    return [
      _collectionSliver(
        columns: columns,
        count: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return _FadeSlideIn(
            index: index,
            child: _MemberTile(
              member: member,
              onOpen: () => _openAttendanceDetails(member),
              onEdit: () => _openMemberForm(member: member),
              onDelete: () => _deleteMember(member),
            ),
          );
        },
      ),
    ];
  }

  Widget _collectionSliver({
    required int columns,
    required int count,
    required NullableIndexedWidgetBuilder itemBuilder,
  }) {
    const padding = EdgeInsets.symmetric(horizontal: _gutter);

    if (columns == 1) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: count,
          itemBuilder: itemBuilder,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverGrid.builder(
        itemCount: count,
        itemBuilder: itemBuilder,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 72,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List screen widgets
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;

  const _SearchField({required this.controller, required this.hasText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEARCH', style: _meta(color: _C.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            cursorColor: _C.inputFocus,
            textInputAction: TextInputAction.search,
            style: _body(15, color: _C.inputText),
            decoration: _inputDecoration(
              hint: 'Search by name or phone',
              icon: Icons.search,
              suffix: AnimatedSwitcher(
                duration: _fastAnim,
                child: hasText
                    ? IconButton(
                        key: const ValueKey('clear'),
                        tooltip: 'Clear search',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          controller.clear();
                        },
                        icon: const Icon(
                          Icons.clear,
                          color: _C.inputIcon,
                          size: 20,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  final bool loading;
  final int shown;
  final int total;
  final bool filtering;

  const _DirectoryHeader({
    required this.loading,
    required this.shown,
    required this.total,
    required this.filtering,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 32, _gutter, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('DIRECTORY', style: _meta(color: _C.textSecondary)),
          const Spacer(),
          AnimatedSwitcher(
            duration: _fastAnim,
            child: Text(
              loading ? '' : '$shown',
              key: ValueKey(loading ? -1 : shown),
              style: _display(22, letterSpacing: -0.4),
            ),
          ),
          if (filtering && !loading)
            Text(' of $total', style: _body(14, color: _C.textSubtle)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberTile({
    required this.member,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = member.name;
    final phone = member.phoneNumber;
    final displayName = name.isEmpty ? 'Unnamed member' : name;
    final displayPhone = phone.isEmpty ? 'No phone number' : phone;

    return Semantics(
      button: true,
      label: 'Open attendance for $displayName, $displayPhone',
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: _cardDecoration(),
          child: InkWell(
            borderRadius: BorderRadius.circular(_rTile),
            splashColor: _tint(_C.accent, 0.08),
            highlightColor: _tint(_C.accent, 0.04),
            onTap: () {
              HapticFeedback.lightImpact();
              onOpen();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
              child: Row(
                children: [
                  _InitialAvatar(name: name),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _display(
                            16,
                            weight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayPhone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _body(
                            13.5,
                            color: phone.isEmpty
                                ? _C.textSubtle
                                : _C.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MemberMenu(onEdit: onEdit, onDelete: onDelete),
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: _C.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(_tint(_C.accent, 0.1), _C.elevated),
        borderRadius: BorderRadius.circular(_rControl),
        border: Border.all(color: _tint(_C.accent, 0.25)),
      ),
      child: ExcludeSemantics(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: _display(18, color: _C.accent, letterSpacing: 0),
        ),
      ),
    );
  }
}

class _MemberMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Member actions',
      color: _C.elevated,
      surfaceTintColor: Colors.transparent,
      shadowColor: _C.bg.withValues(alpha: 0.3),
      elevation: 12,
      padding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_rControl),
        side: const BorderSide(color: _C.border),
      ),
      icon: const Icon(Icons.more_horiz, color: _C.textSecondary),
      onSelected: (action) {
        HapticFeedback.selectionClick();
        if (action == 'edit') {
          onEdit();
        } else if (action == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: _C.text),
              const SizedBox(width: 12),
              Text('Edit', style: _body(15, color: _C.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: _C.error),
              const SizedBox(width: 12),
              Text('Delete', style: _body(15, color: _C.error)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fade + small upward slide, lightly staggered by [index] (capped).
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;

  const _FadeSlideIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final step = index > 8 ? 8 : index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + step * 40),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton (shimmer without packages)
// ---------------------------------------------------------------------------

class _SlideGradient extends GradientTransform {
  final double slide;

  const _SlideGradient(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile();

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: _C.elevated,
      borderRadius: BorderRadius.circular(6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final highlight = Color.alphaBlend(_tint(_C.text, 0.08), _C.elevated);

    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _cardDecoration(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => LinearGradient(
              colors: [_C.elevated, highlight, _C.elevated],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(_controller.value * 2 - 1),
            ).createShader(rect),
            child: child,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _C.elevated,
                  borderRadius: BorderRadius.circular(_rControl),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(140, 14),
                  const SizedBox(height: 8),
                  _bar(96, 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared error / empty state
// ---------------------------------------------------------------------------

class _StateView extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String title;
  final String message;
  final Widget? action;

  const _StateView({
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _tint(tone, 0.1),
                borderRadius: BorderRadius.circular(_rCard),
                border: Border.all(color: _tint(tone, 0.28)),
              ),
              child: Icon(icon, size: 28, color: tone),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: _display(22, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: _body(14.5)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

class _DeleteMemberDialog extends StatelessWidget {
  final String name;

  const _DeleteMemberDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _C.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: _C.bg.withValues(alpha: 0.3),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_rCard),
        side: const BorderSide(color: _C.border),
      ),
      title: Text('Delete member?', style: _display(24, letterSpacing: -0.5)),
      content: Text(
        'Are you sure you want to delete $name? '
        'This cannot be undone.',
        style: _body(15),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
      actions: [
        FilledButton(
          style: _secondaryButton(),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: _destructiveButton(),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, true);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _MemberFormDialog extends StatefulWidget {
  final MemberService service;
  final Member? member;

  const _MemberFormDialog({required this.service, this.member});

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

Future<Member?> showMemberEditDialog(BuildContext context, Member member) {
  return showDialog<Member>(
    context: context,
    builder: (_) => _MemberFormDialog(service: MemberService(), member: member),
  );
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  DateTime? _dob;
  DateTime? _baptismDate;
  DateTime? _marriageDate;
  bool _saving = false;
  bool _closing = false;

  bool get _editing => widget.member != null;

  @override
  void initState() {
    super.initState();

    final member = widget.member;

    _nameController = TextEditingController(text: member?.name ?? '');
    _phoneController = TextEditingController(text: member?.phoneNumber ?? '');

    _dob = member?.dob;
    _baptismDate = member?.baptismDate;
    _marriageDate = member?.marriageDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(
    DateTime? currentDate, {
    bool allowFutureDates = true,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = allowFutureDates ? DateTime(now.year + 1) : today;
    final current = currentDate == null
        ? today
        : DateTime(currentDate.year, currentDate.month, currentDate.day);
    final initialDate = current.isAfter(lastDate) ? lastDate : current;

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _C.accent,
            onPrimary: _C.ink,
            surface: _C.elevated,
            onSurface: _C.text,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: _C.elevated,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_rCard),
              side: const BorderSide(color: _C.border),
            ),
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() => _saving = true);

    try {
      final savedMember = _editing
          ? await widget.service.updateMember(
              id: widget.member!.id,
              name: _nameController.text,
              dob: _dob,
              phoneNumber: _phoneController.text,
              baptismDate: _baptismDate,
              marriageDate: _marriageDate,
            )
          : await widget.service.createMember(
              name: _nameController.text,
              dob: _dob,
              phoneNumber: _phoneController.text,
              baptismDate: _baptismDate,
              marriageDate: _marriageDate,
            );

      if (!mounted) return;
      _closeDialog(savedMember);
    } catch (error) {
      if (!mounted) return;

      _snack(context, error.toString(), error: true);
      setState(() => _saving = false);
    }
  }

  void _closeDialog(Member? member) {
    if (_closing) return;
    setState(() => _closing = true);
    Navigator.of(context).pop<Member>(member);
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    bool allowFutureDates = true,
  }) {
    return _DateField(
      label: label,
      value: value,
      enabled: !_saving,
      onTap: () async {
        final date = await _pickDate(value, allowFutureDates: allowFutureDates);
        if (date != null && mounted) onChanged(date);
      },
      onClear: () => onChanged(null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 112 < 420 ? screenWidth - 112 : 420.0;

    return PopScope(
      canPop: !_saving && !_closing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && mounted && !_closing) {
          setState(() => _closing = true);
        }
      },
      child: AlertDialog(
        backgroundColor: _C.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: _C.bg.withValues(alpha: 0.3),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rCard),
          side: const BorderSide(color: _C.border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: _FormHeader(editing: _editing),
        content: SizedBox(
          width: contentWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('FULL NAME *'),
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
                  const SizedBox(height: 16),
                  const _FieldLabel('PHONE NUMBER'),
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
                  const SizedBox(height: 16),
                  _dateField(
                    label: 'DATE OF BIRTH',
                    value: _dob,
                    onChanged: (date) => setState(() => _dob = date),
                  ),
                  const SizedBox(height: 16),
                  _dateField(
                    label: 'BAPTISM DATE',
                    value: _baptismDate,
                    onChanged: (date) => setState(() => _baptismDate = date),
                  ),
                  const SizedBox(height: 16),
                  _dateField(
                    label: 'MARRIAGE DATE',
                    value: _marriageDate,
                    allowFutureDates: false,
                    onChanged: (date) => setState(() => _marriageDate = date),
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
        actions: [
          FilledButton(
            style: _secondaryButton(),
            onPressed: _saving || _closing ? null : () => _closeDialog(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: _primaryButton(),
            onPressed: _saving || _closing ? null : _save,
            child: AnimatedSwitcher(
              duration: _fastAnim,
              child: _saving
                  ? const SizedBox(
                      key: ValueKey('saving'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _C.ink,
                      ),
                    )
                  : Text(
                      _editing ? 'Save changes' : 'Add member',
                      key: const ValueKey('label'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final bool editing;

  const _FormHeader({required this.editing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          editing ? 'EDIT RECORD' : 'NEW RECORD',
          style: _meta(color: _C.accent),
        ),
        const SizedBox(height: 8),
        Text(
          editing ? 'Edit member' : 'Add member',
          style: _display(28, letterSpacing: -0.8),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: _meta(color: _C.textSecondary)),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Semantics(
          button: true,
          label: '$label, ${_formatDate(value, empty: 'not set')}',
          excludeSemantics: true,
          onTap: enabled ? onTap : null,
          child: Material(
            color: _C.inputBg,
            borderRadius: BorderRadius.circular(_rControl),
            child: InkWell(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onTap();
                    }
                  : null,
              borderRadius: BorderRadius.circular(_rControl),
              splashColor: _tint(_C.inputFocus, 0.12),
              highlightColor: _tint(_C.inputFocus, 0.06),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.only(left: 16, right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_rControl),
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
                        _formatDate(value, empty: 'Select date'),
                        style: _body(
                          15,
                          color: value == null ? _C.inputHint : _C.inputText,
                        ),
                      ),
                    ),
                    if (value != null)
                      IconButton(
                        tooltip: 'Clear $label'.toLowerCase(),
                        onPressed: enabled ? onClear : null,
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
        ),
      ],
    );
  }
}
