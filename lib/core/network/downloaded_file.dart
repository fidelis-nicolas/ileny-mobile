/// A file fetched from the API, held in memory until something writes it to disk.
///
/// Downloads go through dio rather than a plain URL open because everything the
/// API serves is authenticated: `/files/**` resolves a path back to the record
/// that owns it and checks that record's tenant against the caller's, and the
/// payslip endpoint checks the payslip belongs to the caller. Handing a URL to
/// the OS or a browser sends no bearer token and gets a 401 back.
class DownloadedFile {
  const DownloadedFile({required this.bytes, required this.filename});

  final List<int> bytes;

  /// What to save it as. The extension matters beyond tidiness — `OpenFile`
  /// picks the viewer from it, so losing it means the OS has nothing to go on.
  final String filename;
}

/// Reads the filename the server suggested, falling back when it did not.
///
/// `/files/**` sends a bare `Content-Disposition: attachment` with no filename,
/// deliberately: the stored name is a UUID, so a caller that knows what the file
/// actually is can name it better. Endpoints that do send one — the payslip
/// download — get theirs used.
String filenameFromContentDisposition(String? contentDisposition, String fallback) {
  if (contentDisposition == null) return fallback;
  final match = RegExp('filename="?([^";]+)"?').firstMatch(contentDisposition);
  return match?.group(1) ?? fallback;
}

/// A safe filename built from a label and the stored file's URL.
///
/// Keeps the URL's extension so the viewer still opens, and strips the label
/// down to characters every filesystem accepts.
String attachmentFilename(String label, String url) {
  final path = url.split('?').first;
  final lastSegment = path.split('/').last;
  final extension = lastSegment.contains('.') ? lastSegment.split('.').last : '';

  final base = label
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final safeBase = base.isEmpty ? 'attachment' : base;

  return extension.isNotEmpty && extension.length <= 5 ? '$safeBase.$extension' : safeBase;
}
