import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../legal_documents.dart';

/// Passive acceptance notice for the sign-in screen.
///
/// Accounts are provisioned by an organisation administrator rather than
/// created in the app, so there is no registration step to hang a consent
/// checkbox off — and no acceptance to record, which is the web signup flow's
/// job. Presenting the documents at sign-in, one tap away, is what fits, and it
/// satisfies Google Play's requirement that the policy be reachable in-app.
class LegalConsentFooter extends StatefulWidget {
  const LegalConsentFooter({super.key});

  @override
  State<LegalConsentFooter> createState() => _LegalConsentFooterState();
}

class _LegalConsentFooterState extends State<LegalConsentFooter> {
  // Recognisers hold a callback each and must be disposed with the widget.
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => LegalDocument.termsOfService.open(context);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => LegalDocument.privacyPolicy.open(context);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textMuted,
          ),
          children: [
            const TextSpan(text: 'By signing in you agree to the '),
            TextSpan(
              text: LegalDocument.termsOfService.title,
              style: _linkStyle,
              recognizer: _termsTap,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: LegalDocument.privacyPolicy.title,
              style: _linkStyle,
              recognizer: _privacyTap,
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

const _linkStyle = TextStyle(
  color: AppColors.primaryGreen,
  fontWeight: FontWeight.w600,
  decoration: TextDecoration.underline,
  decorationColor: AppColors.primaryGreen,
);
