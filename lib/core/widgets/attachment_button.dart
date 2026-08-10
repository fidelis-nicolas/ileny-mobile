import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_exception.dart';
import '../network/downloaded_file.dart';
import '../theme/app_colors.dart';

/// Opens a file that lives behind `/files/**`.
///
/// Those paths are authenticated — the backend resolves each one back to the
/// record that owns it and checks that record's tenant against the caller's —
/// so there is no URL to hand the OS or a browser. This downloads through dio
/// (which attaches the bearer token), writes the bytes to the cache directory,
/// and lets whatever viewer is installed take it from there — the same approach
/// the payslip screen takes, and for the same reason: no in-app renderer to
/// bundle, and no unauthenticated fetch to fail.
///
/// [download] is passed in rather than a repository, so the caller decides which
/// endpoint and what to name the result.
class AttachmentButton extends StatefulWidget {
  const AttachmentButton({
    super.key,
    required this.download,
    this.label = 'Attached document',
    this.dense = false,
  });

  final Future<DownloadedFile> Function() download;
  final String label;

  /// Compact styling, for a row inside a list rather than a standalone control.
  final bool dense;

  @override
  State<AttachmentButton> createState() => _AttachmentButtonState();
}

class _AttachmentButtonState extends State<AttachmentButton> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      final file = await widget.download();
      final dir = await getTemporaryDirectory();
      final savedFile = File('${dir.path}/${file.filename}');
      await savedFile.writeAsBytes(file.bytes, flush: true);

      final result = await OpenFile.open(savedFile.path);
      // ResultType.done means a viewer took it. Anything else — most often no
      // app installed that handles the type — is worth saying out loud rather
      // than leaving the tap looking like it did nothing.
      if (result.type != ResultType.done && mounted) {
        _report(result.message);
      }
    } on ApiException catch (e) {
      if (mounted) _report(e.message);
    } catch (_) {
      if (mounted) _report('That attachment could not be opened.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _report(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.dense ? 12.0 : 14.0;
    final iconSize = widget.dense ? 14.0 : 18.0;

    return InkWell(
      onTap: _opening ? null : _open,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: widget.dense ? 2 : 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_opening)
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.attach_file, size: iconSize, color: AppColors.primaryGreen),
            const SizedBox(width: 4),
            Text(
              _opening ? 'Opening…' : widget.label,
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
