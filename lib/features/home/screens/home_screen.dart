import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/state/auth_state.dart';
import '../../employees/data/employee_repository.dart';
import '../../employees/screens/directory_screen.dart';
import '../../employees/screens/employee_avatar.dart';
import '../../employees/screens/profile_screen.dart';
import '../../payroll/screens/payroll_cycles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<_HomeKpis>? _kpiFuture;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();
    if (authState.hasAnyRole(kManagerRoles)) {
      _kpiFuture = _loadKpis();
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
    final isManager = authState.hasAnyRole(kManagerRoles);

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
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            user == null ? 'Signed in' : 'Welcome, ${user.employeeFullName ?? user.email}',
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _QuickAction(
            icon: Icons.people_outline,
            label: 'Employee Directory',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DirectoryScreen()),
            ),
          ),
          if (isManager) ...[
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.payments_outlined,
              label: 'Payroll Cycles',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PayrollCyclesScreen()),
              ),
            ),
          ],
          if (_kpiFuture != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 10),
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
                  return const Text(
                    "Overview isn't available right now.",
                    style: TextStyle(color: AppColors.textMuted),
                  );
                }
                final kpis = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        label: 'Headcount',
                        value: '${kpis.headcount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiTile(
                        label: "Today's attendance",
                        value: '${kpis.attendanceRatePercent.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
