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
      // A hairline above the bar instead of a shadow: the bar is the same
      // colour as a card, and on the warm paper background a shadow here reads
      // as grime rather than as depth.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.palette.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            // Six destinations is one past what a NavigationBar comfortably
            // labels on a narrow phone, so the longer names are shortened
            // rather than left to overflow: Attendance/Announcements/
            // Notifications become Time/News/Alerts. The screens themselves
            // keep their full titles in the AppBar.
            const NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule_rounded),
              label: 'Time',
            ),
            const NavigationDestination(
              icon: Icon(Icons.event_available_outlined),
              selectedIcon: Icon(Icons.event_available_rounded),
              label: 'Leave',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Payslips',
            ),
            const NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'News',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
