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

  /// Organisations the last login attempt matched, when the address has
  /// accounts in more than one tenant. Empty in the ordinary single-account
  /// case. The password deliberately isn't held here — the sign-in form keeps
  /// it for the one re-submit and nothing else stores it.
  List<TenantChoice> tenantChoices = const [];

  bool get tenantChoicePending => tenantChoices.isNotEmpty;

  List<String> get roleNames => currentUser?.roleNames ?? const [];

  bool hasAnyRole(Iterable<String> roles) => roles.any(roleNames.contains);

  Future<void> bootstrap() async {
    final me = await _authRepository.restoreSession();
    currentUser = me;
    status = me != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// [tenantId] is set only on the second call of a multi-organisation login,
  /// once the user has picked from [tenantChoices]; the same email and
  /// password go up again with it.
  ///
  /// The three response shapes are checked in the order the API contract
  /// requires — tenant choice first, since that shape carries neither tokens
  /// nor the two-factor flag and would otherwise look like a no-op.
  Future<void> login({
    required String email,
    required String password,
    String? tenantId,
  }) async {
    final result = await _authRepository.login(
      email: email,
      password: password,
      tenantId: tenantId,
    );
    if (result.tenantChoiceRequired) {
      tenantChoices = result.tenantChoices!;
      pendingEmail = email;
      notifyListeners();
      return;
    }
    tenantChoices = const [];
    if (result.twoFactorRequired) {
      twoFactorPending = true;
      pendingEmail = email;
      notifyListeners();
      return;
    }
    await _loadCurrentUser();
  }

  /// Backs out of the organisation picker to the plain sign-in form.
  void cancelTenantChoice() {
    if (tenantChoices.isEmpty) return;
    tenantChoices = const [];
    pendingEmail = null;
    notifyListeners();
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
