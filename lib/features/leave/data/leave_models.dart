class LeaveTypeResponse {
  const LeaveTypeResponse({
    required this.id,
    required this.name,
    this.description,
    this.defaultDaysPerYear,
    this.isPaid,
    this.requiresApproval,
  });

  factory LeaveTypeResponse.fromJson(Map<String, dynamic> json) {
    return LeaveTypeResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      defaultDaysPerYear: (json['defaultDaysPerYear'] as num?)?.toDouble(),
      isPaid: json['isPaid'] as bool?,
      requiresApproval: json['requiresApproval'] as bool?,
    );
  }

  final String id;
  final String name;
  final String? description;
  final double? defaultDaysPerYear;
  final bool? isPaid;
  final bool? requiresApproval;
}

class LeaveBalanceResponse {
  const LeaveBalanceResponse({
    required this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
  });

  factory LeaveBalanceResponse.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceResponse(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      leaveTypeId: json['leaveTypeId'] as String,
      leaveTypeName: json['leaveTypeName'] as String? ?? '',
      year: json['year'] as int,
      totalDays: (json['totalDays'] as num).toDouble(),
      usedDays: (json['usedDays'] as num).toDouble(),
      remainingDays: (json['remainingDays'] as num).toDouble(),
    );
  }

  final String id;
  final String employeeId;
  final String leaveTypeId;
  final String leaveTypeName;
  final int year;
  final double totalDays;
  final double usedDays;
  final double remainingDays;
}

class LeaveRequestResponse {
  const LeaveRequestResponse({
    required this.id,
    required this.employeeId,
    required this.employeeFullName,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.daysRequested,
    this.reason,
    required this.status,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
  });

  factory LeaveRequestResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestResponse(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      leaveTypeId: json['leaveTypeId'] as String,
      leaveTypeName: json['leaveTypeName'] as String? ?? '',
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      daysRequested: (json['daysRequested'] as num).toDouble(),
      reason: json['reason'] as String?,
      status: json['status'] as String,
      approvedById: json['approvedById'] as String?,
      approvedByName: json['approvedByName'] as String?,
      approvedAt: json['approvedAt'] as String?,
    );
  }

  final String id;
  final String employeeId;
  final String employeeFullName;
  final String leaveTypeId;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final double daysRequested;
  final String? reason;
  final String status;
  final String? approvedById;
  final String? approvedByName;
  final String? approvedAt;
}
