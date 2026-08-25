import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/attachment_button.dart';
import '../data/document_models.dart';
import '../data/document_repository.dart';

/// What the organisation asks the signed-in employee for, and the way to provide it.
///
/// This is the half of the documents feature that belongs on a phone, and arguably the reason the
/// feature exists at all: before it, only HR could upload against a staff record, so the person
/// who actually held the certificate had no way to put it in. Here they photograph it and it is
/// filed.
///
/// Camera and gallery only, deliberately. The app carries `image_picker` and not a general file
/// picker, and a photograph of a document is the thing somebody standing in a queue at an embassy
/// can actually produce. A PDF that arrived by email is a job for the web client.
class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  late Future<List<DocumentChecklistItem>> _checklistFuture;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _checklistFuture = context.read<DocumentRepository>().myChecklist();
  }

  void _reload() {
    setState(() {
      _checklistFuture = context.read<DocumentRepository>().myChecklist();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Picks an image, asks for an expiry where the requirement needs one, and uploads.
  ///
  /// The expiry prompt is not optional politeness: the server rejects an upload against an
  /// expiring requirement that carries no date, so skipping the prompt would produce a 400 the
  /// person could do nothing about.
  Future<void> _upload(DocumentChecklistItem item) async {
    // Read before any await. Everything below — the source sheet, the picker, the date dialog —
    // is an async gap, and reaching for the provider afterwards reads a context that may already
    // be gone.
    final repository = context.read<DocumentRepository>();

    final source = await _pickSource();
    if (source == null) return;

    // The same compression the discipline attachments use — a full-resolution phone photo is
    // several megabytes over a Nigerian mobile connection, and the backend rejects it anyway.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    String? expiresOn;
    if (item.expires) {
      final chosen = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
        initialDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'When does this expire?',
      );
      if (chosen == null) {
        _showMessage('${item.name} expires, so it needs an expiry date. Nothing was uploaded.');
        return;
      }
      expiresOn = DateFormat('yyyy-MM-dd').format(chosen);
    }

    setState(() => _uploading = true);
    try {
      await repository.uploadMyDocument(
        filePath: picked.path,
        documentRequirementId: item.requirementId,
        expiresOn: expiresOn,
      );
      _showMessage('${item.name} uploaded.');
      _reload();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _pickSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: FutureBuilder<List<DocumentChecklistItem>>(
        future: _checklistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Message(
              text: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load your documents.',
              onRetry: _reload,
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            // Not an error and not an empty checklist — the organisation has not said what it
            // wants yet. Saying "you are missing nothing" would be misleading.
            return const _Message(
              text: 'Your organisation has not asked for any documents yet.',
            );
          }

          final outstanding = items.where((item) => item.mandatory && item.status != 'PROVIDED').length;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) return _Summary(outstanding: outstanding);
                final item = items[index - 1];
                return _ChecklistTile(
                  item: item,
                  busy: _uploading,
                  onUpload: () => _upload(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.outstanding});

  final int outstanding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        outstanding == 0
            ? 'You have provided everything that is required.'
            : '$outstanding required document${outstanding == 1 ? '' : 's'} still outstanding.',
        style: TextStyle(
          color: outstanding == 0 ? palette.success : palette.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.item, required this.busy, required this.onUpload});

  final DocumentChecklistItem item;
  final bool busy;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final repository = context.read<DocumentRepository>();

    final (IconData icon, Color colour, String label) = switch (item.status) {
      'PROVIDED' => (Icons.check_circle_outline, palette.success, 'Provided'),
      'EXPIRED' => (Icons.error_outline, palette.danger, 'Expired'),
      _ => (
        Icons.radio_button_unchecked,
        item.mandatory ? palette.warning : palette.textMuted,
        'Not provided',
      ),
    };

    return ListTile(
      leading: Icon(icon, color: colour),
      title: Text(
        item.mandatory ? '${item.name} *' : item.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            _subtitleFor(item, label),
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          if (item.fileUrl != null) ...[
            const SizedBox(height: 6),
            AttachmentButton(
              dense: true,
              label: 'View',
              download: () => repository.downloadDocument(item.fileUrl!, label: item.name),
            ),
          ],
        ],
      ),
      isThreeLine: true,
      trailing: IconButton(
        // "Replace" rather than "Upload" once something is on file: the earlier document stays and
        // the newest becomes the answer, so this adds rather than overwrites.
        tooltip: item.isMissing ? 'Upload' : 'Replace',
        icon: Icon(item.isMissing ? Icons.upload_outlined : Icons.refresh),
        onPressed: busy ? null : onUpload,
      ),
    );
  }

  String _subtitleFor(DocumentChecklistItem item, String label) {
    if (item.isMissing) return item.description ?? 'Not provided yet';
    if (item.expiresOn != null) {
      final date = DateTime.tryParse(item.expiresOn!);
      final formatted = date == null ? item.expiresOn! : DateFormat('d MMM y').format(date);
      return '$label · expires $formatted';
    }
    return label;
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
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
