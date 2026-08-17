import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/performance_models.dart';
import '../data/performance_repository.dart';
import 'performance_labels.dart';

/// One of the employee's own appraisals: the self-assessment while it is theirs
/// to write, and the outcome once it is not.
///
/// The screen changes shape with the appraisal's state rather than showing
/// everything at once and disabling most of it. There is only ever one thing to
/// do, and which it is is the question the employee opened this to answer.
class MyAppraisalDetailScreen extends StatefulWidget {
  const MyAppraisalDetailScreen({super.key, required this.appraisalId});

  final String appraisalId;

  @override
  State<MyAppraisalDetailScreen> createState() => _MyAppraisalDetailScreenState();
}

class _MyAppraisalDetailScreenState extends State<MyAppraisalDetailScreen> {
  Appraisal? _appraisal;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  /// Answers keyed by criterion id, seeded from the server and edited in place.
  final Map<String, int?> _ratings = {};
  final Map<String, TextEditingController> _comments = {};
  final TextEditingController _overall = TextEditingController();
  final TextEditingController _acknowledgement = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _comments.values) {
      controller.dispose();
    }
    _overall.dispose();
    _acknowledgement.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appraisal =
          await context.read<PerformanceRepository>().myAppraisal(widget.appraisalId);
      if (!mounted) return;
      setState(() {
        _appraisal = appraisal;
        _loading = false;
        _seed(appraisal);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _seed(Appraisal appraisal) {
    _overall.text = appraisal.selfOverallComment ?? '';
    for (final criterion in appraisal.criteria) {
      _ratings[criterion.id] = criterion.selfRating;
      final existing = _comments[criterion.id];
      if (existing == null) {
        _comments[criterion.id] = TextEditingController(text: criterion.selfComment ?? '');
      } else {
        existing.text = criterion.selfComment ?? '';
      }
    }
  }

  List<CriterionAnswer> _answers() {
    return _ratings.entries
        .map((entry) => CriterionAnswer(
              criterionScoreId: entry.key,
              rating: entry.value,
              comment: _comments[entry.key]?.text,
            ))
        .toList();
  }

  int get _unanswered => _ratings.values.where((rating) => rating == null).length;

  Future<void> _run(Future<Appraisal> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _appraisal = updated;
        _saving = false;
        _seed(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appraisal = _appraisal;

    return Scaffold(
      appBar: AppBar(title: Text(appraisal?.cycleName ?? 'Appraisal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : appraisal == null
                  ? const SizedBox.shrink()
                  : _body(appraisal),
    );
  }

  Widget _body(Appraisal appraisal) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          appraisalStatusLabel(appraisal.status),
          style: TextStyle(
            color: appraisalStatusColour(appraisal.status),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (appraisal.awaitingSelfAssessment) ...[
          const SizedBox(height: 6),
          const Text(
            'Rate yourself against each of these, then submit. Your reviewer sees your '
            'answers before writing theirs.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],

        // The outcome, once there is one. Above the sheet because at this stage
        // it is what the employee came for.
        if (appraisal.finalScore != null) ...[
          const SizedBox(height: 16),
          _OutcomeCard(appraisal: appraisal),
        ],

        const SizedBox(height: 20),
        for (final criterion in appraisal.criteria)
          _CriterionCard(
            criterion: criterion,
            maxRating: appraisal.maxRating,
            rating: _ratings[criterion.id],
            comment: _comments[criterion.id]!,
            editable: appraisal.awaitingSelfAssessment,
            onRating: (value) => setState(() => _ratings[criterion.id] = value),
          ),

        if (appraisal.awaitingSelfAssessment) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _overall,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Anything else about your year',
              hintText: "Optional. What the ratings above don't capture.",
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _unanswered == 0
                ? 'All rated. Submitting sends this to your reviewer and you cannot change it '
                    'afterwards.'
                : '$_unanswered ${_unanswered == 1 ? 'criterion' : 'criteria'} left to rate.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => _run(
                            () => context.read<PerformanceRepository>().saveSelfAssessment(
                                  appraisalId: appraisal.id,
                                  answers: _answers(),
                                  overallComment: _overall.text,
                                ),
                            'Saved. You can come back to this.',
                          ),
                  child: const Text('Save for later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving || _unanswered > 0
                      ? null
                      : () => _run(
                            () => context.read<PerformanceRepository>().submitSelfAssessment(
                                  appraisalId: appraisal.id,
                                  answers: _answers(),
                                  overallComment: _overall.text,
                                ),
                            'Self-assessment submitted.',
                          ),
                  child: Text(_saving ? 'Working…' : 'Submit'),
                ),
              ),
            ],
          ),
        ] else if ((appraisal.selfOverallComment ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          _QuoteBlock(label: 'What you said', body: appraisal.selfOverallComment!),
        ],

        if (appraisal.awaitingAcknowledgement) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          TextField(
            controller: _acknowledgement,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your response',
              hintText: 'Optional. Anything you want on the record — including that you disagree.',
            ),
          ),
          const SizedBox(height: 8),
          // Said plainly because people assume otherwise, and an acknowledgement
          // someone thought was an agreement is worth nothing to either side.
          const Text(
            'Acknowledging records that you have read this. It does not mean you agree with it. '
            'Your response is kept on the appraisal and cannot be edited afterwards.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving
                ? null
                : () => _run(
                      () => context.read<PerformanceRepository>().acknowledge(
                            appraisalId: appraisal.id,
                            comment: _acknowledgement.text,
                          ),
                      'Acknowledged.',
                    ),
            child: Text(_saving ? 'Recording…' : 'Acknowledge'),
          ),
        ],

        if (appraisal.acknowledgedAt != null) ...[
          const SizedBox(height: 20),
          _QuoteBlock(
            label: 'Acknowledged ${formatPerformanceDate(appraisal.acknowledgedAt!)}',
            body: appraisal.employeeComment ?? 'No response given.',
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.appraisal});

  final Appraisal appraisal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Figure(label: 'Final score', value: appraisal.finalScore),
              if (appraisal.selfScore != null) ...[
                const SizedBox(width: 28),
                _Figure(label: 'Your own rating', value: appraisal.selfScore, muted: true),
              ],
            ],
          ),
          if (appraisal.ratingBand != null) ...[
            const SizedBox(height: 8),
            Text(
              appraisal.ratingBand!,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((appraisal.reviewerOverallComment ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              appraisal.reviewerOverallComment!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
          if (appraisal.reviewerSubmittedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reviewed ${formatPerformanceDate(appraisal.reviewerSubmittedAt!)}'
              '${appraisal.reviewedByName != null ? ' by ${appraisal.reviewedByName}' : ''}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.muted = false});

  final String label;
  final double? value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value == null ? '—' : '${value!.toStringAsFixed(0)}%',
          style: TextStyle(
            color: muted ? AppColors.textMuted : AppColors.primaryGreen,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({
    required this.criterion,
    required this.maxRating,
    required this.rating,
    required this.comment,
    required this.editable,
    required this.onRating,
  });

  final AppraisalCriterionScore criterion;
  final int maxRating;
  final int? rating;
  final TextEditingController comment;
  final bool editable;
  final ValueChanged<int> onRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  criterion.label,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // The weight is shown because it changes how much care a line
              // deserves — a 40% criterion is not the same ask as a 5% one.
              Text(
                '${criterion.weight.toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          if ((criterion.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              criterion.description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var value = 1; value <= maxRating; value++)
                _RatingChip(
                  value: value,
                  selected: rating == value,
                  enabled: editable,
                  onTap: () => onRating(value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (editable)
            TextField(
              controller: comment,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What did you do here? Evidence helps your reviewer.',
              ),
            )
          else if (comment.text.isNotEmpty)
            Text(comment.text, style: const TextStyle(fontSize: 14, height: 1.4)),

          // The reviewer's answer, where the server has sent one. It withholds
          // these until the review is submitted, so a null is not "unrated".
          if (criterion.reviewerRating != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REVIEWER',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${criterion.reviewerRating} out of $maxRating',
                      style: const TextStyle(fontSize: 14)),
                  if ((criterion.reviewerComment ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      criterion.reviewerComment!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: enabled,
      label: '$value',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreen : AppColors.inputFill,
            border: Border.all(
              color: selected ? AppColors.primaryGreen : AppColors.inputBorder,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
