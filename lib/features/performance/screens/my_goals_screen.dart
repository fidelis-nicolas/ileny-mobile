import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/performance_models.dart';
import '../data/performance_repository.dart';
import 'performance_labels.dart';

/// The employee's own goals, and the way in to reporting progress on one.
///
/// Checking in needs no permission — progress is reported by whoever is doing
/// the work, and a tracker only a manager can update is one that stops being
/// updated. Closing a goal out is deliberately absent: whether a goal was
/// achieved or missed is a judgement for whoever set it.
class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({super.key});

  @override
  State<MyGoalsScreen> createState() => _MyGoalsScreenState();
}

class _MyGoalsScreenState extends State<MyGoalsScreen> {
  /// Bumped after a check-in to force `PaginatedListView` to refetch, since the
  /// goal's progress is denormalised onto the row we have just changed.
  int _reloadToken = 0;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<PerformanceRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('My goals')),
      body: PaginatedListView<Goal>(
        key: ValueKey(_reloadToken),
        emptyMessage: 'No goals set for you yet.',
        fetchPage: (page, size) => repository.myGoals(page: page, size: size),
        itemBuilder: (context, item) => _GoalTile(
          goal: item,
          onCheckedIn: () => setState(() => _reloadToken++),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onCheckedIn});

  final Goal goal;
  final VoidCallback onCheckedIn;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if ((goal.metric ?? '').isNotEmpty) goal.metric!,
      if ((goal.targetValue ?? '').isNotEmpty) 'target ${goal.targetValue}',
      if (goal.dueDate != null) 'due ${formatPerformanceDate(goal.dueDate!)}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        color: context.palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                goalStatusLabel(goal.status),
                style: TextStyle(
                  color: goalStatusColour(context, goal.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progressPercent / 100,
                    minHeight: 8,
                    backgroundColor: context.palette.surfaceAlt,
                    // Matched to the status colour so a missed goal at 90% does
                    // not read as nearly-there — the bar and the label have to
                    // tell one story, or the cheerful bar wins.
                    valueColor: AlwaysStoppedAnimation(goalStatusColour(context, goal.status)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${goal.progressPercent}%',
                style: TextStyle(color: context.palette.textMuted, fontSize: 12),
              ),
            ],
          ),
          if (goal.isActive) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.trending_up, size: 18),
                label: const Text('Check in'),
                onPressed: () => _openCheckIn(context),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Future<void> _openCheckIn(BuildContext context) async {
    final recorded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CheckInSheet(goal: goal),
    );
    if (recorded == true) onCheckedIn();
  }
}

/// Record a check-in, and read the ones already recorded.
///
/// Both in one sheet because a check-in is written by reading the last one —
/// "still blocked on procurement" only means something next to what came
/// before.
class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({required this.goal});

  final Goal goal;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  final TextEditingController _note = TextEditingController();
  late double _progress = widget.goal.progressPercent.toDouble();
  bool _saving = false;
  List<GoalUpdate>? _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await context.read<PerformanceRepository>().goalUpdates(widget.goal.id);
      if (!mounted) return;
      setState(() => _history = history);
    } on ApiException {
      // The history is context, not the point of the sheet — failing to load it
      // must not stop someone recording where they have got to.
      if (!mounted) return;
      setState(() => _history = const []);
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await context.read<PerformanceRepository>().addGoalUpdate(
            goalId: widget.goal.id,
            note: _note.text,
            progressPercent: _progress.round(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal.title,
              style: TextStyle(
                color: context.palette.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Where things stand',
                hintText: 'What has moved, and what is in the way.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Progress: ${_progress.round()}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _progress,
              max: 100,
              divisions: 20,
              label: '${_progress.round()}%',
              onChanged: (value) => setState(() => _progress = value),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Recording…' : 'Record check-in'),
            ),
            const SizedBox(height: 20),
            Text(
              'EARLIER CHECK-INS',
              style: TextStyle(
                color: context.palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (_history == null)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else if (_history!.isEmpty)
              Text('None yet.', style: TextStyle(color: context.palette.textMuted))
            else
              for (final update in _history!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          formatPerformanceDate(update.createdAt),
                          if (update.progressPercent != null) '${update.progressPercent}%',
                          if (update.createdByName != null) update.createdByName!,
                        ].join(' · '),
                        style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                      ),
                      if ((update.note ?? '').isNotEmpty)
                        Text(update.note!, style: const TextStyle(fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            Text(
              'Check-ins cannot be edited or removed — the trail of how a goal moved is the '
              'point of keeping one.',
              style: TextStyle(color: context.palette.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
