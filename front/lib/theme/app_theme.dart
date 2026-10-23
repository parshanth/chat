import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF101511);
  static const backgroundSecondary = Color(0xFF171E18);
  static const surface = Color(0xFF202922);
  static const elevated = Color(0xFF29342B);
  static const textPrimary = Color(0xFFF5F4EC);
  static const textSecondary = Color(0xFFA8B4A8);
  static const textSubtle = Color(0xFF849184);
  static const border = Color(0xFF354237);
  static const accent = Color(0xFFD6F078);
  static const accentSecondary = Color(0xFF75C6A0);
  static const onAccent = Color(0xFF172016);
  static const onAccentMuted = Color(0xFF34431F);
  static const error = Color(0xFFFF8585);
  static const success = Color(0xFF75D99A);

  // Warm-white input tokens
  static const inputFill = Color(0xFFF4F3ED);
  static const inputText = Color(0xFF172016);
  static const inputHint = Color(0xFF687368);
  static const inputIcon = Color(0xFF455349);
  static const inputBorder = Color(0xFFD7DED6);
  static const inputFocusBorder = Color(0xFF527B45);
  static const inputError = Color(0xFFB4232F);

  // ---- Temporary aliases for screens not yet migrated ----
  // Delete these once login, register and the shared widgets use the new names.
  static const surfaceElevated = elevated;
  static const textSupporting = textSubtle;
  static const selected = elevated;
  static const primary = accent;
  static const primaryPressed = accent;
  static const warning = textSubtle;

  /// Present / Absent / Unmarked. Always pair with a text label or icon.
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return success;
      case 'absent':
        return error;
      default:
        return textSubtle;
    }
  }
}

class AppText {
  AppText._();

  static TextStyle display(double size, {Color? color, double? height}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: height,
        letterSpacing: -0.02 * size,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle title(double size, {Color? color}) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * size,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        height: 1.4,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  /// Uppercase label style. Pass strings that are already uppercase.
  static TextStyle meta({Color? color}) => GoogleFonts.dmSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color ?? AppColors.textSubtle,
      );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  static const double radiusInput = 10;
  static const double radiusButton = 12;
  static const double radiusCard = 16;

  static const double formMaxWidth = 420;
  static const double contentMaxWidth = 600;
}

class AppInputs {
  AppInputs._();

  /// Text style for text typed into a warm-white field.
  static TextStyle get fieldText => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.inputText,
      );

  /// Same as [fieldText]; kept so existing screens keep compiling.
  static TextStyle get valueStyle => fieldText;

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Warm-white field. Put a [FieldLabel] above it instead of using labelText.
  /// [hint], [icon] and [suffix] match the previous signature.
  static InputDecoration decoration({
    String? hint,
    IconData? icon,
    Widget? suffix,
    Widget? prefix,
    String? errorText,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.inputFill,
      hintStyle: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.inputHint,
      ),
      prefixIcon:
          prefix ?? (icon == null ? null : Icon(icon, size: 20)),
      suffixIcon: suffix,
      prefixIconColor: AppColors.inputIcon,
      suffixIconColor: AppColors.inputIcon,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
      errorMaxLines: 3,
      // Validation text sits on the dark background, so it uses the light red.
      errorStyle: GoogleFonts.dmSans(
        fontSize: 12.5,
        height: 1.3,
        color: AppColors.error,
      ),
      border: _border(AppColors.inputBorder),
      enabledBorder: _border(AppColors.inputBorder),
      disabledBorder: _border(AppColors.inputBorder),
      focusedBorder: _border(AppColors.inputFocusBorder, 1.5),
      errorBorder: _border(AppColors.inputError),
      focusedErrorBorder: _border(AppColors.inputError, 1.5),
    );
  }
}

/// Label that sits above a field, on the dark background.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppText.body(
          13.5,
          color: AppColors.textSecondary,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  /// Works as `AppTheme.dark(context)` or `AppTheme.dark()` (e.g. in
  /// `MaterialApp(theme: AppTheme.dark())`). The theme is built from a fresh
  /// dark ThemeData, so it does not depend on the inherited theme.
  static ThemeData dark([BuildContext? context]) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme)
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          displayLarge: AppText.display(48),
          displayMedium: AppText.display(40),
          displaySmall: AppText.display(32),
          headlineLarge: AppText.title(28),
          headlineMedium: AppText.title(24),
          headlineSmall: AppText.title(22),
          titleLarge: AppText.title(20),
          titleMedium: AppText.title(16),
          titleSmall: AppText.title(14),
        );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accentSecondary,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.error,
      onError: AppColors.onAccent,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.elevated,
      surfaceContainerHighest: AppColors.elevated,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
    );
    final buttonText = GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.elevated, // dropdown menu background
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppText.title(18),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppText.title(20),
        contentTextStyle: AppText.body(14.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.elevated,
        contentTextStyle: AppText.body(14, color: AppColors.textPrimary),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.elevated,
        circularTrackColor: AppColors.elevated,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.inputFocusBorder,
        selectionColor: AppColors.accent.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.inputFocusBorder,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: AppText.body(14.5, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppInputs.fieldText,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 15,
            color: AppColors.inputHint,
          ),
          suffixIconColor: AppColors.inputIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            borderSide: const BorderSide(
              color: AppColors.inputFocusBorder,
              width: 1.5,
            ),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.elevated),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        headerBackgroundColor: AppColors.elevated,
        headerForegroundColor: AppColors.textPrimary,
        headerHelpStyle: AppText.meta(),
        dividerColor: AppColors.border,
        weekdayStyle: AppText.body(
          13,
          color: AppColors.textSubtle,
          weight: FontWeight.w600,
        ),
        dayStyle: AppText.body(14, color: AppColors.textPrimary),
        yearStyle: AppText.body(15, color: AppColors.textPrimary),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onAccent;
          }
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSubtle.withValues(alpha: 0.5);
          }
          return AppColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onAccent;
          }
          return AppColors.accent;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        todayBorder: const BorderSide(color: AppColors.accent),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onAccent;
          }
          return AppColors.textPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.elevated,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : AppColors.textPrimary,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.elevated,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : AppColors.textPrimary,
        ),
        dialBackgroundColor: AppColors.elevated,
        dialHandColor: AppColors.accent,
        dialTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : AppColors.textPrimary,
        ),
        entryModeIconColor: AppColors.textSecondary,
        helpTextStyle: AppText.meta(),
      ),
      // Primary action: solid lime, dark text.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSubtle;
            }
            return AppColors.onAccent;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.elevated;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.accentSecondary;
            }
            return AppColors.accent;
          }),
        ),
      ),
      // Secondary action: outlined, readable text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSubtle;
            }
            return AppColors.textPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.border);
            }
            return const BorderSide(color: AppColors.textSubtle);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSubtle;
            }
            return AppColors.accent;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSubtle.withValues(alpha: 0.5);
            }
            return AppColors.textSecondary;
          }),
        ),
      ),
    );
  }
}