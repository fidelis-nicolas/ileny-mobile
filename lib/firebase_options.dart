import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Placeholder Firebase config for push notifications (Phase 5) — every
/// value below is a stand-in, not a real project. `Firebase.initializeApp`
/// succeeds with these (it doesn't touch the network at init time), but no
/// push will actually be delivered until they're replaced: run
/// `flutterfire configure` against a real Firebase project, or hand-fill
/// the values from that project's `google-services.json` / console.
/// `PushNotificationService` (mobile) and `FirebaseConfig` (backend) both
/// degrade to a no-op until then — see their doc comments.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — this '
        'app is Android-first (see plan.txt).',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '$defaultTargetPlatform — this app is Android-first (see plan.txt).',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_REAL_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'REPLACE_WITH_REAL_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_REAL_PROJECT_ID.appspot.com',
  );
}
