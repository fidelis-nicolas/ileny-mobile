import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../leave/screens/leave_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/state/notifications_state.dart';
import '../../payslips/screens/payslips_screen.dart';
import 'home_screen.dart';

/// App shell for the signed-in session: bottom nav across the six
/// top-level destinations from plan.txt Phase 0. All six are wired up as
/// of Phase 3.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    HomeScreen(),
    AttendanceScreen(),
    LeaveScreen(),
    PayslipsScreen(),
    AnnouncementsScreen(),
    NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsState>().unreadCount;

    return Scaffold(
      body: IndexedStack(index: _index, children: _destinations),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textMuted,
        onTap: (index) => setState(() => _index = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            label: 'Attendance',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined),
            label: 'Leave',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Payslips',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
