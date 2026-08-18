import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The type system, matching the web client's editorial pairing: a
/// high-contrast serif carries display type (screen titles, card titles, KPI
/// figures), and Inter carries everything functional (nav, lists, forms) where
/// it still out-reads a serif at small sizes.
///
/// Only the weight axis of Fraunces is used — the optical-size and "wonk" axes
/// stay at their defaults, which is the sober, book-typographic end of the
/// family, exactly as `globals.css` sets it on the web.
class AppTypography {
  AppTypography._();

  /// Display serif. Reach for this deliberately; the [TextTheme] below already
  /// applies it to the display/headline/titleLarge slots.
  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      // Fraunces is drawn generously; headlines need the air taken back out.
      letterSpacing: size * -0.015,
    );
  }

  /// The small-caps eyebrow used above section headings and as KPI labels —
  /// the letterspaced counterweight to the serif display type.
  static TextStyle eyebrow(Color color) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.2,
      // The web sets 0.14em; Flutter's letterSpacing is absolute, so this is
      // that ratio resolved against the 11px size.
      letterSpacing: 11 * 0.14,
    );
  }

  /// Figures that sit in a column and must not jitter as they change — KPI
  /// values, money, counts, times.
  static const FontFeature tabularFigures = FontFeature.tabularFigures();

  static TextTheme textTheme({
    required Color heading,
    required Color body,
    required Color muted,
  }) {
    TextStyle sans(double size, FontWeight weight, Color color, {double? height}) {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }

    return TextTheme(
      // Serif — display and headline slots.
      displayLarge: display(size: 40, weight: FontWeight.w600, color: heading),
      displayMedium: display(size: 34, weight: FontWeight.w600, color: heading),
      displaySmall: display(size: 30, weight: FontWeight.w600, color: heading),
      headlineLarge: display(size: 27, weight: FontWeight.w600, color: heading),
      headlineMedium: display(size: 24, weight: FontWeight.w600, color: heading),
      headlineSmall: display(size: 21, weight: FontWeight.w600, color: heading),
      // AppBar titles and card titles — the smallest size the serif still
      // carries comfortably.
      titleLarge: display(size: 19, weight: FontWeight.w600, color: heading),

      // Inter — everything functional.
      titleMedium: sans(16, FontWeight.w600, heading, height: 1.3),
      titleSmall: sans(14, FontWeight.w600, heading, height: 1.3),
      bodyLarge: sans(16, FontWeight.w400, body, height: 1.45),
      bodyMedium: sans(14.5, FontWeight.w400, body, height: 1.45),
      bodySmall: sans(12.5, FontWeight.w400, muted, height: 1.4),
      labelLarge: sans(15, FontWeight.w600, heading, height: 1.2),
      labelMedium: sans(13, FontWeight.w500, muted, height: 1.2),
      labelSmall: sans(11, FontWeight.w500, muted, height: 1.2),
    );
  }
}
