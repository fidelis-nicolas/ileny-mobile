import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/screens/sign_in_screen.dart';
import 'package:mobile/features/auth/state/auth_state.dart';

void main() {
  testWidgets('Sign-in screen shows the ileny brand and a sign-in button', (
    tester,
  ) async {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient(
      tokenStorage: tokenStorage,
      cookieJar: CookieJar(),
      onSessionExpired: () {},
    );
    final authState = AuthState(
      authRepository: AuthRepository(
        dioClient: dioClient,
        tokenStorage: tokenStorage,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authState,
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    expect(find.text('ileny'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
