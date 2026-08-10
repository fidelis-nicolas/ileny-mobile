class PayslipResponse {
  const PayslipResponse({
    required this.id,
    required this.employeeId,
    required this.employeeFullName,
    required this.month,
    required this.year,
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
    this.fileUrl,
    required this.emailStatus,
    required this.generatedAt,
    this.emailedAt,
  });

  factory PayslipResponse.fromJson(Map<String, dynamic> json) {
    return PayslipResponse(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      month: json['month'] as int,
      year: json['year'] as int,
      grossSalary: (json['grossSalary'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      fileUrl: json['fileUrl'] as String?,
      emailStatus: json['emailStatus'] as String,
      generatedAt: json['generatedAt'] as String,
      emailedAt: json['emailedAt'] as String?,
    );
  }

  final String id;
  final String employeeId;
  final String employeeFullName;
  final int month;
  final int year;
  final double grossSalary;
  final double deductions;
  final double netSalary;

  /// Informational only — the backend derives the storage path itself.
  /// Fetch bytes via [PayslipRepository.download], not this URL.
  final String? fileUrl;
  final String emailStatus;
  final String generatedAt;
  final String? emailedAt;
}
