import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/push/push_notification_service.dart';
import 'core/router.dart';
import 'core/storage/cookie_jar_provider.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/announcements/data/announcement_repository.dart';
import 'features/attendance/data/attendance_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/state/auth_state.dart';
import 'features/discipline/data/discipline_repository.dart';
import 'features/employees/data/employee_repository.dart';
import 'features/leave/data/leave_repository.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/payroll/data/payroll_repository.dart';
import 'features/payslips/data/payslip_repository.dart';
import 'features/notifications/state/notifications_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Best-effort: a Firebase misconfiguration (still-placeholder credentials,
  // see firebase_options.dart) must never block app startup — push simply
  // stays off for the session and NotificationsState's polling covers it.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase.initializeApp failed (push disabled for this session): $e');
  }

  final tokenStorage = TokenStorage();
  final cookieJar = await createPersistedCookieJar();

  late final AuthState authState;
  final dioClient = DioClient(
    tokenStorage: tokenStorage,
    cookieJar: cookieJar,
    onSessionExpired: () => authState.handleSessionExpired(),
  );
  final authRepository = AuthRepository(
    dioClient: dioClient,
    tokenStorage: tokenStorage,
  );
  final employeeRepository = EmployeeRepository(dioClient: dioClient);
  final attendanceRepository = AttendanceRepository(dioClient: dioClient);
  final notificationRepository = NotificationRepository(dioClient: dioClient);
  final announcementRepository = AnnouncementRepository(dioClient: dioClient);
  final leaveRepository = LeaveRepository(dioClient: dioClient);
  final payslipRepository = PayslipRepository(dioClient: dioClient);
  final disciplineRepository = DisciplineRepository(dioClient: dioClient);
  final payrollRepository = PayrollRepository(dioClient: dioClient);
  final notificationsState = NotificationsState(repository: notificationRepository);
  final pushNotificationService = PushNotificationService(
    notificationRepository: notificationRepository,
    notificationsState: notificationsState,
  );

  authState = AuthState(authRepository: authRepository);
  authState.addListener(() {
    if (authState.status == AuthStatus.authenticated) {
      notificationsState.start();
      unawaited(pushNotificationService.start());
    } else if (authState.status == AuthStatus.unauthenticated) {
      unawaited(pushNotificationService.stop());
      notificationsState.stop();
    }
  });

  final router = buildRouter(authState);
  authState.bootstrap();

  runApp(MyApp(
    authState: authState,
    notificationsState: notificationsState,
    employeeRepository: employeeRepository,
    attendanceRepository: attendanceRepository,
    notificationRepository: notificationRepository,
    announcementRepository: announcementRepository,
    leaveRepository: leaveRepository,
    payslipRepository: payslipRepository,
    disciplineRepository: disciplineRepository,
    payrollRepository: payrollRepository,
    router: router,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.authState,
    required this.notificationsState,
    required this.employeeRepository,
    required this.attendanceRepository,
    required this.notificationRepository,
    required this.announcementRepository,
    required this.leaveRepository,
    required this.payslipRepository,
    required this.disciplineRepository,
    required this.payrollRepository,
    required this.router,
  });

  final AuthState authState;
  final NotificationsState notificationsState;
  final EmployeeRepository employeeRepository;
  final AttendanceRepository attendanceRepository;
  final NotificationRepository notificationRepository;
  final AnnouncementRepository announcementRepository;
  final LeaveRepository leaveRepository;
  final PayslipRepository payslipRepository;
  final DisciplineRepository disciplineRepository;
  final PayrollRepository payrollRepository;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authState),
        ChangeNotifierProvider.value(value: notificationsState),
        Provider.value(value: employeeRepository),
        Provider.value(value: attendanceRepository),
        Provider.value(value: notificationRepository),
        Provider.value(value: announcementRepository),
        Provider.value(value: leaveRepository),
        Provider.value(value: payslipRepository),
        Provider.value(value: disciplineRepository),
        Provider.value(value: payrollRepository),
      ],
      child: MaterialApp.router(
        title: 'ileny',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
