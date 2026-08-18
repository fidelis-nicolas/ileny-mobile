import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payroll_models.dart';
import '../data/payroll_repository.dart';
import 'payroll_cycle_detail_screen.dart';

class PayrollCyclesScreen extends StatefulWidget {
  const PayrollCyclesScreen({super.key});

  @override
  State<PayrollCyclesScreen> createState() => _PayrollCyclesScreenState();
}

class _PayrollCyclesScreenState extends State<PayrollCyclesScreen> {
  Future<List<PayrollCycleResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = context.read<PayrollRepository>().cycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll cycles')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<PayrollCycleResponse>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load payroll cycles.';
              return _scrollableMessage(message);
            }
            final cycles = snapshot.data!;
            if (cycles.isEmpty) return _scrollableMessage('No payroll cycles yet.');
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                final period = DateFormat('MMMM yyyy').format(DateTime(cycle.year, cycle.month));
                return ListTile(
                  leading: Icon(Icons.payments_outlined, color: context.palette.primary),
                  title: Text(
                    period,
                    style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${cycle.employeeCount} employee(s) · net ${cycle.totalNet.toStringAsFixed(2)}',
                  ),
                  trailing: Text(cycle.status, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PayrollCycleDetailScreen(cycle: cycle)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _scrollableMessage(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Text(message, style: TextStyle(color: context.palette.textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
