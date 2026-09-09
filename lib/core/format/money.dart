import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Money as an amount a person can read, rather than a bare `toStringAsFixed`.
///
/// The currency is fixed to the naira. The API does carry a per-tenant currency
/// on the tenant record, but it is not on anything the mobile session fetches,
/// so formatting by it would mean inventing a value the client cannot see. This
/// matches the choice already made for the subscription screen; if the tenant
/// currency ever reaches the client, both call sites should switch together.
String formatMoney(double amount, {int decimalDigits = 2}) {
  // Round first, then test for zero. Two things depend on that order: an amount
  // that only rounds to zero must not keep a sign it no longer earns, and Dart
  // preserves the sign of `-0.0` — which is exactly what negating a zero
  // deductions figure produces — so an unrounded check would still print
  // "-₦0.00".
  final factor = math.pow(10, decimalDigits);
  final rounded = (amount * factor).round() / factor;

  return NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: decimalDigits,
  ).format(rounded == 0 ? 0 : rounded);
}
