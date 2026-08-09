import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../employees/data/employee_models.dart';
import '../data/discipline_models.dart';
import '../data/discipline_repository.dart';
import 'case_conversation_screen.dart';
import 'discipline_labels.dart';
import 'new_discipline_case_screen.dart';

class DisciplineCasesScreen extends StatefulWidget {
  const DisciplineCasesScreen({super.key, required this.employee});

  final EmployeeResponse employee;

  @override
  State<DisciplineCasesScreen> createState() => _DisciplineCasesScreenState();
}

class _DisciplineCasesScreenState extends State<DisciplineCasesScreen> {
  final _listKey = GlobalKey<PaginatedListViewState<DisciplinaryCaseResponse>>();

  Future<void> _openNewCase() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewDisciplineCaseScreen(employee: widget.employee),
      ),
    );
    if (created == true) _listKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DisciplineRepository>();

    return Scaffold(
      appBar: AppBar(title: Text('Discipline · ${widget.employee.fullName}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewCase,
        icon: const Icon(Icons.add),
        label: const Text('New case'),
      ),
      body: PaginatedListView<DisciplinaryCaseResponse>(
        key: _listKey,
        emptyMessage: 'No disciplinary cases on record.',
        fetchPage: (page, size) =>
            repository.casesForEmployee(widget.employee.id, page: page, size: size),
        itemBuilder: (context, item) => _CaseTile(item: item),
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.item});

  final DisciplinaryCaseResponse item;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        humaniseEnum(item.category),
        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${formatCaseDate(item.incidentDate)} · ${humaniseEnum(item.status)}'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.description),
        if (item.actions.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryGreen, fontSize: 13),
          ),
          for (final action in item.actions)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${humaniseEnum(action.actionType)} · ${formatCaseDate(action.actionDate)}'
                '${action.notes != null && action.notes!.isNotEmpty ? ' · ${action.notes}' : ''}'
                '${action.fileUrl != null ? ' · 📎' : ''}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.forum_outlined, size: 18),
            // The employee's answer to this case, and HR's reply to it. The
            // reply count isn't shown here: this list endpoint returns cases
            // without their thread (one query per page, by design), so a count
            // would have to be either fetched per row or quietly wrong.
            label: const Text('Conversation'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaseConversationScreen(
                  caseId: item.id,
                  title: humaniseEnum(item.category),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
