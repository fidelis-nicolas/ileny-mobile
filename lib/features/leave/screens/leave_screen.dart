import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/roles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../auth/state/auth_state.dart';
import '../data/leave_models.dart';
import '../data/leave_repository.dart';
import 'leave_approvals_screen.dart';
import 'request_leave_screen.dart';

/// Self-service leave: this year's balances, a "Request leave" action, and
/// paginated history of the signed-in employee's own requests (plan.txt
/// Phase 2). Approvals are Phase 4 Tier A, out of scope here.
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveBalanceResponse> _balances = const [];
  List<LeaveTypeResponse> _leaveTypes = const [];
  bool _loadingBalances = true;
  String? _balancesError;
  final _historyKey = GlobalKey<PaginatedListViewState<LeaveRequestResponse>>();

  String get _employeeId => context.read<AuthState>().currentUser!.employeeId!;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    setState(() {
      _loadingBalances = true;
      _balancesError = null;
    });
    final repository = context.read<LeaveRepository>();
    try {
      final results = await Future.wait([
        repository.balance(_employeeId, year: DateTime.now().year),
        repository.types(),
      ]);
      setState(() {
        _balances = results[0] as List<LeaveBalanceResponse>;
        _leaveTypes = results[1] as List<LeaveTypeResponse>;
      });
    } on ApiException catch (e) {
      setState(() => _balancesError = e.message);
    } finally {
      if (mounted) setState(() => _loadingBalances = false);
    }
  }

  Future<void> _openRequestForm() async {
    if (_leaveTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leave types available yet.')),
      );
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RequestLeaveScreen(leaveTypes: _leaveTypes),
      ),
    );
    if (created == true) {
      _loadBalances();
      _historyKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<LeaveRepository>();
    final isManager = context.watch<AuthState>().hasAnyRole(kManagerRoles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Leave approvals',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaveApprovalsScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRequestForm,
        icon: const Icon(Icons.add),
        label: const Text('Request'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBalances();
          _historyKey.currentState?.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Balances',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingBalances)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_balancesError != null)
              Text(_balancesError!, style: const TextStyle(color: AppColors.accentOrange))
            else if (_balances.isEmpty)
              const Text(
                'No leave balances set up yet.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ..._balances.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BalanceCard(balance: b),
                  )),
            const SizedBox(height: 16),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: PaginatedListView<LeaveRequestResponse>(
                key: _historyKey,
                emptyMessage: 'No leave requests yet.',
                fetchPage: (page, size) =>
                    repository.requests(employeeId: _employeeId, page: page, size: size),
                itemBuilder: (context, request) => _RequestTile(request: request),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final LeaveBalanceResponse balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              balance.leaveTypeName,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
            ),
          ),
          Text(
            '${balance.remainingDays.toStringAsFixed(1)} / ${balance.totalDays.toStringAsFixed(1)} days',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final LeaveRequestResponse request;

  Color get _statusColor {
    switch (request.status) {
      case 'APPROVED':
        return AppColors.primaryGreen;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.accentOrange;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${request.leaveTypeName} · ${request.startDate} → ${request.endDate}',
        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${request.daysRequested.toStringAsFixed(1)} day(s)'
          '${request.reason != null && request.reason!.isNotEmpty ? ' · ${request.reason}' : ''}'),
      trailing: Text(request.status, style: TextStyle(color: _statusColor, fontSize: 12)),
    );
  }
}
