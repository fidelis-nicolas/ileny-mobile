import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/roles.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../auth/state/auth_state.dart';
import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';
import 'qr_scan_screen.dart';
import 'request_correction_screen.dart';
import 'team_attendance_screen.dart';

/// Clock in/out + this month's summary + paginated history for the signed-in
/// employee. `EMPLOYEE`-role accounts currently only hold `attendance:create`
/// on the backend (see RoleSeeder), not `attendance:read`, so summary/history
/// calls 403 for them today — that's surfaced as an inline message rather
/// than a crash, and is flagged separately as a backend permission gap to
/// close before this screen is fully usable for plain employees.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceResponse? _today;
  AttendanceSummaryResponse? _summary;
  bool _loadingToday = true;
  bool _clocking = false;
  String? _todayError;
  bool _readDenied = false;
  final _historyKey = GlobalKey<PaginatedListViewState<AttendanceResponse>>();
  final _locationService = LocationService();

  String get _employeeId => context.read<AuthState>().currentUser!.employeeId!;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() {
      _loadingToday = true;
      _todayError = null;
    });
    final repository = context.read<AttendanceRepository>();
    final now = DateTime.now();
    try {
      final history = await repository.history(_employeeId, page: 0, size: 1);
      final summary =
          await repository.summary(_employeeId, month: now.month, year: now.year);
      final todayIso = DateFormat('yyyy-MM-dd').format(now);
      AttendanceResponse? today;
      for (final record in history.content) {
        if (record.attendanceDate == todayIso) {
          today = record;
          break;
        }
      }
      setState(() {
        _today = today;
        _summary = summary;
        _readDenied = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _readDenied = e.statusCode == 403;
        _todayError = e.message;
      });
    } finally {
      if (mounted) setState(() => _loadingToday = false);
    }
  }

  Future<void> _clockIn() async {
    setState(() => _clocking = true);
    final repository = context.read<AttendanceRepository>();
    try {
      final position = await _locationService.getCurrentPosition();
      final record = await repository.clockIn(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() => _today = record);
      _historyKey.currentState?.refresh();
    } on LocationException catch (e) {
      if (mounted) _showError(e.message);
    } on ApiException catch (e) {
      if (mounted) _showError(_explainGeofenceError(e));
    } finally {
      if (mounted) setState(() => _clocking = false);
    }
  }

  /// QR clock-in, the alternative to the geofence button for branches that
  /// post a code instead of (or as well as) relying on GPS.
  Future<void> _clockInWithQrCode() async {
    final qrToken = await _scanQrToken();
    if (qrToken == null || !mounted) return;

    setState(() => _clocking = true);
    final repository = context.read<AttendanceRepository>();
    try {
      final record = await repository.clockInWithQrCode(qrToken: qrToken);
      setState(() => _today = record);
      _historyKey.currentState?.refresh();
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _clocking = false);
    }
  }

  /// The backend re-validates clock-out against the source the day was opened
  /// with, so what this has to collect depends on [_today]: a fresh QR scan
  /// for a QR_CODE day, a GPS fix for a GEOFENCE one, and nothing at all for
  /// a day opened manually or by a biometric device.
  Future<void> _clockOut() async {
    final source = _today?.source;

    String? qrToken;
    if (source == 'QR_CODE') {
      qrToken = await _scanQrToken();
      if (qrToken == null || !mounted) return;
    }

    setState(() => _clocking = true);
    final repository = context.read<AttendanceRepository>();
    final employeeId = _employeeId;
    try {
      double? latitude;
      double? longitude;
      if (source == 'GEOFENCE') {
        final position = await _locationService.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }
      final record = await repository.clockOut(
        employeeId,
        latitude: latitude,
        longitude: longitude,
        qrToken: qrToken,
      );
      setState(() => _today = record);
      _historyKey.currentState?.refresh();
    } on LocationException catch (e) {
      if (mounted) _showError(e.message);
    } on ApiException catch (e) {
      if (mounted) _showError(_explainGeofenceError(e));
    } finally {
      if (mounted) setState(() => _clocking = false);
    }
  }

  /// [date] comes from the tapped history row when there is one; opened from
  /// the app bar the user picks the day themselves.
  Future<void> _requestCorrection({DateTime? date}) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RequestCorrectionScreen(initialDate: date),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correction request submitted for review.'),
        ),
      );
    }
  }

  Future<String?> _scanQrToken() {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
  }

  /// The backend's geofence message already states the distance
  /// (`"You are outside the branch geofence (Xm away, allowed Ym)"`); add an
  /// explicit call to action so the user knows what to do about it.
  String _explainGeofenceError(ApiException e) {
    if (e.statusCode == 403 && e.message.toLowerCase().contains('geofence')) {
      return '${e.message}. Move within range of your branch and try again.';
    }
    return e.message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AttendanceRepository>();
    final isManager = context.watch<AuthState>().hasAnyPermission(kTeamAttendancePermissions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: 'Request a correction',
            onPressed: () => _requestCorrection(),
          ),
          if (isManager)
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Team attendance',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TeamAttendanceScreen()),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadToday();
          _historyKey.currentState?.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TodayCard(
              loading: _loadingToday,
              today: _today,
              error: _readDenied ? null : _todayError,
              clocking: _clocking,
              onClockIn: _clockIn,
              onClockInWithQrCode: _clockInWithQrCode,
              onClockOut: _clockOut,
            ),
            if (_readDenied) ...[
              const SizedBox(height: 12),
              Text(
                "Your account doesn't have permission to view attendance "
                'history yet — you can still clock in/out above.',
                style: TextStyle(color: context.palette.textMuted, fontSize: 12),
              ),
            ],
            if (_summary != null) ...[
              const SizedBox(height: 20),
              _SummaryCard(summary: _summary!),
            ],
            const SizedBox(height: 24),
            Text(
              'History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.palette.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a day to request a correction.',
              style: TextStyle(color: context.palette.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: _readDenied
                  ? Center(
                      child: Text(
                        'History is unavailable for your role right now.',
                        style: TextStyle(color: context.palette.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : PaginatedListView<AttendanceResponse>(
                      key: _historyKey,
                      emptyMessage: 'No attendance records yet.',
                      fetchPage: (page, size) =>
                          repository.history(_employeeId, page: page, size: size),
                      itemBuilder: (context, record) => _HistoryTile(
                        record: record,
                        onRequestCorrection: () => _requestCorrection(
                          date: DateTime.tryParse(record.attendanceDate),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.loading,
    required this.today,
    required this.error,
    required this.clocking,
    required this.onClockIn,
    required this.onClockInWithQrCode,
    required this.onClockOut,
  });

  final bool loading;
  final AttendanceResponse? today;
  final String? error;
  final bool clocking;
  final VoidCallback onClockIn;
  final VoidCallback onClockInWithQrCode;
  final VoidCallback onClockOut;

  @override
  Widget build(BuildContext context) {
    final clockedIn = today != null && today!.clockOut == null;
    final completed = today != null && today!.clockOut != null;
    final clockedInByQr = clockedIn && today!.source == 'QR_CODE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today",
            style: TextStyle(color: context.palette.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            completed
                ? 'Clocked out'
                : clockedIn
                    ? 'Clocked in at ${_time(today!.clockIn)}'
                    : loading
                        ? 'Checking status…'
                        : 'Not clocked in yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.palette.primary,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(color: context.palette.danger, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: clocking || completed
                  ? null
                  : clockedIn
                      ? onClockOut
                      : onClockIn,
              child: clocking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      completed
                          ? 'Done for today'
                          : clockedIn
                              ? clockedInByQr
                                  ? 'Scan QR to clock out'
                                  : 'Clock out'
                              : 'Clock in',
                    ),
            ),
          ),
          // Offered only as a way to *open* the day — once clocked in, the
          // backend pins clock-out to the source the day was opened with, so
          // a second choice here would just produce a guaranteed rejection.
          if (!clockedIn && !completed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: clocking ? null : onClockInWithQrCode,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Clock in with QR code'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _time(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '';
    return DateFormat('h:mm a').format(parsed);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final AttendanceSummaryResponse summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Present', value: '${summary.daysPresent}')),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'Late', value: '${summary.daysLate}')),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'Absent', value: '${summary.daysAbsent}')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.palette.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.onRequestCorrection});

  final AttendanceResponse record;
  final VoidCallback onRequestCorrection;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onRequestCorrection,
      title: Text(
        record.attendanceDate,
        style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        record.workHours != null
            ? '${record.workHours!.toStringAsFixed(1)}h worked'
            : 'In progress',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(record.status, style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 18, color: context.palette.textMuted),
        ],
      ),
    );
  }
}
