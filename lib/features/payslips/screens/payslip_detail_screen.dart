import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payslip_models.dart';
import '../data/payslip_repository.dart';

/// Downloads the PDF into the app's cache dir and hands it to whatever PDF
/// viewer is already installed on the device, rather than bundling an
/// in-app renderer (see pubspec.yaml note on `open_file`).
class PayslipDetailScreen extends StatefulWidget {
  const PayslipDetailScreen({super.key, required this.payslip});

  final PayslipResponse payslip;

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  bool _opening = false;
  String? _error;

  Future<void> _viewPayslip() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final file = await context.read<PayslipRepository>().download(widget.payslip.id);
      final dir = await getTemporaryDirectory();
      final savedFile = File('${dir.path}/${file.filename}');
      await savedFile.writeAsBytes(file.bytes, flush: true);
      final result = await OpenFile.open(savedFile.path);
      if (result.type != ResultType.done && mounted) {
        setState(() => _error = result.message);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payslip = widget.payslip;
    final period = DateFormat('MMMM yyyy').format(DateTime(payslip.year, payslip.month));
    final generatedAt = DateTime.tryParse(payslip.generatedAt)?.toLocal();

    return Scaffold(
      appBar: AppBar(title: Text(period)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AmountRow(label: 'Gross salary', value: payslip.grossSalary),
          const Divider(height: 24),
          _AmountRow(label: 'Deductions', value: -payslip.deductions),
          const Divider(height: 24),
          _AmountRow(label: 'Net pay', value: payslip.netSalary, emphasize: true),
          const SizedBox(height: 20),
          if (generatedAt != null)
            Text(
              'Generated ${DateFormat('MMM d, yyyy').format(generatedAt)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          const SizedBox(height: 32),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.accentOrange, fontSize: 13)),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: _opening ? null : _viewPayslip,
            icon: _opening
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(_opening ? 'Opening…' : 'View payslip'),
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
