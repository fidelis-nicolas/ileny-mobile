import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase config for push notifications (Phase 5), for the `ileny-app`
/// project. These values mirror `android/app/google-services.json` and must
/// stay in step with it — the Dart side is what `Firebase.initializeApp`
/// reads, the JSON is what the Google Services Gradle plugin reads.
///
/// The `apiKey` below is not a secret: it ships inside every APK and only
/// identifies the project to Google's SDKs. Restrict it by package name and
/// SHA-1 in the Google Cloud console so it can't be reused elsewhere.
///
/// Sending still needs the backend's service-account credentials —
/// `FirebaseConfig` there stays a no-op until those are configured.
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
    apiKey: 'AIzaSyCzh5snkx804kv1Zd4nzBvGtV3-Hhz8Oq0',
    appId: '1:753285259194:android:63891387bd0fb0e0894783',
    messagingSenderId: '753285259194',
    projectId: 'ileny-app',
    storageBucket: 'ileny-app.firebasestorage.app',
  );
}
