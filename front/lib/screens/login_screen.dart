import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pending_approval_dialog.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Text style for typed values on the black auth screens.
final TextStyle _fieldStyle = GoogleFonts.rubik(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: AppColors.textPrimary,
);

OutlineInputBorder _pill(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(32),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Pill-shaped, glass-like field made to sit on pure black beside the logo.
/// Quiet at rest, lights up green when focused.
InputDecoration _fieldDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.rubik(
      fontSize: 15,
      color: AppColors.textSupporting,
    ),
    filled: true,
    fillColor: Colors.white.withAlpha(14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    prefixIcon: Padding(
      padding: const EdgeInsetsDirectional.only(start: 18, end: 10),
      child: Icon(icon, size: 20),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    prefixIconColor: AppColors.inputIcon,
    suffixIcon: suffix == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: suffix,
          ),
    border: _pill(Colors.white.withAlpha(28)),
    enabledBorder: _pill(Colors.white.withAlpha(28)),
    disabledBorder: _pill(Colors.white.withAlpha(16)),
    focusedBorder: _pill(AppColors.success, 1.5),
    errorBorder: _pill(AppColors.error),
    focusedErrorBorder: _pill(AppColors.error, 1.5),
    errorStyle: GoogleFonts.rubik(fontSize: 12.5, color: AppColors.error),
    errorMaxLines: 2,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // The logo artwork sits on pure black, so the whole screen is pure black
  // too. That way the logo has no visible box and simply "floats".
  static const Color _stage = Colors.black;

  @override
  void dispose() {
    _numberController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        number: _numberController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(initialUser: user)),
      );
    } on PendingApprovalException catch (error) {
      if (mounted) {
        await PendingApprovalDialog.show(context, message: error.message);
      }
    } on AuthException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError(
          'Unable to connect to the server. Check your network and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 20, color: AppColors.error),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  /// The hero. Big, centred, on a soft pool of light, with its edges faded
  /// into the black so any off-black pixels in the PNG never show a border.
  Widget _logoHero({required double size}) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final logo = Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow behind the logo.
        Container(
          width: size * 1.35,
          height: size * 1.35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.success.withAlpha(60),
                AppColors.success.withAlpha(0),
              ],
            ),
          ),
        ),
        // Logo with feathered edges.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const RadialGradient(
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, 0.8, 1.0],
          ).createShader(rect),
          child: Image.asset(
            'assets/church.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            semanticLabel: 'Jehovah Jireh Light of Life AG Church',
          ),
        ),
      ],
    );

    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: reduceMotion
          ? logo
          // The one entrance moment on this screen.
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
              ),
              child: logo,
            ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _login,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
        ),
        child: _isLoading
            ? Semantics(
                label: 'Signing in',
                child: const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Text(
                'Sign in',
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _registerLink() {
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.success,
          disabledForegroundColor: AppColors.textSupporting,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: _isLoading
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
        child: const Text('Create account'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    // Logo takes ~65% of the width on phones, shrinks while typing.
    final logoSize = keyboardOpen
        ? 110.0
        : (media.size.width * 0.65).clamp(180.0, 280.0);

    return Theme(
      data: AppTheme.dark(context),
      child: Scaffold(
        backgroundColor: _stage,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _logoHero(size: logoSize)),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _numberController,
                          readOnly: _isLoading,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.username],
                          style: _fieldStyle,
                          cursorColor: AppColors.success,
                          decoration: _fieldDecoration(
                            hint: 'Number',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          readOnly: _isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.password],
                          style: _fieldStyle,
                          cursorColor: AppColors.success,
                          decoration: _fieldDecoration(
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              color: AppColors.inputIcon,
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _loginButton(),
                        const SizedBox(height: AppSpacing.sm),
                        _registerLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}