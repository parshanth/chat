import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../utils/secure_storage.dart';
import 'add_attendance_screen.dart';
import 'attendance_summary_screen.dart';
import 'login_screen.dart';
import 'members_screen.dart';

// ---- Art direction tokens (local to this screen) ----
class _C {
  static const background = Color(0xFF090A0B);
  static const surface = Color(0xFF151719);
  static const elevated = Color(0xFF1C1F22);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFA1A5AA);
  static const textSubtle = Color(0xFF747A80);
  static const border = Color(0xFF292D31);
  static const accent = Color(0xFFD6F078);
  static const accentSecondary = Color(0xFF75D99A);
  static const onAccent = Color(0xFF171918);
  static const onAccentMuted = Color(0xFF505650);
  static const error = Color(0xFFFF8585);
}

// ---- Church branding ----
class _Brand {
  static const churchName = 'Jehovah Jireh Light of Life';
  static const denomination = 'AG CHURCH';
}

// ---- Type system: Manrope (display) + DM Sans (body) ----
class _T {
  static TextStyle display(double size, {Color? color, double? height}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: height,
        letterSpacing: -0.02 * size,
        color: color ?? _C.textPrimary,
      );

  static TextStyle title(double size, {Color? color}) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01 * size,
    color: color ?? _C.textPrimary,
  );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        height: 1.4,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? _C.textSecondary,
      );

  static TextStyle meta({Color? color}) => GoogleFonts.dmSans(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: color ?? _C.textSubtle,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialUser});

  final AuthUser? initialUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _verifyingSession = false;
  bool _wasBackgrounded = false;
  String? _number;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _number = widget.initialUser?.number;
    if (widget.initialUser == null) {
      _isLoading = true;
      _verifySession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _verifySession();
    }
  }

  Future<void> _verifySession() async {
    if (_verifyingSession) return;
    _verifyingSession = true;

    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _number = user.number;
        _isLoading = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401 || error.statusCode == 403) {
        _returnToLogin();
        return;
      }

      _keepSessionAfterVerificationFailure(error);
    } catch (_) {
      _keepSessionAfterVerificationFailure(
        AuthNetworkException(
          'Unable to verify your session. Your saved login is retained.',
        ),
      );
    } finally {
      _verifyingSession = false;
    }
  }

  void _keepSessionAfterVerificationFailure(AuthException error) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (error) {
      if (!mounted) return;
      try {
        final token = await SecureStorage.getToken();
        if (token == null || token.isEmpty) {
          _returnToLogin();
          return;
        }
      } catch (_) {
        // Keep the current screen if secure storage cannot confirm logout.
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to clear the saved session: $error')),
      );
      return;
    }

    if (!mounted) return;

    _returnToLogin();
  }

  void _returnToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openMembers() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MembersScreen()));
  }

  void _openAttendance() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddAttendanceScreen()));
  }

  void _openSummary() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AttendanceSummaryScreen()));
  }

  /// Top bar now only holds the logout button (icon and name were removed).
  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: _isLoading ? null : _logout,
          tooltip: 'Logout',
          color: _C.textSecondary,
          disabledColor: _C.textSubtle.withValues(alpha: 0.5),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: _C.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _greeting() {
    final number = _number ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: 'Welcome to ${_Brand.churchName}',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Welcome to\n'),
                TextSpan(
                  text: _Brand.churchName,
                  style: const TextStyle(color: _C.accent),
                ),
              ],
            ),
            style: _T.display(36, height: 1.1),
          ),
        ),
        const SizedBox(height: 10),
        Text(_Brand.denomination, style: _T.meta(color: _C.accentSecondary)),
        if (number.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('SIGNED IN AS', style: _T.meta()),
          const SizedBox(height: 4),
          Text(
            number,
            style: _T.body(16, color: _C.textPrimary, weight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  /// The one primary action: a solid accent block.
  Widget _primaryAction() {
    return Material(
      color: _C.accent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openAttendance,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_rounded,
                    size: 26,
                    color: _C.onAccent,
                  ),
                  const Spacer(),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _C.onAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: _C.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text('Attendance', style: _T.display(30, color: _C.onAccent)),
              const SizedBox(height: 6),
              Text(
                'Record Sunday attendance',
                style: _T.body(
                  15,
                  color: _C.onAccentMuted,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: _C.elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: _C.accentSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _T.title(17)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _T.body(13.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: _C.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryGroup() {
    return Material(
      color: _C.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.border),
      ),
      child: Column(
        children: [
          _row(
            icon: Icons.analytics_outlined,
            title: 'Attendance Summary',
            subtitle: 'View weekly records and member history',
            onTap: _openSummary,
          ),
          const Divider(height: 1, thickness: 1, color: _C.border),
          _row(
            icon: Icons.people_alt_outlined,
            title: 'Member Management',
            subtitle: 'Add, search, edit and manage members',
            onTap: _openMembers,
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _greeting(),
          const SizedBox(height: 36),
          _primaryAction(),
          const SizedBox(height: 32),
          Text('REPORTS AND PEOPLE', style: _T.meta()),
          const SizedBox(height: 12),
          _secondaryGroup(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _C.background,
        colorScheme: const ColorScheme.dark(
          primary: _C.accent,
          onPrimary: _C.onAccent,
          surface: _C.surface,
          onSurface: _C.textPrimary,
          error: _C.error,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _C.elevated,
          contentTextStyle: _T.body(14, color: _C.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _C.border),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _C.accent,
        ),
      ),
      child: Scaffold(
        backgroundColor: _C.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _content(),
                  ),
                  Positioned(top: 4, right: 16, child: _topBar()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
