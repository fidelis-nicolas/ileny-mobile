import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/attachment_button.dart';
import '../data/discipline_models.dart';
import '../data/discipline_repository.dart';
import 'case_conversation_screen.dart';
import 'discipline_labels.dart';

/// One of the employee's own cases: what was raised, what has been recorded
/// against it, and the way through to answering it.
///
/// Deliberately not the same screen HR sees. HR's view carries actions it can
/// take — record an action, resolve, close — and none of those belong on a
/// screen the subject of the case is reading. What the two share is the
/// conversation, which is its own screen.
class MyQueryDetailScreen extends StatefulWidget {
  const MyQueryDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<MyQueryDetailScreen> createState() => _MyQueryDetailScreenState();
}

class _MyQueryDetailScreenState extends State<MyQueryDetailScreen> {
  late Future<DisciplinaryCaseResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<DisciplineRepository>().myCase(widget.caseId);
  }

  Future<void> _reload() async {
    final future = context.read<DisciplineRepository>().myCase(widget.caseId);
    setState(() => _future = future);
    await future;
  }

  Future<void> _openConversation(DisciplinaryCaseResponse item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseConversationScreen(
          caseId: item.id,
          title: humaniseEnum(item.category),
        ),
      ),
    );
    // The reply count on this screen comes from the case payload, so it is
    // stale the moment something is sent. Reload on the way back rather than
    // leaving a "1 response" label under a thread that now has two.
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Query')),
      body: FutureBuilder<DisciplinaryCaseResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _ErrorView(
              message: error is ApiException ? error.message : "This case couldn't be loaded.",
              onRetry: _reload,
            );
          }

          final item = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  humaniseEnum(item.category),
                  style: TextStyle(
                    color: context.palette.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Incident of ${formatCaseDate(item.incidentDate)}'
                  '${item.reportedByName.isEmpty ? '' : ', raised by ${item.reportedByName}'}',
                  style: TextStyle(color: context.palette.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(humaniseEnum(item.status)),
                  backgroundColor: context.palette.surfaceAlt,
                  side: BorderSide.none,
                ),
                const SizedBox(height: 16),
                const _SectionLabel('What was raised'),
                Text(item.description),

                if (item.actions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel('Actions recorded'),
                  for (final action in item.actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${humaniseEnum(action.actionType)} · ${formatCaseDate(action.actionDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (action.notes != null && action.notes!.isNotEmpty)
                            Text(
                              action.notes!,
                              style: TextStyle(color: context.palette.textMuted, fontSize: 13),
                            ),
                          // The evidence behind the action. This screen showed
                          // no sign one existed, which is the wrong omission on
                          // the employee's own view: answering a query means
                          // being able to read what it rests on.
                          if (action.fileUrl != null)
                            AttachmentButton(
                              dense: true,
                              label: 'View attachment',
                              download: () =>
                                  context.read<DisciplineRepository>().downloadAttachment(
                                        action.fileUrl!,
                                        label:
                                            '${humaniseEnum(action.actionType)}-${action.actionDate}',
                                      ),
                            ),
                        ],
                      ),
                    ),
                ],

                if (item.resolutionNotes != null && item.resolutionNotes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel('Outcome'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(item.resolutionNotes!),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _openConversation(item),
                  icon: const Icon(Icons.forum_outlined),
                  label: Text(
                    item.responses.isEmpty
                        ? 'Respond to this query'
                        : 'Conversation (${item.responses.length})',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anything you write becomes part of the case record, alongside what was raised.',
                  style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
