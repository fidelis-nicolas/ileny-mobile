import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payroll_models.dart';
import '../data/payroll_repository.dart';

/// Single review-and-approve step — no cycle creation, component config, or
/// batch transfer trigger on mobile (plan.txt Tier B). `approve` moves a
/// cycle from OPEN to CLOSED (= approved); locking/payslip email is a
/// separate, web-only step.
class PayrollCycleDetailScreen extends StatefulWidget {
  const PayrollCycleDetailScreen({super.key, required this.cycle});

  final PayrollCycleResponse cycle;

  @override
  State<PayrollCycleDetailScreen> createState() => _PayrollCycleDetailScreenState();
}

class _PayrollCycleDetailScreenState extends State<PayrollCycleDetailScreen> {
  late PayrollCycleResponse _cycle;
  Future<List<PayrollRunResponse>>? _previewFuture;
  bool _approving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cycle = widget.cycle;
    _previewFuture = context.read<PayrollRepository>().preview(_cycle.id);
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve payroll cycle'),
        content: Text(
          'Approve payroll for ${_cycle.employeeCount} employee(s), '
          'total net ${_cycle.totalNet.toStringAsFixed(2)}? This cannot be undone from mobile.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Approve')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _approving = true;
      _error = null;
    });
    try {
      final updated = await context.read<PayrollRepository>().approve(_cycle.id);
      setState(() => _cycle = updated);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = DateFormat('MMMM yyyy').format(DateTime(_cycle.year, _cycle.month));

    return Scaffold(
      appBar: AppBar(title: Text(period)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AmountRow(label: 'Gross', value: _cycle.totalGross),
          const Divider(height: 24),
          _AmountRow(label: 'Deductions', value: -_cycle.totalDeductions),
          const Divider(height: 24),
          _AmountRow(label: 'Net', value: _cycle.totalNet, emphasize: true),
          const SizedBox(height: 12),
          Text(
            '${_cycle.employeeCount} employee(s) · ${_cycle.status}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.accentOrange, fontSize: 13)),
          ],
          if (_cycle.status == 'OPEN') ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _approving ? null : _approve,
              child: _approving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Approve cycle'),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Employees',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<PayrollRunResponse>>(
            future: _previewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                final message = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Could not load the preview.';
                return Text(message, style: const TextStyle(color: AppColors.accentOrange));
              }
              final runs = snapshot.data!;
              if (runs.isEmpty) {
                return const Text('No employees in this cycle.', style: TextStyle(color: AppColors.textMuted));
              }
              return Column(
                children: [
                  for (final run in runs)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        run.employeeFullName,
                        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text([run.employeeNumber, run.departmentName]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(' · ')),
                      trailing: Text(run.netSalary.toStringAsFixed(2)),
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasize ? AppColors.primaryGreen : AppColors.textMuted,
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: emphasize ? 18 : 15,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
