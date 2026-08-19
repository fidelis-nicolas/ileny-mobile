import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/roles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/state/auth_state.dart';
import '../../discipline/screens/discipline_cases_screen.dart';
import '../data/employee_models.dart';
import '../data/employee_repository.dart';
import 'employee_avatar.dart';

const _statusOptions = ['ACTIVE', 'INACTIVE', 'TERMINATED', 'SUSPENDED'];

/// Directory drill-down: the record itself for anyone who can reach the directory, plus
/// manager actions gated one at a time.
///
/// Status change, discipline and invite are three separate permissions on the backend, so
/// they get three separate checks here rather than one for the section. A head of department
/// holds the discipline one and neither of the others — under a single check they either saw
/// all three and got a 403 from two, or saw none and lost the one they could use.
class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employee});

  final EmployeeResponse employee;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late EmployeeResponse _employee;
  bool _busy = false;
  bool _invited = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  Future<void> _changeStatus() async {
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: _employee.status,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in _statusOptions)
                RadioListTile<String>(value: option, title: Text(option)),
            ],
          ),
        ),
      ),
    );
    if (status == null || status == _employee.status || !mounted) return;

    setState(() => _busy = true);
    try {
      final updated = await context.read<EmployeeRepository>().updateStatus(_employee.id, status);
      setState(() => _employee = updated);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final repository = context.read<EmployeeRepository>();
    List<RoleResponse> roles;
    try {
      roles = await repository.roles();
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
      return;
    }
    if (!mounted) return;
    if (roles.isEmpty) {
      _showError('No roles are configured to assign.');
      return;
    }

    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite to app'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in roles)
                CheckboxListTile(
                  value: selected.contains(role.id),
                  title: Text(role.name),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) {
                      selected.add(role.id);
                    } else {
                      selected.remove(role.id);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected.isEmpty ? null : () => Navigator.of(context).pop(true),
              child: const Text('Send invite'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await repository.invite(_employee.id, selected.toList());
      if (mounted) {
        setState(() => _invited = true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invitation sent.')));
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    // One gate per action rather than one for the whole section. These are three different
    // permissions on the backend, and a head of department holds the discipline one without
    // the other two — under a single check they either saw all three and got a 403 from two,
    // or saw none and lost the one they could use.
    final canChangeStatus = authState.hasAnyPermission(kEmployeeUpdatePermissions);
    final canSeeDiscipline = authState.hasAnyPermission(kDisciplinePermissions);
    final canInvite = authState.hasAnyPermission(kInvitePermissions) &&
        !_employee.hasLoginAccount &&
        !_invited;
    final showActions = canChangeStatus || canSeeDiscipline || canInvite;

    return Scaffold(
      appBar: AppBar(title: Text(_employee.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: EmployeeAvatar(
              photoUrl: _employee.photoUrl,
              initials: _initials(_employee),
              radius: 44,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _employee.fullName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.palette.primary,
              ),
            ),
          ),
          Center(
            child: Text(
              _employee.employeeNumber,
              style: TextStyle(color: context.palette.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(label: 'Position', value: _employee.positionName),
          _InfoTile(label: 'Department', value: _employee.departmentName),
          _InfoTile(label: 'Branch', value: _employee.branchName),
          _InfoTile(label: 'Status', value: _employee.status),
          _InfoTile(label: 'Email', value: _employee.email),
          _InfoTile(label: 'Phone', value: _employee.phone),
          _InfoTile(
            label: 'Login account',
            value: _employee.hasLoginAccount || _invited ? 'Yes' : 'No',
          ),
          if (showActions) ...[
            const SizedBox(height: 24),
            Text(
              'Manager actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.palette.primary,
              ),
            ),
            const SizedBox(height: 12),
            if (canChangeStatus)
              OutlinedButton.icon(
                onPressed: _busy ? null : _changeStatus,
                icon: const Icon(Icons.toggle_on_outlined),
                label: const Text('Change status'),
              ),
            if (canSeeDiscipline) ...[
              if (canChangeStatus) const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DisciplineCasesScreen(employee: _employee),
                          ),
                        ),
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('Discipline cases'),
              ),
            ],
            if (canInvite) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _invite,
                icon: const Icon(Icons.mail_outline),
                label: const Text('Invite to app'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _initials(EmployeeResponse employee) {
    final first = employee.firstName.isNotEmpty ? employee.firstName[0] : '';
    final last = employee.lastName.isNotEmpty ? employee.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              (value == null || value!.isEmpty) ? '—' : value!,
              style: TextStyle(color: context.palette.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
