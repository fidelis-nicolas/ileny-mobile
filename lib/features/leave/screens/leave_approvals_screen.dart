import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/leave_models.dart';
import '../data/leave_repository.dart';

/// Tier A: tenant-wide pending-approvals queue — there's no manager/team
/// scoping on the backend, so every HR_MANAGER/ORG_ADMIN sees every pending
/// request, not just "their" team's (see [LeaveRepository.requests]).
class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  final _listKey = GlobalKey<PaginatedListViewState<LeaveRequestResponse>>();
  final _busyIds = <String>{};

  Future<void> _approve(LeaveRequestResponse request) async {
    setState(() => _busyIds.add(request.id));
    try {
      await context.read<LeaveRepository>().approve(request.id);
      _listKey.currentState?.refresh();
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<void> _reject(LeaveRequestResponse request) async {
    final reason = await _promptReason();
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _busyIds.add(request.id));
    try {
      await context.read<LeaveRepository>().reject(request.id, reason);
      _listKey.currentState?.refresh();
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<String?> _promptReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<LeaveRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Leave approvals')),
      body: PaginatedListView<LeaveRequestResponse>(
        key: _listKey,
        emptyMessage: 'No pending leave requests.',
        fetchPage: (page, size) =>
            repository.requests(status: 'PENDING', page: page, size: size),
        itemBuilder: (context, request) {
          final busy = _busyIds.contains(request.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.palette.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.employeeFullName,
                    style: TextStyle(
                      color: context.palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request.leaveTypeName} · ${request.startDate} → ${request.endDate} · '
                    '${request.daysRequested.toStringAsFixed(1)} day(s)',
                    style: TextStyle(color: context.palette.textMuted, fontSize: 13),
                  ),
                  if (request.reason != null && request.reason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(request.reason!, style: const TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : () => _reject(request),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: busy ? null : () => _approve(request),
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
