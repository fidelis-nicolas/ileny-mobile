class DisciplinaryActionResponse {
  const DisciplinaryActionResponse({
    required this.id,
    required this.disciplinaryCaseId,
    required this.actionType,
    required this.actionDate,
    required this.issuedByName,
    this.notes,
    this.fileUrl,
    required this.createdAt,
  });

  factory DisciplinaryActionResponse.fromJson(Map<String, dynamic> json) {
    return DisciplinaryActionResponse(
      id: json['id'] as String,
      disciplinaryCaseId: json['disciplinaryCaseId'] as String,
      actionType: json['actionType'] as String,
      actionDate: json['actionDate'] as String,
      issuedByName: json['issuedByName'] as String? ?? '',
      notes: json['notes'] as String?,
      fileUrl: json['fileUrl'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  final String id;
  final String disciplinaryCaseId;
  final String actionType;
  final String actionDate;
  final String issuedByName;
  final String? notes;
  final String? fileUrl;
  final String createdAt;
}

class DisciplinaryCaseResponse {
  const DisciplinaryCaseResponse({
    required this.id,
    required this.employeeId,
    required this.employeeFullName,
    required this.reportedByName,
    required this.category,
    required this.description,
    required this.incidentDate,
    required this.status,
    this.resolutionNotes,
    required this.createdAt,
    required this.actions,
  });

  factory DisciplinaryCaseResponse.fromJson(Map<String, dynamic> json) {
    return DisciplinaryCaseResponse(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      reportedByName: json['reportedByName'] as String? ?? '',
      category: json['category'] as String,
      description: json['description'] as String,
      incidentDate: json['incidentDate'] as String,
      status: json['status'] as String,
      resolutionNotes: json['resolutionNotes'] as String?,
      createdAt: json['createdAt'] as String,
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((e) => DisciplinaryActionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String employeeId;
  final String employeeFullName;
  final String reportedByName;
  final String category;
  final String description;
  final String incidentDate;
  final String status;
  final String? resolutionNotes;
  final String createdAt;
  final List<DisciplinaryActionResponse> actions;
}
