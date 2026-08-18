import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/performance_models.dart';
import '../data/performance_repository.dart';
import 'my_appraisal_detail_screen.dart';
import 'performance_labels.dart';

/// The signed-in employee's own appraisals.
///
/// Reachable by every role. Setting up cycles and writing reviews are web jobs;
/// what mobile carries is the part an employee actually does on a phone —
/// filling in their self-assessment and reading the outcome.
class MyAppraisalsScreen extends StatelessWidget {
  const MyAppraisalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<PerformanceRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('My appraisals')),
      body: PaginatedListView<Appraisal>(
        emptyMessage:
            'Nothing here yet. Appraisals appear when your organisation opens a review round.',
        fetchPage: (page, size) => repository.myAppraisals(page: page, size: size),
        itemBuilder: (context, item) => _AppraisalTile(item: item),
      ),
    );
  }
}

class _AppraisalTile extends StatelessWidget {
  const _AppraisalTile({required this.item});

  final Appraisal item;

  @override
  Widget build(BuildContext context) {
    // The score only exists once the reviewer has submitted — before that the
    // server sends nulls, so there is genuinely nothing to show rather than
    // something being held back here.
    final trailingScore = item.finalScore;

    return ListTile(
      title: Text(
        item.cycleName,
        style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            appraisalStatusLabel(item.status),
            style: TextStyle(
              color: appraisalStatusColour(context, item.status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.ratingBand != null) ...[
            const SizedBox(height: 2),
            Text(
              item.ratingBand!,
              style: TextStyle(color: context.palette.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
      isThreeLine: item.ratingBand != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingScore != null)
            Text(
              '${trailingScore.toStringAsFixed(0)}%',
              style: TextStyle(
                color: context.palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          Icon(Icons.chevron_right, color: context.palette.textMuted),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyAppraisalDetailScreen(appraisalId: item.id)),
      ),
    );
  }
}
