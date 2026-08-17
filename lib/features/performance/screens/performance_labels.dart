import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';

/// Display helpers shared by the performance screens.
///
/// The appraisal wording is a lookup rather than a derived string, unlike
/// `humaniseEnum` in the discipline screens. That is a deliberate difference:
/// "Pending self" is not what an employee needs to read on their own appraisal,
/// and the whole point of these five lines is to say what the person opening the
/// screen is actually waiting on. A server-side addition falls back to the raw
/// name, which is ugly but never wrong.
const Map<String, String> _myAppraisalStatusLabels = {
  'PENDING_SELF': 'Your self-assessment is due',
  'PENDING_REVIEW': 'Being reviewed',
  'PENDING_ACKNOWLEDGEMENT': 'Ready for you to read',
  'COMPLETED': 'Completed',
  'CANCELLED': 'Cancelled',
};

String appraisalStatusLabel(String status) => _myAppraisalStatusLabels[status] ?? status;

const Map<String, String> _goalStatusLabels = {
  'DRAFT': 'Draft',
  'ACTIVE': 'Active',
  'ACHIEVED': 'Achieved',
  'MISSED': 'Missed',
  'CANCELLED': 'Cancelled',
};

String goalStatusLabel(String status) => _goalStatusLabels[status] ?? status;

const Map<String, String> _criterionTypeLabels = {
  'COMPETENCY': 'Competency',
  'GOAL': 'Goal',
  'VALUE': 'Value',
};

String criterionTypeLabel(String type) => _criterionTypeLabels[type] ?? type;

/// `2026-08-10` -> `10 Aug 2026`. Falls back to the raw value rather than
/// throwing, so an unexpected format degrades to something readable.
String formatPerformanceDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('d MMM y').format(date);
}

/// Colour tracks how much attention the item still needs — amber while someone
/// is being waited on, green once done, muted once it no longer counts.
Color appraisalStatusColour(String status) {
  switch (status) {
    case 'PENDING_SELF':
    case 'PENDING_ACKNOWLEDGEMENT':
      return AppColors.accentOrange;
    case 'COMPLETED':
      return AppColors.primaryGreen;
    default:
      return AppColors.textMuted;
  }
}

Color goalStatusColour(String status) {
  switch (status) {
    case 'ACHIEVED':
      return AppColors.primaryGreen;
    case 'MISSED':
      return AppColors.accentOrange;
    case 'ACTIVE':
      return AppColors.primaryGreen;
    default:
      return AppColors.textMuted;
  }
}
