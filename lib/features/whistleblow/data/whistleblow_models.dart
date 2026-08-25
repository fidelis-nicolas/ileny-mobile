/// The whistleblowing channel's wire shapes.
///
/// Note what none of these carries on an anonymous report: a reporter. That is not a field the
/// app hides — the server has no value to send, because nothing on the row records who filed it.
library;

/// What comes back from filing a report.
///
/// **[passphrase] is returned exactly once.** It is stored only as a hash and cannot be re-sent,
/// so a screen that does not put it in front of the reporter — with the warning that it will not
/// be shown again — has silently locked them out of their own report.
class WhistleblowSubmitResult {
  const WhistleblowSubmitResult({
    required this.caseCode,
    required this.passphrase,
    required this.status,
    required this.submittedAt,
    required this.guidance,
  });

  factory WhistleblowSubmitResult.fromJson(Map<String, dynamic> json) {
    return WhistleblowSubmitResult(
      caseCode: json['caseCode'] as String,
      passphrase: json['passphrase'] as String,
      status: json['status'] as String,
      submittedAt: json['submittedAt'] as String,
      guidance: json['guidance'] as String? ?? '',
    );
  }

  final String caseCode;
  final String passphrase;
  final String status;
  final String submittedAt;

  /// Server-written guidance, shown verbatim beside the credentials.
  final String guidance;
}

/// One message in the conversation on a report.
///
/// [fromHandler] is sent by the server rather than inferred from [authorName] being null: an
/// anonymous reporter's message has no author at all, so reading the side from missing data would
/// render a handler's message as a reporter's the day that handler's account is deleted.
class WhistleblowMessage {
  const WhistleblowMessage({
    required this.id,
    required this.fromHandler,
    this.authorName,
    required this.body,
    required this.sentAt,
  });

  factory WhistleblowMessage.fromJson(Map<String, dynamic> json) {
    return WhistleblowMessage(
      id: json['id'] as String,
      fromHandler: json['fromHandler'] as bool? ?? false,
      authorName: json['authorName'] as String?,
      body: json['body'] as String,
      sentAt: json['sentAt'] as String,
    );
  }

  final String id;
  final bool fromHandler;

  /// The handler's name, or null for a message from an anonymous reporter.
  final String? authorName;
  final String body;
  final String sentAt;
}

/// What the reporter sees when they follow their own report with its case code.
class TrackedWhistleblowReport {
  const TrackedWhistleblowReport({
    required this.caseCode,
    required this.category,
    required this.subject,
    required this.body,
    required this.status,
    this.outcomeNote,
    required this.submittedAt,
    this.closedAt,
    required this.messages,
  });

  factory TrackedWhistleblowReport.fromJson(Map<String, dynamic> json) {
    return TrackedWhistleblowReport(
      caseCode: json['caseCode'] as String,
      category: json['category'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      status: json['status'] as String,
      outcomeNote: json['outcomeNote'] as String?,
      submittedAt: json['submittedAt'] as String,
      closedAt: json['closedAt'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((item) => WhistleblowMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String caseCode;
  final String category;
  final String subject;
  final String body;
  final String status;

  /// The standing answer to "what came of this", shown beside the status.
  final String? outcomeNote;
  final String submittedAt;
  final String? closedAt;
  final List<WhistleblowMessage> messages;
}

/// Display names for the fixed category list. `OTHER` is the escape hatch — somebody who cannot
/// find their situation on the list must not be stopped from reporting it.
const kWhistleblowCategories = <String, String>{
  'FRAUD': 'Fraud',
  'THEFT': 'Theft',
  'CORRUPTION': 'Corruption',
  'HARASSMENT': 'Harassment',
  'DISCRIMINATION': 'Discrimination',
  'SAFETY': 'Health & safety',
  'POLICY_BREACH': 'Policy breach',
  'OTHER': 'Something else',
};

/// Display names for the report states.
///
/// `ACTION_TAKEN` and `DISMISSED` are both endings and are deliberately distinct: the difference
/// is what the person who took the risk of reporting most wants to know.
const kWhistleblowStatuses = <String, String>{
  'SUBMITTED': 'Submitted',
  'UNDER_REVIEW': 'Under review',
  'ACTION_TAKEN': 'Action taken',
  'DISMISSED': 'Dismissed',
  'CLOSED': 'Closed',
};
