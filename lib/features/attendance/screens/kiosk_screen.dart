import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_exception.dart';
import '../data/attendance_repository.dart';
import 'qr_scan_screen.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  bool busy = false;
  String? message;

  Future<void> scan(String action) async {
    final token = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => const QrScanScreen(title: 'Scan employee card', employeeCard: true),
    ));
    if (token == null || !mounted) return;
    setState(() { busy = true; message = null; });
    try {
      final result = await context.read<AttendanceRepository>().kioskPunch(token, action);
      if (mounted) setState(() => message = '${result.employeeFullName}: clocked ${action == 'IN' ? 'in' : 'out'}.');
    } on ApiException catch (e) {
      if (mounted) setState(() => message = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Attendance kiosk')),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Text('Choose an action, then scan the employee card.'),
        const SizedBox(height: 12),
        const Text('Keep this device supervised. Leaving this screen returns to the signed-in account.', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: busy ? null : () => scan('IN'), icon: const Icon(Icons.login), label: const Text('Clock in')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: busy ? null : () => scan('OUT'), icon: const Icon(Icons.logout), label: const Text('Clock out')),
        if (message != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(message!, textAlign: TextAlign.center)),
      ],
    ))),
  );
}
