import 'package:intl/intl.dart';

/// Display helpers shared by the discipline screens.
///
/// Deliberately derived rather than a lookup table: the backend sends raw enum
/// names (`POLICY_VIOLATION`, `UNDER_INVESTIGATION`) and a hardcoded map would
/// silently render a newly added category as a blank or a crash until the app
/// shipped again. Deriving the shape means a server-side addition reads
/// sensibly with no mobile release at all.
String humaniseEnum(String enumName) {
  final words = enumName.toLowerCase().replaceAll('_', ' ');
  if (words.isEmpty) return words;
  return words[0].toUpperCase() + words.substring(1);
}

/// `2026-08-10` -> `10 Aug 2026`. Falls back to the raw value rather than
/// throwing, so an unexpected format degrades to something readable.
String formatCaseDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('d MMM y').format(date);
}
