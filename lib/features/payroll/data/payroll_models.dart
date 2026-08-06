class PayrollCycleResponse {
  const PayrollCycleResponse({
    required this.id,
    required this.month,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.employeeCount,
    required this.totalGross,
    required this.totalDeductions,
    required this.totalNet,
  });

  factory PayrollCycleResponse.fromJson(Map<String, dynamic> json) {
    return PayrollCycleResponse(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      status: json['status'] as String,
      employeeCount: json['employeeCount'] as int,
      totalGross: (json['totalGross'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
      totalNet: (json['totalNet'] as num).toDouble(),
    );
  }

  final String id;
  final int month;
  final int year;
  final String startDate;
  final String endDate;
  final String status;
  final int employeeCount;
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
}

class PayrollRunResponse {
  const PayrollRunResponse({
    required this.id,
    required this.employeeId,
    required this.employeeFullName,
    required this.employeeNumber,
    this.departmentName,
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
    required this.status,
  });

  factory PayrollRunResponse.fromJson(Map<String, dynamic> json) {
    return PayrollRunResponse(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      employeeNumber: json['employeeNumber'] as String? ?? '',
      departmentName: json['departmentName'] as String?,
      grossSalary: (json['grossSalary'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  final String id;
  final String employeeId;
  final String employeeFullName;
  final String employeeNumber;
  final String? departmentName;
  final double grossSalary;
  final double deductions;
  final double netSalary;
  final String status;
}
