import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/whistleblow_models.dart';
import '../data/whistleblow_repository.dart';

/// Following a report with the case code and passphrase issued when it was filed.
///
/// The credentials live in this widget's state and nowhere else — not in storage, not in a cache,
/// not in a route argument. That is the point: an anonymous report is reached by something the
/// reporter knows rather than by who they are signed in as, and leaving the passphrase on the
/// device would undo the part of that the app controls. The cost is retyping them after leaving
/// the screen, which is the right trade here.
///
/// A wrong passphrase and an unknown case code fail identically, because telling them apart would
/// confirm to a guesser that a code exists.
class TrackReportScreen extends StatefulWidget {
  const TrackReportScreen({super.key});

  @override
  State<TrackReportScreen> createState() => _TrackReportScreenState();
}

class _TrackReportScreenState extends State<TrackReportScreen> {
  final _caseCodeController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _replyController = TextEditingController();

  TrackedWhistleblowReport? _report;
  bool _loading = false;
  bool _sending = false;

  @override
  void dispose() {
    _caseCodeController.dispose();
    _passphraseController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _lookUp() async {
    final caseCode = _caseCodeController.text.trim();
    final passphrase = _passphraseController.text.trim();
    if (caseCode.isEmpty || passphrase.isEmpty) {
      _showMessage('Enter both the case code and the passphrase.');
      return;
    }

    setState(() => _loading = true);
    try {
      final report = await context.read<WhistleblowRepository>().track(
        caseCode: caseCode,
        passphrase: passphrase,
      );
      if (mounted) setState(() => _report = report);
    } on ApiException catch (e) {
      if (mounted) setState(() => _report = null);
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    try {
      final report = await context.read<WhistleblowRepository>().addMessage(
        caseCode: _caseCodeController.text.trim(),
        passphrase: _passphraseController.text.trim(),
        body: body,
      );
      if (mounted) {
        setState(() => _report = report);
        _replyController.clear();
      }
      _showMessage('Message sent.');
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('Follow a report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _caseCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Case code',
              hintText: 'WB-XXXX-XXXX',
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passphraseController,
            decoration: const InputDecoration(labelText: 'Passphrase'),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _lookUp,
            child: Text(_loading ? 'Looking up…' : 'Open report'),
          ),
          if (report != null) ...[
            const SizedBox(height: 24),
            _ReportSummary(report: report),
            const SizedBox(height: 24),
            Text('Messages', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (report.messages.isEmpty)
              Text(
                'No messages yet. Whoever is looking into this can ask you questions here.',
                style: TextStyle(color: context.palette.textMuted, fontSize: 12),
              )
            else
              ...report.messages.map((message) => _MessageBubble(message: message)),
            const SizedBox(height: 16),
            TextField(
              controller: _replyController,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Add a message',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _sendReply,
              child: Text(_sending ? 'Sending…' : 'Send message'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final TrackedWhistleblowReport report;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              '${kWhistleblowCategories[report.category] ?? report.category} · '
              '${kWhistleblowStatuses[report.status] ?? report.status} · filed '
              '${_formatDate(report.submittedAt)}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(report.body),
            if (report.outcomeNote != null) ...[
              const SizedBox(height: 16),
              Text(
                'OUTCOME',
                style: TextStyle(color: palette.textMuted, fontSize: 11, letterSpacing: 0.6),
              ),
              const SizedBox(height: 4),
              Text(report.outcomeNote!),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final WhistleblowMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Read from fromHandler rather than inferred from the author being absent: an anonymous
    // reporter's message has no author, and inferring the side from missing data would render a
    // handler's message as the reporter's own the day that handler's account is deleted.
    final mine = !message.fromHandler;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: mine ? palette.primarySoft : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // A handler is always named: the reporter is owed the knowledge of who inside the
              // organisation is reading and answering.
              message.fromHandler
                  ? (message.authorName ?? 'Handler')
                  : (message.authorName ?? 'You (anonymous)'),
              style: TextStyle(color: palette.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(message.body),
            const SizedBox(height: 4),
            Text(
              _formatDate(message.sentAt),
              style: TextStyle(color: palette.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// Falls back to the raw value rather than throwing, so an unexpected format still reads.
String _formatDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('d MMM y').format(date.toLocal());
}
