import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/whistleblow_models.dart';
import '../data/whistleblow_repository.dart';
import 'track_report_screen.dart';

/// Raising a concern about the organisation.
///
/// Needs no permission, like the rest of the self-service screens — the person who most needs
/// this channel is the one with the least authority, and gating the ability to raise a concern
/// would defeat the feature.
///
/// The screen has two jobs and the second is the harder one. Filing the report is a form; handing
/// over the case code and passphrase is the part that has to be got right. They come back once,
/// the passphrase is stored only as a hash and cannot be re-sent, and on an anonymous report they
/// are the only way the reporter can ever get back to it. So the confirmation replaces the form
/// entirely rather than appearing under it, and it does not offer a casual way out.
class RaiseReportScreen extends StatefulWidget {
  const RaiseReportScreen({super.key});

  @override
  State<RaiseReportScreen> createState() => _RaiseReportScreenState();
}

class _RaiseReportScreenState extends State<RaiseReportScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _anonymous = true;
  String _category = 'OTHER';
  bool _submitting = false;
  WhistleblowSubmitResult? _result;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      _showMessage('Add a summary and describe what happened.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await context.read<WhistleblowRepository>().submit(
        anonymous: _anonymous,
        category: _category,
        subject: subject,
        body: body,
      );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(result == null ? 'Raise a concern' : 'Report filed')),
      body: result == null ? _buildForm(context) : _SubmittedPanel(result: result),
    );
  }

  Widget _buildForm(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _anonymous,
          onChanged: (value) => setState(() => _anonymous = value),
          title: const Text('File anonymously'),
          subtitle: Text(
            _anonymous
                ? 'Nothing on the report will identify you. Not hidden — not recorded. You will '
                      'follow it with a case code instead, and nobody can notify you, so keep the '
                      'code safe.'
                : 'Your name is attached, whoever handles it can see who raised it, and you will '
                      'be notified of replies and the outcome.',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'What is this about?'),
          items: kWhistleblowCategories.entries
              .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
              .toList(),
          onChanged: (value) => setState(() => _category = value ?? 'OTHER'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(
            labelText: 'Summary',
            hintText: 'One line: what is happening?',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bodyController,
          minLines: 6,
          maxLines: 14,
          decoration: const InputDecoration(
            labelText: 'What happened',
            hintText: 'Dates, who was involved, whether it is still going on.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'If you are filing anonymously, remember that details only you could know may identify '
          'you to the people reading this.',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Filing…' : 'File report'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TrackReportScreen()),
          ),
          child: const Text('Already filed one? Follow it with your case code'),
        ),
      ],
    );
  }
}

/// The credentials, shown once.
///
/// Deliberately blunt and deliberately hard to skip past: the single most damaging thing this
/// screen can do is let somebody leave before they have written the passphrase down, at which
/// point an anonymous report becomes unreachable to the only person who should be able to reach it.
class _SubmittedPanel extends StatelessWidget {
  const _SubmittedPanel({required this.result});

  final WhistleblowSubmitResult result;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.verified_user_outlined, color: palette.success),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Your report has been received',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(result.guidance, style: TextStyle(color: palette.textMuted)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Credential(label: 'Case code', value: result.caseCode),
                const SizedBox(height: 12),
                _Credential(label: 'Passphrase', value: result.passphrase),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy both'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: 'Case code: ${result.caseCode}\n'
                            'Passphrase: ${result.passphrase}',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied. Save it somewhere outside work.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TrackReportScreen()),
          ),
          child: const Text('Follow this report'),
        ),
      ],
    );
  }
}

class _Credential extends StatelessWidget {
  const _Credential({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: palette.textMuted, fontSize: 11, letterSpacing: 0.6),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
