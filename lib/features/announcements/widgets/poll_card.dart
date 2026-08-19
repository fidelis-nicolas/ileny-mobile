import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/announcement_models.dart';
import '../data/announcement_repository.dart';

/// The ballot on an announcement that is a poll.
///
/// Three things are decided by the server, never re-derived here:
///
///  * [PollResponse.canVote] — whether to show the controls at all. It folds
///    together open/closed, audience membership and whether the account has a
///    staff record. The announcement feed is not audience-filtered, so a poll is
///    routinely visible to people who cannot answer it.
///  * A null [PollOptionResponse.voteCount] means "not shown to you", not zero,
///    so the bars are hidden entirely rather than drawn empty.
///  * [PollResponse.closed] already accounts for the deadline having passed.
///
/// Voting again replaces the previous answer, so one control serves both casting
/// and changing a vote.
class PollCard extends StatefulWidget {
  const PollCard({super.key, required this.announcementId, required this.poll});

  final String announcementId;
  final PollResponse poll;

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  late PollResponse _poll = widget.poll;
  late List<String> _selected = List<String>.from(widget.poll.myVotedOptionIds);
  bool _submitting = false;

  /// True when the selection differs from what the server holds — which is what
  /// makes the button meaningful for a change of mind as well as a first answer.
  bool get _dirty {
    if (_selected.isEmpty) return false;
    if (_selected.length != _poll.myVotedOptionIds.length) return true;
    return _selected.any((id) => !_poll.myVotedOptionIds.contains(id));
  }

  void _toggle(String optionId) {
    if (!_poll.canVote || _submitting) return;
    setState(() {
      if (_poll.allowMultiple) {
        _selected.contains(optionId) ? _selected.remove(optionId) : _selected.add(optionId);
      } else {
        _selected = [optionId];
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final updated = await context
          .read<AnnouncementRepository>()
          .vote(widget.announcementId, _selected);
      if (!mounted) return;
      setState(() {
        _poll = updated;
        _selected = List<String>.from(updated.myVotedOptionIds);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your vote has been recorded.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final totalVoters = _poll.totalVoters ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _Chip(label: 'Poll', icon: Icons.bar_chart_rounded),
              if (_poll.anonymous) _Chip(label: 'Anonymous', icon: Icons.visibility_off_outlined),
              if (_poll.closed) _Chip(label: 'Closed', icon: Icons.lock_outline),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _poll.question,
            style: TextStyle(
              color: palette.textHeading,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _poll.allowMultiple ? 'Choose as many as apply.' : 'Choose one.',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          for (final option in _poll.options) ...[
            _OptionRow(
              option: option,
              selected: _selected.contains(option.id),
              isMyVote: _poll.myVotedOptionIds.contains(option.id),
              allowMultiple: _poll.allowMultiple,
              enabled: _poll.canVote && !_submitting,
              // Share of the people who answered, not of the votes cast — on a
              // multi-select poll these can therefore sum past 100%.
              share: _poll.showsCounts && totalVoters > 0
                  ? (option.voteCount ?? 0) / totalVoters
                  : null,
              onTap: () => _toggle(option.id),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _poll.showsCounts
                      ? totalVoters == 1
                            ? '1 person has answered'
                            : '$totalVoters people have answered'
                      : _resultsPendingLabel(),
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
              if (_poll.canVote)
                FilledButton(
                  onPressed: _dirty && !_submitting ? _submit : null,
                  child: Text(
                    _submitting
                        ? 'Saving…'
                        : _poll.hasVoted
                        ? 'Change vote'
                        : 'Submit vote',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Why no tally is on screen. Worth saying — a poll that silently shows no
  /// numbers reads as broken rather than as deliberately private.
  String _resultsPendingLabel() {
    switch (_poll.resultsVisibility) {
      case 'AFTER_VOTE':
        return _poll.hasVoted ? 'Results are being counted.' : 'Results appear once you have voted.';
      case 'AFTER_CLOSE':
        return 'Results appear once the poll closes.';
      case 'ADMINS_ONLY':
        return 'Results are only shared with administrators.';
      default:
        return 'Results are not available yet.';
    }
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.isMyVote,
    required this.allowMultiple,
    required this.enabled,
    required this.share,
    required this.onTap,
  });

  final PollOptionResponse option;
  final bool selected;
  final bool isMyVote;
  final bool allowMultiple;
  final bool enabled;

  /// 0..1, or null when the tally is not visible to this viewer.
  final double? share;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? palette.primary : palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // The tally sits behind the label rather than beside it, so the row
              // keeps the same height whether or not counts are visible.
              if (share != null)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: share!.clamp(0.0, 1.0),
                    child: ColoredBox(color: palette.primary.withValues(alpha: 0.12)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      allowMultiple
                          ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                          : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      size: 20,
                      color: selected ? palette.primary : palette.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(color: palette.textBody, fontSize: 14),
                      ),
                    ),
                    if (isMyVote)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'your answer',
                          style: TextStyle(color: palette.textMuted, fontSize: 11),
                        ),
                      ),
                    if (share != null)
                      Text(
                        '${option.voteCount} · ${(share! * 100).round()}%',
                        style: TextStyle(
                          color: palette.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
