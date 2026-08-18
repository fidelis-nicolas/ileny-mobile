import 'package:go_router/go_router.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/state/auth_state.dart';
import '../features/home/screens/home_shell.dart';

/// Routes reachable without a session — the sign-in screen plus the
/// account-recovery pair, which by definition are used while signed out.
const _publicRoutes = {'/login', '/forgot-password', '/reset-password'};

/// Redirect helper for permission-gated routes: return this from a GoRoute's own
/// `redirect` once a manager/admin-only route exists (plan.txt Phase 4 Tier A/B). No route
/// needs it yet.
///
/// Takes permissions rather than role names: tenants can change what a role may do, so the
/// name no longer says what its holder can reach. See [AuthState.hasAnyPermission].
String? permissionGuardRedirect(AuthState authState, Set<String> requiredPermissions) {
  if (requiredPermissions.isEmpty) return null;
  return authState.hasAnyPermission(requiredPermissions) ? null : '/home';
}

GoRouter buildRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authState,
    redirect: (context, state) {
      // Cold-start bootstrap hasn't resolved yet — hold on the current
      // location rather than bouncing to /login and back.
      if (authState.status == AuthStatus.unknown) return null;

      final signedIn = authState.status == AuthStatus.authenticated;
      final onPublicRoute = _publicRoutes.contains(state.matchedLocation);

      if (!signedIn && !onPublicRoute) return '/login';
      if (signedIn && onPublicRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        // ?token= is here for a future deep link off the reset email; today
        // the user pastes the link into the screen itself.
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
    ],
  );
}
