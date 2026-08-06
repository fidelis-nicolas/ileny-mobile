// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'leave_models.dart';

class LeaveRepository {
  LeaveRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<List<LeaveTypeResponse>> types() async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>('/leave/types');
      return response.data!
          .map((e) => LeaveTypeResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<LeaveBalanceResponse>> balance(
    String employeeId, {
    required int year,
  }) async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>(
        '/leave/balance/$employeeId',
        queryParameters: {'year': year},
      );
      return response.data!
          .map((e) => LeaveBalanceResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Employee is resolved server-side from the authenticated user, not sent
  /// in the body.
  Future<LeaveRequestResponse> createRequest({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/leave/requests',
        data: {
          'leaveTypeId': leaveTypeId,
          'startDate': startDate,
          'endDate': endDate,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return LeaveRequestResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `employeeId` must be passed explicitly to scope to "my requests" — the
  /// backend does not infer it, unlike attendance history's path variable.
  /// Omitting it (as the Tier A approvals queue does) returns every request
  /// tenant-wide — there's no manager/team filter on this endpoint.
  Future<PageResponse<LeaveRequestResponse>> requests({
    String? employeeId,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/leave/requests',
        queryParameters: {
          if (employeeId != null) 'employeeId': employeeId,
          if (status != null) 'status': status,
          'page': page,
          'size': size,
        },
      );
      return PageResponse.fromJson(response.data!, LeaveRequestResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Tier A: any account with `leave:approve` (HR_MANAGER/ORG_ADMIN) may
  /// approve/reject any pending request tenant-wide — the backend does not
  /// restrict this to "the requester's manager" since no such relationship
  /// is modeled.
  Future<LeaveRequestResponse> approve(String id) async {
    try {
      final response =
          await _dioClient.dio.patch<Map<String, dynamic>>('/leave/requests/$id/approve');
      return LeaveRequestResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LeaveRequestResponse> reject(String id, String reason) async {
    try {
      final response = await _dioClient.dio.patch<Map<String, dynamic>>(
        '/leave/requests/$id/reject',
        data: {'reason': reason},
      );
      return LeaveRequestResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
