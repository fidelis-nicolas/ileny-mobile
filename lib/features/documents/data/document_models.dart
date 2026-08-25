/// One line of the caller's document checklist: what the organisation asks for, and what they
/// have filed against it.
///
/// The server produces one of these per live requirement whether or not anything has been
/// uploaded, so the screen can show what is still needed without a second request. [status] is
/// worked out on read rather than stored, which is what lets a document go out of date on its own
/// the morning after it expires.
class DocumentChecklistItem {
  const DocumentChecklistItem({
    required this.requirementId,
    required this.name,
    this.description,
    required this.mandatory,
    required this.expires,
    required this.status,
    this.documentId,
    this.fileUrl,
    this.uploadedAt,
    this.expiresOn,
  });

  factory DocumentChecklistItem.fromJson(Map<String, dynamic> json) {
    return DocumentChecklistItem(
      requirementId: json['requirementId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      mandatory: json['mandatory'] as bool? ?? false,
      expires: json['expires'] as bool? ?? false,
      status: json['status'] as String,
      documentId: json['documentId'] as String?,
      fileUrl: json['fileUrl'] as String?,
      uploadedAt: json['uploadedAt'] as String?,
      expiresOn: json['expiresOn'] as String?,
    );
  }

  final String requirementId;
  final String name;

  /// Guidance from HR — accepted formats, what counts, who to ask.
  final String? description;

  /// Whether staff must provide it.
  ///
  /// Nothing is blocked by a missing mandatory document: no sign-in is refused and no payroll is
  /// held. It changes what this list says, and that is deliberate — the usual reason a document
  /// is missing is that a university or an embassy has not produced it yet.
  final bool mandatory;

  /// Whether the document goes out of date. When true, an upload must carry an expiry.
  final bool expires;

  /// One of `MISSING`, `PROVIDED`, `EXPIRED`.
  final String status;

  /// The most recent document filed against this requirement, or null.
  final String? documentId;
  final String? fileUrl;
  final String? uploadedAt;
  final String? expiresOn;

  bool get isMissing => status == 'MISSING';
  bool get isExpired => status == 'EXPIRED';
}

/// Metadata for one filed document. The file itself is fetched from `/files/**`.
class EmployeeDocument {
  const EmployeeDocument({
    required this.id,
    required this.documentType,
    this.documentRequirementId,
    this.documentRequirementName,
    this.expiresOn,
    required this.fileUrl,
    this.uploadedByName,
    required this.uploadedAt,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id'] as String,
      documentType: json['documentType'] as String,
      documentRequirementId: json['documentRequirementId'] as String?,
      documentRequirementName: json['documentRequirementName'] as String?,
      expiresOn: json['expiresOn'] as String?,
      fileUrl: json['fileUrl'] as String,
      uploadedByName: json['uploadedByName'] as String?,
      uploadedAt: json['uploadedAt'] as String,
    );
  }

  final String id;

  /// The label this is grouped under — the requirement's own name when it answers one, so the
  /// checklist and the document list never call the same thing two different things.
  final String documentType;
  final String? documentRequirementId;
  final String? documentRequirementName;
  final String? expiresOn;
  final String fileUrl;
  final String? uploadedByName;
  final String uploadedAt;
}
