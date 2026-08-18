import 'package:flutter/material.dart';

/// Brand palette for ileny.
///
/// These are the raw brand constants — the values that mean the same thing
/// regardless of who is looking at them or in which brightness. They mirror
/// the web client's `--primary-*` and `--brand-accent` scales in
/// `front-end/web/src/styles/globals.css`; keep the two in step.
///
/// Screens should **not** read from this class directly. Colors that depend on
/// brightness (anything used as a background, a surface, or as type) live on
/// [AppPalette] and are reached with `context.palette`. Reading a `const` from
/// here inside a widget is exactly what makes a screen unreadable in dark mode.
class AppColors {
  AppColors._();

  // Brand primary scale — ileny deep green, from ileny_mark.svg.
  static const Color primary50 = Color(0xFFEFF6F2);
  static const Color primary100 = Color(0xFFD9E8E0);
  static const Color primary200 = Color(0xFFB3CDC0);
  static const Color primary300 = Color(0xFF7FA695);
  static const Color primary400 = Color(0xFF4C7E6B);
  static const Color primary500 = Color(0xFF2E5C4B);
  static const Color primary600 = Color(0xFF22483A);
  static const Color primary700 = Color(0xFF1E4038);
  static const Color primary800 = Color(0xFF1A3830);
  static const Color primary900 = Color(0xFF12241D);

  // Brand accent — ileny terracotta, from ileny_mark.svg.
  static const Color accent = Color(0xFFC1663F);
}

/// Every color that changes with brightness, resolved from the ambient theme.
///
/// Registered as a [ThemeExtension] on both themes in `AppTheme`, so a widget
/// reaches it with `context.palette.textMuted` and automatically gets the right
/// value in light and dark. The field names are semantic (`textMuted`,
/// `surfaceAlt`) rather than literal (`grey`, `cream`) so that swapping a value
/// stays a one-line change here.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.accent,
    required this.accentInk,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.inputFill,
    required this.inputBorder,
    required this.textHeading,
    required this.textBody,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.shadowTint,
  });

  final Brightness brightness;

  /// Brand green as it should appear on this brightness's background — the
  /// deep #22483A in light, lifted to a sage in dark where the deep green is
  /// unreadable as type. Safe both as type and as an icon color.
  final Color primary;

  /// Tinted brand fill for chips, selected states, and icon plates.
  final Color primarySoft;

  /// Type/icon color that sits on top of a [primary] fill.
  final Color onPrimary;

  /// Terracotta as a *fill* — buttons, rules, indicators. Not type: at 3.6:1 on
  /// the paper background it fails AA at small sizes.
  final Color accent;

  /// Terracotta as *type*. Same hue, darkened (light) or lightened (dark) to
  /// clear AA. Use this anywhere the accent carries words.
  final Color accentInk;

  /// The page itself — warm paper, never pure white.
  final Color background;

  /// Cards and raised surfaces, one step off [background].
  final Color surface;

  /// Recessed fills: KPI plates, list-row backgrounds, empty states.
  final Color surfaceAlt;

  /// Hairline dividers and card outlines.
  final Color border;

  final Color inputFill;
  final Color inputBorder;

  /// Display type — titles and figures. The highest-contrast ink.
  final Color textHeading;

  /// Ordinary body copy.
  final Color textBody;

  /// Captions, labels, secondary rows. Still clears AA on [background].
  final Color textMuted;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Shadows are tinted with the ink hue rather than neutral black: on a warm
  /// paper background a grey shadow goes muddy.
  final Color shadowTint;

  /// Three elevation steps, so "how raised is this" stays a question with three
  /// answers: [elevation1] resting surfaces, [elevation2] things that pop,
  /// [elevation3] things above the whole page. Each is a stacked pair — a tight
  /// contact shadow plus a wide soft one — because a single blurred shadow
  /// reads as a 2015 drop shadow.
  List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: shadowTint.withValues(alpha: brightness == Brightness.dark ? 0.40 : 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadowTint.withValues(alpha: brightness == Brightness.dark ? 0.00 : 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  List<BoxShadow> get elevation2 => [
        BoxShadow(
          color: shadowTint.withValues(alpha: brightness == Brightness.dark ? 0.40 : 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadowTint.withValues(alpha: brightness == Brightness.dark ? 0.60 : 0.12),
          blurRadius: 20,
          spreadRadius: -8,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get elevation3 => [
        BoxShadow(
          color: shadowTint.withValues(alpha: brightness == Brightness.dark ? 0.50 : 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadowTint.withValues(alpha: brightness == Brightness.dark ? 0.70 : 0.16),
          blurRadius: 32,
          spreadRadius: -12,
          offset: const Offset(0, 16),
        ),
      ];

  /// Warm paper neutrals. The lightness steps of an ordinary grey scale rotated
  /// to a warm hue, so ink-on-paper reads classic rather than clinical — and so
  /// the terracotta accent has something to sit on that it doesn't fight.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: AppColors.primary600,
    primarySoft: AppColors.primary50,
    onPrimary: Color(0xFFFFFFFF),
    accent: AppColors.accent,
    accentInk: Color(0xFF9A4A28),
    background: Color(0xFFF7F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0EBE3),
    border: Color(0xFFE4DDD2),
    inputFill: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFDDD5C8),
    textHeading: Color(0xFF1A1714),
    textBody: Color(0xFF403A34),
    textMuted: Color(0xFF6E655C),
    success: Color(0xFF047857),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
    info: Color(0xFF1D4ED8),
    shadowTint: Color(0xFF1A1714),
  );

  /// Warm *ink* counterpart of the light neutrals — the same lightness steps
  /// rotated off cool navy, so the terracotta accent and the serif display type
  /// stay at home here too.
  ///
  /// Note [primary]: the web can use the deep green as a dark-mode fill because
  /// it always pairs it with a light foreground. Mobile leans on the brand green
  /// as *type* far more often, so dark mode lifts it to `primary300` — readable
  /// as words on the ink background, and still fine as a fill under
  /// [onPrimary]'s dark ink.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: AppColors.primary300,
    primarySoft: Color(0xFF1B2E26),
    onPrimary: Color(0xFF14120F),
    accent: AppColors.accent,
    accentInk: Color(0xFFE09A72),
    background: Color(0xFF14120F),
    surface: Color(0xFF1B1815),
    surfaceAlt: Color(0xFF262220),
    border: Color(0xFF2E2A26),
    inputFill: Color(0xFF221F1C),
    inputBorder: Color(0xFF322D28),
    textHeading: Color(0xFFF5F1EA),
    textBody: Color(0xFFDCD5CC),
    textMuted: Color(0xFFA79E93),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    shadowTint: Color(0xFF000000),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? primary,
    Color? primarySoft,
    Color? onPrimary,
    Color? accent,
    Color? accentInk,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? inputFill,
    Color? inputBorder,
    Color? textHeading,
    Color? textBody,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? shadowTint,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      textHeading: textHeading ?? this.textHeading,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      shadowTint: shadowTint ?? this.shadowTint,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      shadowTint: Color.lerp(shadowTint, other.shadowTint, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The brightness-aware palette. Falls back to [AppPalette.light] only if a
  /// widget is built outside `AppTheme`, which in practice means a test that
  /// pumped a bare `MaterialApp`.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
