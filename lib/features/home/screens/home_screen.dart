import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../../../core/auth/roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shape.dart';
import '../../../core/theme/app_typography.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/state/auth_state.dart';
import '../../billing/screens/subscription_screen.dart';
import '../../discipline/screens/my_queries_screen.dart';
import '../../employees/data/employee_models.dart';
import '../../employees/data/employee_repository.dart';
import '../../employees/screens/directory_screen.dart';
import '../../employees/screens/employee_avatar.dart';
import '../../employees/screens/profile_screen.dart';
import '../../payroll/screens/payroll_cycles_screen.dart';
import '../../performance/screens/my_appraisals_screen.dart';
import '../../performance/screens/my_goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<_HomeKpis>? _kpiFuture;
  Future<List<UpcomingBirthdayResponse>>? _birthdaysFuture;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();
    // Headcount comes from the employee list and the rate from the daily register, and both
    // accept the department-scoped read — so a head of department gets the same two tiles,
    // counting their own team. The panel hides itself on error, which covers someone holding
    // one of the two permissions but not the other.
    if (authState.hasAnyPermission(kDirectoryPermissions)) {
      _kpiFuture = _loadKpis();
    }
    // A separate gate, because `/employees/birthdays` has no department tier and takes the
    // tenant-wide `employee:read` alone. Under the directory gate a head of department would
    // be shown a section whose one request comes back 403. Employees still get their own
    // greeting as a notification.
    if (authState.hasAnyPermission(kBirthdayPermissions)) {
      _birthdaysFuture = context.read<EmployeeRepository>().upcomingBirthdays(days: 30);
    }
  }

  Future<_HomeKpis> _loadKpis() async {
    final employees = context.read<EmployeeRepository>();
    final attendance = context.read<AttendanceRepository>();

    final headcountPage = await employees.list(status: 'ACTIVE', page: 0, size: 1);
    final today = await attendance.daily();
    final present = today
        .where((record) => record.status == 'PRESENT' || record.status == 'LATE')
        .length;
    final headcount = headcountPage.totalElements;
    final rate = headcount == 0 ? 0.0 : (present / headcount) * 100;
    return _HomeKpis(headcount: headcount, attendanceRatePercent: rate);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final user = authState.currentUser;
    // One gate per destination. These were a single "isManager" check, which meant the
    // directory and payroll stood or fell together even though they are different
    // permissions — and a head of department, holding the first and not the second, got
    // neither.
    final canSeeDirectory = authState.hasAnyPermission(kDirectoryPermissions);
    final canSeePayroll = authState.hasAnyPermission(kPayrollPermissions);
    final isOrgAdmin = authState.hasAnyPermission(kInvitePermissions);

    return Scaffold(
      appBar: AppBar(
        title: user == null ? const Text('Home') : _OrgBrandingTitle(user: user),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _Greeting(user: user),
          if (_kpiFuture != null) ...[
            const SizedBox(height: 22),
            FutureBuilder<_HomeKpis>(
              future: _kpiFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    "Overview isn't available right now.",
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                final kpis = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.groups_outlined,
                        label: 'Headcount',
                        value: '${kpis.headcount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.how_to_reg_outlined,
                        label: 'In today',
                        value: '${kpis.attendanceRatePercent.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 28),
          const _SectionHeading('Your workspace'),
          const SizedBox(height: 12),
          // A grid rather than a stack of full-width rows. Six identical bars
          // gave every destination the same weight and read as a settings menu;
          // paired tiles are scannable at a glance and leave vertical room for
          // the sections that actually carry information.
          _QuickActionGrid(
            actions: [
              // Ungated: every employee needs to reach the queries raised
              // against them. The HR-side case list is elsewhere and stays
              // role-gated.
              _QuickAction(
                icon: Icons.forum_outlined,
                label: 'My Queries',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyQueriesScreen()),
                ),
              ),
              // Also ungated. Mobile carries the employee's half of performance
              // — their self-assessment and the outcome. Templates, cycles, and
              // writing reviews are administrative jobs done sitting down and
              // stay on the web client.
              _QuickAction(
                icon: Icons.trending_up_outlined,
                label: 'My Appraisals',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyAppraisalsScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.flag_outlined,
                label: 'My Goals',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyGoalsScreen()),
                ),
              ),
              // Gated to match the backend: the directory and the records it opens need
              // employee:read or its department variant, neither of which EMPLOYEE holds
              // (see RoleSeeder). Ungated, this offered every employee a tap-path into
              // colleagues' contact details. A head of department gets in on the narrow
              // one, and the backend hands them their own team.
              if (canSeeDirectory)
                _QuickAction(
                  icon: Icons.people_outline,
                  label: 'Directory',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DirectoryScreen()),
                  ),
                ),
              // Payroll has no department tier at all — it is the one thing the HOD role was
              // built to stay out of.
              if (canSeePayroll)
                _QuickAction(
                  icon: Icons.payments_outlined,
                  label: 'Payroll Cycles',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PayrollCyclesScreen()),
                  ),
                ),
              if (isOrgAdmin)
                _QuickAction(
                  icon: Icons.card_membership_outlined,
                  label: 'Subscription',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
            ],
          ),
          if (_birthdaysFuture != null)
            FutureBuilder<List<UpcomingBirthdayResponse>>(
              future: _birthdaysFuture,
              builder: (context, snapshot) {
                // No section at all while loading, on error, or when nobody
                // has a birthday coming up. This is a nice-to-have panel, and
                // an empty "Birthdays" heading or a spinner for one is more
                // noise than the feature is worth.
                final birthdays = snapshot.data;
                if (birthdays == null || birthdays.isEmpty) {
                  return const SizedBox.shrink();
                }
                final shown = birthdays.take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const _SectionHeading('Birthdays'),
                    const SizedBox(height: 12),
                    _Panel(
                      child: Column(
                        children: [
                          for (var i = 0; i < shown.length; i++)
                            _BirthdayRow(
                              birthday: shown[i],
                              isLast: i == shown.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Greeting block: time of day as a letterspaced eyebrow, the person's name
/// below it in the display serif.
///
/// This is the one place on the screen that gets to be typographic, and that is
/// what makes it read as the top of a page rather than as the first row of a
/// list.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final MeResponse? user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final partOfDay = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    // First name only. The full legal name is the wrong register for a
    // greeting, and it is the part most likely to wrap on a narrow phone.
    final fullName = user?.employeeFullName;
    final name = (fullName == null || fullName.trim().isEmpty)
        ? user?.email
        : fullName.trim().split(RegExp(r'\s+')).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partOfDay.toUpperCase(),
          style: AppTypography.eyebrow(context.palette.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          name ?? 'Welcome back',
          style: Theme.of(context).textTheme.headlineMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Small-caps section label. The letterspaced sans is the counterweight to the
/// serif above it — a second bold serif heading would compete with the greeting
/// rather than rank below it.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.eyebrow(context.palette.textMuted),
    );
  }
}

/// Card surface at the app's resting elevation, for anything that is a group of
/// rows rather than a single control.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: palette.border),
        boxShadow: palette.elevation1,
      ),
      child: child,
    );
  }
}

/// Two-column grid of destination tiles.
///
/// Hand-laid as rows rather than a `GridView` so the whole thing measures its
/// own height inside the parent `ListView` — a nested scrollable here would
/// either fight the outer scroll or need a hardcoded extent that breaks as
/// role-gating changes how many tiles there are.
class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      final left = actions[i];
      final right = i + 1 < actions.length ? actions[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < actions.length ? 12 : 0),
          child: IntrinsicHeight(
            // Both tiles take the height of the taller one, so a label that
            // wraps to two lines doesn't leave its neighbour short. The Row
            // needs a bounded height for `stretch`, which inside a ListView it
            // otherwise does not have.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                const SizedBox(width: 12),
                // An odd tile keeps its column width instead of stretching, so
                // the grid stays a grid on the last row.
                Expanded(child: right ?? const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// One destination tile: a tinted icon plate over a label.
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // The outline lives on the Material's own shape rather than on a nested
    // Ink or Container, so the tap ripple is clipped by the same rounded
    // rectangle that draws the border.
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, color: palette.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One upcoming birthday. No age and no year — the backend does not send the
/// year of birth, which is deliberate.
class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.birthday, required this.isLast});

  final UpcomingBirthdayResponse birthday;

  /// The last row drops its divider, so the panel doesn't end on a stray rule.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final isToday = birthday.daysUntil == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
      child: Row(
        children: [
          EmployeeAvatar(
            photoUrl: birthday.photoUrl,
            initials: _initials(birthday.fullName),
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  birthday.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (birthday.departmentName != null)
                  Text(
                    birthday.departmentName!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _dayAndMonth(birthday.nextBirthday),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [AppTypography.tabularFigures],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                switch (birthday.daysUntil) {
                  0 => 'Today',
                  1 => 'Tomorrow',
                  final days => 'in $days days',
                },
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isToday ? palette.accentInk : palette.textMuted,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dayAndMonth(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return DateFormat('d MMM').format(date);
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty && words[0].isNotEmpty ? words[0][0] : '';
    final second = words.length > 1 && words[1].isNotEmpty ? words[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}

/// Organisation branding shown in the Home AppBar — logo (falls back to
/// initials, same as [EmployeeAvatar]) alongside the tenant name.
class _OrgBrandingTitle extends StatelessWidget {
  const _OrgBrandingTitle({required this.user});

  final MeResponse user;

  @override
  Widget build(BuildContext context) {
    final name = user.tenantName;
    if (name == null || name.isEmpty) return const Text('Home');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmployeeAvatar(photoUrl: user.tenantLogoUrl, initials: _initials(name), radius: 14),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty && words[0].isNotEmpty ? words[0][0] : '';
    final second = words.length > 1 && words[1].isNotEmpty ? words[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}

class _HomeKpis {
  const _HomeKpis({required this.headcount, required this.attendanceRatePercent});

  final int headcount;
  final double attendanceRatePercent;
}

/// A single figure with its label. The figure is set in the display serif and
/// in tabular figures, so a column of these doesn't jitter as numbers refresh.
class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: palette.border),
        boxShadow: palette.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.textMuted),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.display(
              size: 28,
              weight: FontWeight.w600,
              color: palette.textHeading,
            ).copyWith(fontFeatures: const [AppTypography.tabularFigures]),
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppTypography.eyebrow(palette.textMuted)),
        ],
      ),
    );
  }
}
