import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/discipline_models.dart';
import '../data/discipline_repository.dart';
import 'discipline_labels.dart';
import 'my_query_detail_screen.dart';

/// The signed-in employee's own disciplinary record — the queries raised with
/// them, and the way in to answering one.
///
/// Reachable by every role, unlike the HR case list (`DisciplineCasesScreen`),
/// which needs `discipline:read`. An employee cannot be expected to answer a
/// query they are not allowed to read, and the HR list is not somewhere they
/// can be sent.
class MyQueriesScreen extends StatelessWidget {
  const MyQueriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DisciplineRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('My queries')),
      body: PaginatedListView<DisciplinaryCaseResponse>(
        emptyMessage: 'Nothing here — no disciplinary matters have been raised with you.',
        fetchPage: (page, size) => repository.myCases(page: page, size: size),
        itemBuilder: (context, item) => _MyCaseTile(item: item),
      ),
    );
  }
}

class _MyCaseTile extends StatelessWidget {
  const _MyCaseTile({required this.item});

  final DisciplinaryCaseResponse item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        humaniseEnum(item.category),
        style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${formatCaseDate(item.incidentDate)} · ${humaniseEnum(item.status)}',
            style: TextStyle(color: context.palette.textMuted, fontSize: 12),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Icon(Icons.chevron_right, color: context.palette.textMuted),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyQueryDetailScreen(caseId: item.id)),
      ),
    );
  }
}
