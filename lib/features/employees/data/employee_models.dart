class EmployeeResponse {
  const EmployeeResponse({
    required this.id,
    required this.tenantId,
    required this.employeeNumber,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.email,
    this.phone,
    this.hireDate,
    this.employmentType,
    this.qualification,
    required this.status,
    this.branchId,
    this.branchName,
    this.departmentId,
    this.departmentName,
    this.positionId,
    this.positionName,
    this.photoUrl,
    required this.hasLoginAccount,
  });

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeResponse(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      hireDate: json['hireDate'] as String?,
      employmentType: json['employmentType'] as String?,
      qualification: json['qualification'] as String?,
      status: json['status'] as String,
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      positionId: json['positionId'] as String?,
      positionName: json['positionName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      hasLoginAccount: json['hasLoginAccount'] as bool? ?? false,
    );
  }

  final String id;
  final String tenantId;
  final String employeeNumber;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? email;
  final String? phone;
  final String? hireDate;
  final String? employmentType;

  /// Raw backend enum (`BACHELORS`), null on records enrolled before the field
  /// existed or never filled in. Render it through `qualificationLabel`.
  final String? qualification;
  final String status;
  final String? branchId;
  final String? branchName;
  final String? departmentId;
  final String? departmentName;
  final String? positionId;
  final String? positionName;
  final String? photoUrl;
  final bool hasLoginAccount;

  String get fullName => [
        firstName,
        if (middleName != null && middleName!.isNotEmpty) middleName,
        lastName,
      ].join(' ');
}

/// An employee whose birthday is coming up (`GET /employees/birthdays`).
///
/// Carries the *next* occurrence rather than the date of birth, and no birth
/// year at all — the backend withholds it deliberately, since a birthday board
/// that publishes everyone's age is a different and much less welcome feature.
class UpcomingBirthdayResponse {
  const UpcomingBirthdayResponse({
    required this.employeeId,
    required this.fullName,
    this.photoUrl,
    this.departmentName,
    this.positionTitle,
    required this.nextBirthday,
    required this.daysUntil,
  });

  factory UpcomingBirthdayResponse.fromJson(Map<String, dynamic> json) {
    return UpcomingBirthdayResponse(
      employeeId: json['employeeId'] as String,
      fullName: json['fullName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      departmentName: json['departmentName'] as String?,
      positionTitle: json['positionTitle'] as String?,
      nextBirthday: json['nextBirthday'] as String,
      daysUntil: (json['daysUntil'] as num?)?.toInt() ?? 0,
    );
  }

  final String employeeId;
  final String fullName;
  final String? photoUrl;
  final String? departmentName;
  final String? positionTitle;
  final String nextBirthday;

  /// 0 on the day itself.
  final int daysUntil;
}

/// A tenant role available for assignment when inviting an employee
/// (`GET /roles`, ORG_ADMIN-only per `user:create`).
class RoleResponse {
  const RoleResponse({required this.id, required this.name, this.description});

  factory RoleResponse.fromJson(Map<String, dynamic> json) {
    return RoleResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  final String id;
  final String name;
  final String? description;
}
