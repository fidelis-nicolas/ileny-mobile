import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/attachment_button.dart';
import '../data/discipline_models.dart';
import '../data/discipline_repository.dart';

/// The conversation on a disciplinary case: the employee's answer to a query,
/// and HR's reply to that answer.
///
/// One screen for both sides. Which side a message came from is on the message
/// itself ([DisciplinaryResponseResponse.fromEmployee], decided by the server),
/// so this never needs to know who is looking — only who wrote each line. Both
/// parties therefore see the same thread in the same order, which is the point
/// of keeping it as a record at all.
///
/// The composer is available even on a closed case, matching the backend.
/// Someone who wants the last word on a file that has been shut is exactly who
/// a right of reply is for.
class CaseConversationScreen extends StatefulWidget {
  const CaseConversationScreen({
    super.key,
    required this.caseId,
    required this.title,
  });

  final String caseId;

  /// Shown in the app bar — the case category, since a case has no name.
  final String title;

  @override
  State<CaseConversationScreen> createState() => _CaseConversationScreenState();
}

class _CaseConversationScreenState extends State<CaseConversationScreen> {
  final _messageController = TextEditingController();
  late Future<List<DisciplinaryResponseResponse>> _future;
  XFile? _attachment;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<DisciplineRepository>().caseResponses(widget.caseId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = context.read<DisciplineRepository>().caseResponses(widget.caseId);
    setState(() => _future = future);
    await future;
  }

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Same client-side compression the discipline document upload uses — a
    // full-resolution phone photo is several megabytes over a Nigerian mobile
    // connection, and the backend's storage limits reject it anyway.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked != null && mounted) setState(() => _attachment = picked);
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showMessage('Write something before sending.');
      return;
    }

    setState(() => _sending = true);
    final repository = context.read<DisciplineRepository>();
    try {
      final created = await repository.addResponse(
        caseId: widget.caseId,
        message: message,
      );
      // The attachment is a second call because the message must exist before
      // anything can hang off it. A failed upload therefore leaves the reply
      // recorded without its document — said plainly rather than rolled back,
      // since losing the words to save the file would be the worse trade.
      if (_attachment != null) {
        try {
          await repository.uploadResponseDocument(created.id, _attachment!.path);
        } on ApiException catch (e) {
          if (mounted) {
            _showMessage('Your response was sent, but the attachment failed: ${e.message}');
          }
        }
      }
      if (!mounted) return;
      _messageController.clear();
      setState(() => _attachment = null);
      await _reload();
      if (mounted) _showMessage('Response sent.');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DisciplinaryResponseResponse>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return _CentredMessage(
                    message: error is ApiException
                        ? error.message
                        : "This conversation couldn't be loaded.",
                    onRetry: _reload,
                  );
                }
                final responses = snapshot.data ?? const [];
                if (responses.isEmpty) {
                  return const _CentredMessage(
                    message: 'No responses yet.\n\nAnything written here becomes '
                        'part of the case record.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: responses.length,
                    itemBuilder: (context, index) => _ResponseBubble(response: responses[index]),
                  ),
                );
              },
            ),
          ),
          _Composer(
            controller: _messageController,
            attachmentName: _attachment?.name,
            sending: _sending,
            onAttach: _pickAttachment,
            onClearAttachment: () => setState(() => _attachment = null),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ResponseBubble extends StatelessWidget {
  const _ResponseBubble({required this.response});

  final DisciplinaryResponseResponse response;

  @override
  Widget build(BuildContext context) {
    // The employee's own messages sit left on cream, HR's right on the pale
    // green — the usual chat convention, but keyed on which *side* wrote the
    // message rather than on who is reading, so a case reads identically to
    // both parties. That matters: this is evidence, not a chat.
    final fromEmployee = response.fromEmployee;
    return Align(
      alignment: fromEmployee ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: fromEmployee ? context.palette.surfaceAlt : context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${response.authorName ?? 'Unknown'} · ${fromEmployee ? 'Employee' : 'HR'}',
              style: TextStyle(
                color: context.palette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(response.message),
            if (response.fileUrl != null) ...[
              const SizedBox(height: 6),
              AttachmentButton(
                dense: true,
                download: () => context.read<DisciplineRepository>().downloadAttachment(
                      response.fileUrl!,
                      label: 'response-${_filenameDate(response.createdAt)}',
                    ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _timestamp(response.createdAt),
              style: TextStyle(color: context.palette.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _timestamp(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  /// Sortable date for the saved attachment's filename, so a folder of them
  /// stays in order. Distinct from [_timestamp], which is for reading.
  String _filenameDate(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return 'attachment';
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.attachmentName,
    required this.sending,
    required this.onAttach,
    required this.onClearAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final String? attachmentName;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onClearAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.palette.surfaceAlt)),
        ),
        child: Column(
          children: [
            if (attachmentName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: context.palette.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        attachmentName!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Remove attachment',
                      onPressed: sending ? null : onClearAttachment,
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach a document',
                  onPressed: sending ? null : onAttach,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 5000,
                    enabled: !sending,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write your response…',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton.filled(
                        icon: const Icon(Icons.send),
                        tooltip: 'Send response',
                        onPressed: onSend,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CentredMessage extends StatelessWidget {
  const _CentredMessage({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

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
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
