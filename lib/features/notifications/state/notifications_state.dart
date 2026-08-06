// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/notification_repository.dart';

/// Unread-count badge source. Per plan.txt's "no background services"
/// rule, polling only runs while the app is foregrounded/resumed and stops
/// the moment it's backgrounded — [start]/[stop] are driven by
/// [AuthState]'s status so a signed-out session never polls.
class NotificationsState extends ChangeNotifier with WidgetsBindingObserver {
  NotificationsState({required NotificationRepository repository})
      : _repository = repository;

  static const _pollInterval = Duration(seconds: 30);

  final NotificationRepository _repository;
  Timer? _pollTimer;
  bool _observing = false;

  int unreadCount = 0;

  void start() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    unawaited(refreshNow());
    _startPolling();
  }

  void stop() {
    _stopPolling();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    unreadCount = 0;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshNow());
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refreshNow());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refreshNow() async {
    try {
      unreadCount = await _repository.unreadCount();
      notifyListeners();
    } catch (_) {
      // Best-effort background poll — keep the last known count on a
      // transient failure rather than surfacing an error to the user.
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
