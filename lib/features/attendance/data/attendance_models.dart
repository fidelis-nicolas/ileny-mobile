class AttendanceResponse {
  const AttendanceResponse({
    required this.id,
    required this.employeeId,
    required this.employeeFullName,
    required this.attendanceDate,
    this.clockIn,
    this.clockOut,
    this.workHours,
    required this.source,
    required this.status,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      attendanceDate: json['attendanceDate'] as String,
      clockIn: json['clockIn'] as String?,
      clockOut: json['clockOut'] as String?,
      workHours: (json['workHours'] as num?)?.toDouble(),
      source: json['source'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String employeeId;
  final String employeeFullName;
  final String attendanceDate;
  final String? clockIn;
  final String? clockOut;
  final double? workHours;
  final String source;
  final String status;
}

/// A correction request and its approval state. Note there is no field for
/// proposed times — the record carries only the employee's reason, which is
/// why approving one does not itself change the attendance record.
class AttendanceCorrection {
  const AttendanceCorrection({
    required this.id,
    required this.attendanceId,
    required this.employeeId,
    required this.reason,
    required this.status,
    this.approvedAt,
  });

  factory AttendanceCorrection.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrection(
      id: json['id'] as String,
      attendanceId: json['attendanceId'] as String,
      employeeId: json['employeeId'] as String,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String,
      approvedAt: json['approvedAt'] as String?,
    );
  }

  final String id;
  final String attendanceId;
  final String employeeId;
  final String reason;

  /// PENDING, APPROVED, or REJECTED.
  final String status;
  final String? approvedAt;
}

class AttendanceSummaryResponse {
  const AttendanceSummaryResponse({
    required this.employeeId,
    required this.employeeFullName,
    required this.month,
    required this.year,
    required this.daysPresent,
    required this.daysAbsent,
    required this.daysLate,
    required this.totalWorkHours,
  });

  factory AttendanceSummaryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryResponse(
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      month: json['month'] as int,
      year: json['year'] as int,
      daysPresent: json['daysPresent'] as int,
      daysAbsent: json['daysAbsent'] as int,
      daysLate: json['daysLate'] as int,
      totalWorkHours: (json['totalWorkHours'] as num?)?.toDouble() ?? 0,
    );
  }

  final String employeeId;
  final String employeeFullName;
  final int month;
  final int year;
  final int daysPresent;
  final int daysAbsent;
  final int daysLate;
  final double totalWorkHours;
}
