import 'package:go_router/go_router.dart';

import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/state/auth_state.dart';
import '../features/home/screens/home_shell.dart';

/// Redirect helper for role-gated routes: return this from a GoRoute's
/// own `redirect` once a manager/admin-only route exists (plan.txt
/// Phase 4 Tier A/B). No route needs it yet in Phase 0.
String? roleGuardRedirect(AuthState authState, Set<String> requiredRoles) {
  if (requiredRoles.isEmpty) return null;
  return authState.hasAnyRole(requiredRoles) ? null : '/home';
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
      final loggingIn = state.matchedLocation == '/login';

      if (!signedIn && !loggingIn) return '/login';
      if (signedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
    ],
  );
}
