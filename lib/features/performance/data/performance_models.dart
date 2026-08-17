/// One line of an appraisal: the question, and each side's answer.
///
/// [label], [description] and [weight] are the appraisal's own snapshot of the
/// template taken when the cycle launched, not a live lookup — an appraisal
/// reads the way it read when it was signed even if the template has since been
/// rewritten.
///
/// [reviewerRating] and [reviewerComment] are **null while the employee is not
/// yet entitled to them**: the server strips the reviewer's side out of what it
/// sends the employee until the review is submitted. A null here therefore does
/// not mean "unrated", and nothing in this app should present it as one.
class AppraisalCriterionScore {
  const AppraisalCriterionScore({
    required this.id,
    required this.label,
    this.description,
    required this.type,
    required this.weight,
    required this.sortOrder,
    this.selfRating,
    this.selfComment,
    this.reviewerRating,
    this.reviewerComment,
  });

  factory AppraisalCriterionScore.fromJson(Map<String, dynamic> json) {
    return AppraisalCriterionScore(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'COMPETENCY',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      selfRating: (json['selfRating'] as num?)?.toInt(),
      selfComment: json['selfComment'] as String?,
      reviewerRating: (json['reviewerRating'] as num?)?.toInt(),
      reviewerComment: json['reviewerComment'] as String?,
    );
  }

  final String id;
  final String label;
  final String? description;
  final String type;
  final double weight;
  final int sortOrder;
  final int? selfRating;
  final String? selfComment;
  final int? reviewerRating;
  final String? reviewerComment;
}

/// One employee's appraisal within a review cycle.
///
/// States run PENDING_SELF → PENDING_REVIEW → PENDING_ACKNOWLEDGEMENT →
/// COMPLETED, in that order. A cycle with self-assessment switched off starts
/// its appraisals at PENDING_REVIEW.
///
/// Every reviewer field reads as null until the review is submitted — see
/// [AppraisalCriterionScore]. [finalScore] is the reviewer's score alone;
/// [selfScore] sits beside it and is never averaged in.
///
/// [criteria] is empty in a list response and populated only when one appraisal
/// is fetched on its own.
class Appraisal {
  const Appraisal({
    required this.id,
    required this.cycleId,
    required this.cycleName,
    required this.employeeId,
    required this.employeeFullName,
    required this.status,
    required this.maxRating,
    this.selfOverallComment,
    this.selfSubmittedAt,
    this.selfScore,
    this.reviewerOverallComment,
    this.reviewerSubmittedAt,
    this.reviewedByName,
    this.finalScore,
    this.ratingBand,
    this.employeeComment,
    this.acknowledgedAt,
    required this.criteria,
  });

  factory Appraisal.fromJson(Map<String, dynamic> json) {
    return Appraisal(
      id: json['id'] as String,
      cycleId: json['cycleId'] as String,
      cycleName: json['cycleName'] as String? ?? '',
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      status: json['status'] as String,
      maxRating: (json['maxRating'] as num?)?.toInt() ?? 5,
      selfOverallComment: json['selfOverallComment'] as String?,
      selfSubmittedAt: json['selfSubmittedAt'] as String?,
      selfScore: (json['selfScore'] as num?)?.toDouble(),
      reviewerOverallComment: json['reviewerOverallComment'] as String?,
      reviewerSubmittedAt: json['reviewerSubmittedAt'] as String?,
      reviewedByName: json['reviewedByName'] as String?,
      finalScore: (json['finalScore'] as num?)?.toDouble(),
      ratingBand: json['ratingBand'] as String?,
      employeeComment: json['employeeComment'] as String?,
      acknowledgedAt: json['acknowledgedAt'] as String?,
      criteria: (json['criteria'] as List<dynamic>? ?? [])
          .map((e) => AppraisalCriterionScore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String cycleId;
  final String cycleName;
  final String employeeId;
  final String employeeFullName;
  final String status;
  final int maxRating;
  final String? selfOverallComment;
  final String? selfSubmittedAt;
  final double? selfScore;
  final String? reviewerOverallComment;
  final String? reviewerSubmittedAt;
  final String? reviewedByName;
  final double? finalScore;
  final String? ratingBand;
  final String? employeeComment;
  final String? acknowledgedAt;
  final List<AppraisalCriterionScore> criteria;

  /// The employee has something to write.
  bool get awaitingSelfAssessment => status == 'PENDING_SELF';

  /// The outcome is ready and the employee has not yet acknowledged it.
  bool get awaitingAcknowledgement => status == 'PENDING_ACKNOWLEDGEMENT';
}

/// A target set for one employee.
///
/// [metric] and [targetValue] are free text rather than numbers, matching the
/// API: half of what an SME sets as a goal is not countable, and a numeric field
/// would either exclude those or collect nonsense.
///
/// [progressPercent] is the latest check-in's figure denormalised onto the goal.
class Goal {
  const Goal({
    required this.id,
    required this.employeeId,
    required this.employeeFullName,
    this.cycleName,
    required this.title,
    this.description,
    this.metric,
    this.targetValue,
    this.startDate,
    this.dueDate,
    required this.status,
    required this.progressPercent,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeFullName: json['employeeFullName'] as String? ?? '',
      cycleName: json['cycleName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      metric: json['metric'] as String?,
      targetValue: json['targetValue'] as String?,
      startDate: json['startDate'] as String?,
      dueDate: json['dueDate'] as String?,
      status: json['status'] as String,
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String employeeId;
  final String employeeFullName;
  final String? cycleName;
  final String title;
  final String? description;
  final String? metric;
  final String? targetValue;
  final String? startDate;
  final String? dueDate;
  final String status;
  final int progressPercent;

  bool get isActive => status == 'ACTIVE';
}

/// A check-in on a goal. Append-only — there is no edit or delete path.
class GoalUpdate {
  const GoalUpdate({
    required this.id,
    required this.goalId,
    this.note,
    this.progressPercent,
    this.createdByName,
    required this.createdAt,
  });

  factory GoalUpdate.fromJson(Map<String, dynamic> json) {
    return GoalUpdate(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      note: json['note'] as String?,
      progressPercent: (json['progressPercent'] as num?)?.toInt(),
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  final String id;
  final String goalId;
  final String? note;
  final int? progressPercent;
  final String? createdByName;
  final String createdAt;
}

/// One answer being sent back — a rating and an optional comment on one line.
///
/// Nothing here says which side the answer is for. The endpoint decides that,
/// which is what stops an employee writing into the reviewer's column.
class CriterionAnswer {
  const CriterionAnswer({
    required this.criterionScoreId,
    this.rating,
    this.comment,
  });

  final String criterionScoreId;
  final int? rating;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'criterionScoreId': criterionScoreId,
        'rating': rating,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}
