import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';

/// Tier A: tenant-wide attendance for a chosen day — there's no team/manager
/// scoping on the backend (`/attendance/daily` returns every employee), so
/// this is the same data source as the Home KPI tile, just per-day and
/// itemized rather than a single rate.
class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  DateTime _date = DateTime.now();
  Future<List<AttendanceResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = context.read<AttendanceRepository>().daily(date: _date);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Choose date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<AttendanceResponse>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load attendance.';
              return _scrollableMessage(message);
            }
            final records = snapshot.data!;
            if (records.isEmpty) {
              return _scrollableMessage('No attendance records for this day.');
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.palette.primary,
                  ),
                ),
                const SizedBox(height: 16),
                for (final record in records) _TeamAttendanceTile(record: record),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scrollableMessage(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Text(message, style: TextStyle(color: context.palette.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamAttendanceTile extends StatelessWidget {
  const _TeamAttendanceTile({required this.record});

  final AttendanceResponse record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        record.employeeFullName,
        style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        record.workHours != null
            ? '${record.workHours!.toStringAsFixed(1)}h worked'
            : 'In progress',
      ),
      trailing: Text(record.status, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
    );
  }
}
