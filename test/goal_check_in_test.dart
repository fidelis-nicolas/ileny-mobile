import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/state/auth_state.dart';
import 'package:mobile/features/performance/data/performance_repository.dart';
import 'package:mobile/features/performance/screens/my_goals_screen.dart';
import 'package:provider/provider.dart';

void main() {
  const cases = [
    (label: 'disabled for employees', setting: false, manager: false),
    (label: 'enabled for employees', setting: true, manager: false),
    (
      label: 'disabled for employees with a goal manager',
      setting: false,
      manager: true,
    ),
    (label: 'absent from an older API', setting: null, manager: false),
  ];

  for (final scenario in cases) {
    testWidgets('Check in when progress is ${scenario.label}', (tester) async {
      final tokenStorage = TokenStorage();
      final client = DioClient(
        tokenStorage: tokenStorage,
        cookieJar: CookieJar(),
        onSessionExpired: () {},
      );
      final auth =
          AuthState(
              authRepository: AuthRepository(
                dioClient: client,
                tokenStorage: tokenStorage,
              ),
            )
            ..currentUser = MeResponse(
              id: 'user',
              tenantId: 'tenant',
              email: 'employee@example.com',
              roleNames: const [],
              permissions: [if (scenario.manager) 'performance:manage'],
            );
      final requests = <Object?>[];
      client.dio.interceptors
        ..clear()
        ..add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              final data = switch ((request.method, request.path)) {
                ('GET', '/performance/goals/me') => {
                  'content': [
                    {
                      'id': 'goal',
                      'employeeId': 'employee',
                      'title': 'Complete onboarding',
                      'status': 'ACTIVE',
                      'progressPercent': 40,
                      if (scenario.setting != null)
                        'allowEmployeeGoalProgressUpdates': scenario.setting,
                    },
                  ],
                  'totalElements': 1,
                  'totalPages': 1,
                  'number': 0,
                  'size': 20,
                  'first': true,
                  'last': true,
                },
                ('GET', '/performance/goals/goal/updates') => [],
                ('POST', '/performance/goals/goal/updates') => {
                  'id': 'update',
                  'goalId': 'goal',
                  'createdAt': '2026-11-23T12:00:00Z',
                },
                _ => throw StateError(
                  'Unexpected request: ${request.method} ${request.path}',
                ),
              };
              if (request.method == 'POST') requests.add(request.data);
              handler.resolve(Response(requestOptions: request, data: data));
            },
          ),
        );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => auth),
            Provider(create: (_) => PerformanceRepository(dioClient: client)),
          ],
          child: const MaterialApp(home: MyGoalsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      final submit = find.widgetWithText(FilledButton, 'Record check-in');
      final canUpdateProgress = scenario.manager || scenario.setting != false;
      if (canUpdateProgress) {
        expect(slider, findsOneWidget);
        tester.widget<Slider>(slider).onChanged!(75);
      } else {
        expect(slider, findsNothing);
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      }

      await tester.enterText(
        find.byType(TextField),
        'The first milestone is complete.',
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(requests, [
        {
          'note': 'The first milestone is complete.',
          if (canUpdateProgress) 'progressPercent': 75,
        },
      ]);
      expect(submit, findsNothing);
    });
  }
}
