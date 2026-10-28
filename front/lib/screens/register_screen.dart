import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Same pure-black stage as the login screen so the logo blends in.
  static const Color _stage = Colors.black;

  @override
  void dispose() {
    _numberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.register(
        number: _numberController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 44,
          ),
          title: const Text('Account created', textAlign: TextAlign.center),
          content: const Text(
            'You can sign in once your access is approved.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue to login'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError('Unable to connect to the server. Please try again.');
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

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      color: AppColors.inputIcon,
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
      ),
    );
  }

  /// Logo hero: feathered into the black, on a soft glow.
  Widget _logoHero({required double size}) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final logo = Stack(
      alignment: Alignment.center,
      children: [
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    // Slightly smaller than login: this screen has three fields.
    final logoSize = keyboardOpen
        ? 90.0
        : (media.size.width * 0.5).clamp(140.0, 220.0);

    return Theme(
      data: AppTheme.dark(context),
      child: Scaffold(
        backgroundColor: _stage,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const SizedBox.shrink(),
        ),
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
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _numberController,
                          readOnly: _isLoading,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.newUsername],
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
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.newPassword],
                          style: _fieldStyle,
                          cursorColor: AppColors.success,
                          decoration: _fieldDecoration(
                            hint: 'Password (6+ characters)',
                            icon: Icons.lock_outline,
                            suffix: _visibilityToggle(
                              obscured: _obscurePassword,
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a password';
                            }
                            if (value.length < 6) {
                              return 'Use at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmFocus,
                          readOnly: _isLoading,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          enableSuggestions: false,
                          autocorrect: false,
                          style: _fieldStyle,
                          cursorColor: AppColors.success,
                          decoration: _fieldDecoration(
                            hint: 'Confirm password',
                            icon: Icons.lock_reset_outlined,
                            suffix: _visibilityToggle(
                              obscured: _obscureConfirmPassword,
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _register,
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                            child: _isLoading
                                ? Semantics(
                                    label: 'Creating account',
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
                                    'Create account',
                                    style: GoogleFonts.rubik(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.success,
                              disabledForegroundColor:
                                  AppColors.textSupporting,
                              minimumSize: const Size(48, 48),
                              tapTargetSize: MaterialTapTargetSize.padded,
                              textStyle: GoogleFonts.rubik(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Sign in'),
                          ),
                        ),
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