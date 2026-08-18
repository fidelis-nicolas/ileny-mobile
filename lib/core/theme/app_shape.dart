import 'package:flutter/widgets.dart';

/// Corner radii, derived from the web client's `--radius: 12px` the same way
/// its scale is — so a card here and a card there round to the same curve.
///
/// Soft enough to read as current, short of the fully pill-shaped look that
/// dates just as fast in the other direction.
class AppRadius {
  AppRadius._();

  /// Chips, badges, small indicators.
  static const double sm = 8;

  /// Inputs, buttons, list rows — the control radius the system is drawn to.
  static const double md = 12;

  /// Cards and panels.
  static const double lg = 17;

  /// Sheets and dialogs.
  static const double xl = 22;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// The one easing curve in the app. A single answer to "how should this move"
/// is what keeps motion from feeling assembled out of spare parts.
const Curve kEaseOutSoft = Cubic(0.2, 0.7, 0.3, 1);

const Duration kMotionFast = Duration(milliseconds: 150);
const Duration kMotionMedium = Duration(milliseconds: 220);
