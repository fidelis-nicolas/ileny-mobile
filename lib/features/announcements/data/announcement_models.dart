class AnnouncementResponse {
  const AnnouncementResponse({
    required this.id,
    required this.authorName,
    required this.title,
    required this.body,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.poll,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    final poll = json['poll'];
    return AnnouncementResponse(
      id: json['id'] as String,
      authorName: json['authorName'] as String? ?? '',
      title: json['title'] as String,
      body: json['body'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'NORMAL',
      createdAt: json['createdAt'] as String,
      poll: poll == null ? null : PollResponse.fromJson(poll as Map<String, dynamic>),
    );
  }

  final String id;
  final String authorName;
  final String title;
  final String body;
  final String status;
  final String priority;
  final String createdAt;

  /// Non-null only when this announcement is a poll. Its presence is what decides
  /// whether the detail screen shows a ballot.
  final PollResponse? poll;
}

/// A poll, as served to *this* user.
///
/// The server shapes it per viewer: [myVotedOptionIds] is their own answer, and the
/// counts are present or absent according to the poll's visibility rule and whether
/// they have voted. Two people can receive different bodies for the same poll.
class PollResponse {
  const PollResponse({
    required this.id,
    required this.question,
    required this.allowMultiple,
    required this.anonymous,
    required this.resultsVisibility,
    required this.closed,
    required this.canVote,
    required this.myVotedOptionIds,
    required this.options,
    this.closesAt,
    this.totalVoters,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    return PollResponse(
      id: json['id'] as String,
      question: json['question'] as String,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      anonymous: json['anonymous'] as bool? ?? false,
      resultsVisibility: json['resultsVisibility'] as String? ?? 'AFTER_VOTE',
      closed: json['closed'] as bool? ?? false,
      canVote: json['canVote'] as bool? ?? false,
      closesAt: json['closesAt'] as String?,
      totalVoters: (json['totalVoters'] as num?)?.toInt(),
      myVotedOptionIds:
          (json['myVotedOptionIds'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => PollOptionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String question;
  final bool allowMultiple;
  final bool anonymous;
  final String resultsVisibility;
  final bool closed;

  /// The server's answer to "should the vote controls appear". Folds together
  /// open/closed, audience membership, and whether the account has a staff record.
  ///
  /// The announcement feed is *not* audience-filtered, so polls are routinely
  /// visible to people who cannot answer them. Never re-derive this locally.
  final bool canVote;

  final String? closesAt;

  /// Null when the tally is not visible to this viewer.
  final int? totalVoters;

  final List<String> myVotedOptionIds;
  final List<PollOptionResponse> options;

  bool get hasVoted => myVotedOptionIds.isNotEmpty;

  /// Whether the server sent any counts at all. Derived from the options rather than
  /// from [resultsVisibility], since the rule also depends on the viewer.
  bool get showsCounts => options.any((option) => option.voteCount != null);
}

class PollOptionResponse {
  const PollOptionResponse({
    required this.id,
    required this.label,
    required this.displayOrder,
    this.voteCount,
  });

  factory PollOptionResponse.fromJson(Map<String, dynamic> json) {
    return PollOptionResponse(
      id: json['id'] as String,
      label: json['label'] as String,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      voteCount: (json['voteCount'] as num?)?.toInt(),
    );
  }

  final String id;
  final String label;
  final int displayOrder;

  /// Null means "not shown to you", **not** zero. Rendering it as 0 would show a
  /// confident and wrong result, so the bars are hidden entirely instead.
  final int? voteCount;
}
