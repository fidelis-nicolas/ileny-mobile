import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../data/payslip_models.dart';
import '../data/payslip_repository.dart';
import 'payslip_detail_screen.dart';

class PayslipsScreen extends StatelessWidget {
  const PayslipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<PayslipRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payslips')),
      body: PaginatedListView<PayslipResponse>(
        emptyMessage: 'No payslips yet.',
        fetchPage: (page, size) => repository.me(page: page, size: size),
        itemBuilder: (context, payslip) {
          final period = DateFormat('MMMM yyyy').format(DateTime(payslip.year, payslip.month));
          return ListTile(
            leading: Icon(Icons.receipt_long_outlined, color: context.palette.primary),
            title: Text(
              period,
              style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Net pay: ${payslip.netSalary.toStringAsFixed(2)}'),
            trailing: Icon(Icons.chevron_right, color: context.palette.textMuted),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PayslipDetailScreen(payslip: payslip),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
