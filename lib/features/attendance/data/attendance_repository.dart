// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'attendance_models.dart';

class AttendanceRepository {
  AttendanceRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Self-service clock-in: omits `employeeId` so the backend resolves the
  /// employee from the authenticated user rather than trusting a client-sent
  /// id. `source: GEOFENCE` makes the backend verify `latitude`/`longitude`
  /// against the employee's branch radius (see `AttendanceService
  /// .validateAttendanceSource`); it rejects with a 403/400 message this
  /// client surfaces as-is (e.g. "You are outside the branch geofence").
  Future<AttendanceResponse> clockIn({
    required double latitude,
    required double longitude,
  }) {
    return _clockIn({
      'source': 'GEOFENCE',
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// QR clock-in: the employee scans the code posted at their branch and the
  /// backend checks the scanned token against the branch *it* has on file for
  /// them. No position is sent — `QR_CODE` validation is token-only, so being
  /// physically at the branch is proven by having scanned its code.
  ///
  /// The backend gates this on a paid subscription and on `QR_CODE` being in
  /// the tenant's `allowedAttendanceSources`; both refusals come back as 403s
  /// whose messages the UI shows as-is.
  Future<AttendanceResponse> clockInWithQrCode({required String qrToken}) {
    return _clockIn({'source': 'QR_CODE', 'qrToken': qrToken});
  }

  Future<AttendanceResponse> _clockIn(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/attendance/clock-in',
        data: data,
      );
      return AttendanceResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Clock-out re-runs the same source validation as clock-in, against the
  /// *original* clock-in's source rather than anything the client picks. So a
  /// GEOFENCE clock-in must be closed with `latitude`/`longitude`, and a
  /// QR_CODE one with a freshly scanned [qrToken]; sources that need neither
  /// (MANUAL, BIOMETRIC_DEVICE…) can be closed with both omitted.
  Future<AttendanceResponse> clockOut(
    String employeeId, {
    double? latitude,
    double? longitude,
    String? qrToken,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/attendance/$employeeId/clock-out',
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (qrToken != null) 'qrToken': qrToken,
        },
      );
      return AttendanceResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PageResponse<AttendanceResponse>> history(
    String employeeId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/attendance/employee/$employeeId',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, AttendanceResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AttendanceSummaryResponse> summary(
    String employeeId, {
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/attendance/summary/$employeeId',
        queryParameters: {'month': month, 'year': year},
      );
      return AttendanceSummaryResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Flags a problem with one of the caller's own attendance records. Like
  /// clock-in, it omits any employee id — the backend resolves the employee
  /// from the authenticated user.
  ///
  /// Two things this deliberately cannot do, both backend contract rather than
  /// client limitation: it raises a note against an *existing* record (a date
  /// with no record at all 404s with "No attendance record found for that
  /// date"), and it proposes no times — approval records that the employee's
  /// account of the day was accepted, and a manager still has to overwrite the
  /// record separately for hours and pay to change.
  Future<AttendanceCorrection> submitCorrection({
    required String date,
    required String reason,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/attendance/corrections',
        data: {'date': date, 'reason': reason},
      );
      return AttendanceCorrection.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Org-wide attendance for a single day — the existing endpoint the Home
  /// KPI tile's "today's attendance rate" is sourced from (see plan.txt
  /// Phase 1); not a new report endpoint.
  Future<List<AttendanceResponse>> daily({DateTime? date}) async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>(
        '/attendance/daily',
        queryParameters: date != null ? {'date': _isoDate(date)} : null,
      );
      return response.data!
          .map((e) => AttendanceResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
