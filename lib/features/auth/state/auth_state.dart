// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../data/auth_models.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Single source of truth for "is there a session, and what can this user
/// do" — cached in memory per plan.txt section 4 (roleNames/employeeId
/// are read on almost every screen, no reason to refetch /me per screen).
/// Also the [refreshListenable] the router watches for its auth guard.
class AuthState extends ChangeNotifier {
  AuthState({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  AuthStatus status = AuthStatus.unknown;
  MeResponse? currentUser;
  bool twoFactorPending = false;
  String? pendingEmail;

  List<String> get roleNames => currentUser?.roleNames ?? const [];

  bool hasAnyRole(Iterable<String> roles) => roles.any(roleNames.contains);

  Future<void> bootstrap() async {
    final me = await _authRepository.restoreSession();
    currentUser = me;
    status = me != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _authRepository.login(email: email, password: password);
    if (result.twoFactorRequired) {
      twoFactorPending = true;
      pendingEmail = email;
      notifyListeners();
      return;
    }
    await _loadCurrentUser();
  }

  Future<void> verifyTwoFactor(String code) async {
    final email = pendingEmail;
    if (email == null) {
      throw StateError('No pending two-factor login to verify.');
    }
    await _authRepository.verifyTwoFactor(email: email, code: code);
    twoFactorPending = false;
    pendingEmail = null;
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await _authRepository.me();
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by the dio auth interceptor when a refresh attempt fails
  /// mid-session (e.g. the refresh cookie was revoked/expired) — drops
  /// local session state so the router redirects to /login.
  void handleSessionExpired() {
    if (status != AuthStatus.authenticated) return;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
