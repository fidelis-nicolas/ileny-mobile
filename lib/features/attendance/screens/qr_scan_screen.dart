import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';

/// Camera screen for scanning a branch QR code, popped with the branch's
/// `qrToken` (a UUID string) once a code is read — or with `null` if the user
/// backs out. The backend generates these codes as a JSON payload
/// (`TenantService.getBranchQrCodePng`):
///
/// ```json
/// {"branchId":"<uuid>","qrToken":"<uuid>"}
/// ```
///
/// Only the `qrToken` half is sent back to `/attendance/clock-in`; the backend
/// resolves the branch from the *employee's* own assignment and rejects a token
/// that doesn't match it, so there is nothing to gain by trusting the scanned
/// `branchId`.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.title = 'Scan branch QR code'});

  final String title;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Detections keep arriving while the pop animation runs; without this the
  /// screen would pop more than once and unwind the caller's route too.
  bool _handled = false;
  String? _rejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final token = _extractQrToken(barcode.rawValue);
      if (token != null) {
        _handled = true;
        Navigator.of(context).pop(token);
        return;
      }
    }

    // Something scanned, but it isn't one of ours — say so instead of leaving
    // the user staring at a camera that appears to do nothing.
    if (capture.barcodes.isNotEmpty && mounted) {
      setState(() => _rejected = "That isn't an ileny branch QR code.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _rejected ?? 'Point your camera at the QR code posted at your branch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _rejected == null ? Colors.white : context.palette.danger,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accepts the backend's JSON payload, and also a bare token string so a
/// hand-made or re-encoded code still works.
String? _extractQrToken(String? rawValue) {
  if (rawValue == null) return null;
  final raw = rawValue.trim();
  if (raw.isEmpty) return null;

  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final token = decoded['qrToken'];
        if (token is String && _isUuid(token)) return token;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  return _isUuid(raw) ? raw : null;
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool _isUuid(String value) => _uuidPattern.hasMatch(value);

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            denied
                ? 'Camera permission is required to scan the branch QR code. '
                    'Enable it in system settings and try again.'
                : "The camera couldn't be started. Try again.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
