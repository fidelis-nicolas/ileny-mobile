import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The published legal documents, opened in the device browser.
///
/// They are deliberately not bundled in the app. The API's `LegalController`
/// records the reasoning: the documents are static pages served by the
/// marketing front end because they are legal text, not application data, and
/// belong where they can be changed without a deploy. A copy inside the APK
/// could only be corrected by shipping a Play release, and would sit at a
/// version the server no longer recognises in the meantime.
///
/// Nothing here records acceptance. Only the web signup flow does that, against
/// `GET /api/v1/legal/versions` — employees never register in the app, their
/// accounts are provisioned by an organisation administrator.
enum LegalDocument {
  termsOfService(
    title: 'Terms of Service',
    url: 'https://ileny.app/terms',
  ),
  privacyPolicy(
    title: 'Privacy Policy',
    url: 'https://ileny.app/privacy',
  );

  const LegalDocument({required this.title, required this.url});

  final String title;
  final String url;

  /// Hands the document to the browser. On failure the URL is surfaced in a
  /// snackbar rather than swallowed — Google Play requires the policy to be
  /// reachable from inside the app, so a silent no-op here is a compliance
  /// problem as much as a usability one.
  Future<void> open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      launched = false;
    }
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open a browser. Visit $url')),
      );
    }
  }
}
