// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/state/notifications_state.dart';

/// Must be a top-level function, not a class method — the Android/iOS FCM
/// plugins invoke it on a separate isolate for background/terminated
/// messages. The system tray already shows a notification banner for any
/// message carrying a `notification` payload, so there's nothing else to do
/// here (no background service, per plan.txt's battery-drain rule).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Registers this device for push and, per plan.txt Phase 5, replaces
/// [NotificationsState]'s polling as the primary way the unread badge stays
/// current — polling remains as a fallback for whenever Firebase isn't
/// configured yet (see the backend's `FirebaseConfig`) or a push is missed.
/// Best-effort throughout: any Firebase/network failure here degrades
/// silently to "this device just doesn't get push," never a crash or a
/// blocked login.
class PushNotificationService {
  PushNotificationService({
    required NotificationRepository notificationRepository,
    required NotificationsState notificationsState,
  })  : _notificationRepository = notificationRepository,
        _notificationsState = notificationsState;

  final NotificationRepository _notificationRepository;
  final NotificationsState _notificationsState;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  Future<void> start() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // iOS shows nothing at all for a push that arrives while the app is
      // open unless asked to; Android has no equivalent switch and stays
      // silent in the foreground. Opting in here rather than matching
      // Android's silence because on iOS a banner over the running app is the
      // platform convention, and the alternative is a notification the user
      // has no way of knowing arrived.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _tokenRefreshSub = messaging.onTokenRefresh.listen(_registerToken);
      // Whether or not a banner is shown, the unread badge should be right
      // immediately rather than at the next poll tick.
      _foregroundSub = FirebaseMessaging.onMessage.listen((_) {
        unawaited(_notificationsState.refreshNow());
      });

      // iOS hands the app its APNs token asynchronously, some way after
      // permission is granted, and getToken() throws outright if FCM has not
      // been given one yet — which on a cold first launch is the usual
      // ordering. Nothing is lost by leaving now: onTokenRefresh, subscribed
      // above, delivers the FCM token as soon as the APNs one lands.
      if (Platform.isIOS && await messaging.getAPNSToken() == null) return;

      final token = await messaging.getToken();
      if (token != null) unawaited(_registerToken(token));
    } catch (e) {
      debugPrint('PushNotificationService.start failed (push disabled for this session): $e');
    }
  }

  Future<void> stop() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _notificationRepository.unregisterDeviceToken(token);
    } catch (_) {
      // Best-effort cleanup on logout — a stale token just gets pruned
      // server-side the next time a push to it fails.
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _notificationRepository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      );
    } catch (e) {
      debugPrint('Device token registration failed: $e');
    }
  }
}
