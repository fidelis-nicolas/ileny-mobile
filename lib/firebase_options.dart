import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase config for push notifications (Phase 5), for the `ileny-app`
/// project.
///
/// Android carries its credentials in Dart. These values mirror
/// `android/app/google-services.json` and must stay in step with it — the Dart
/// side is what `Firebase.initializeApp` reads, the JSON is what the Google
/// Services Gradle plugin reads.
///
/// iOS deliberately does not. The Firebase iOS SDK configures itself from
/// `ios/Runner/GoogleService-Info.plist`, so [currentPlatformOrNull] returns
/// null there and `main` calls `Firebase.initializeApp()` with no arguments —
/// one source of truth instead of a plist and a Dart copy that can drift.
/// Until an iOS app is registered in the `ileny-app` project that plist does
/// not exist, initialization throws, and `main` catches it: push is simply off
/// on iOS and [NotificationsState]'s polling carries the unread badge. See the
/// iOS section of README.md for what registering it involves.
///
/// The `apiKey` below is not a secret: it ships inside every APK and only
/// identifies the project to Google's SDKs. Restrict it by package name and
/// SHA-1 in the Google Cloud console so it can't be reused elsewhere.
///
/// Sending still needs the backend's service-account credentials —
/// `FirebaseConfig` there stays a no-op until those are configured.
class DefaultFirebaseOptions {
  /// The options to initialize Firebase with, or null when the platform's own
  /// SDK reads its configuration from a bundled file instead.
  ///
  /// Throws for platforms this app does not target, so an unconfigured build
  /// fails loudly during development rather than reporting a working Firebase
  /// that isn't.
  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — this '
        'app ships on Android and iOS only (see plan.txt).',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return null;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '$defaultTargetPlatform — this app ships on Android and iOS only '
          '(see plan.txt).',
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
