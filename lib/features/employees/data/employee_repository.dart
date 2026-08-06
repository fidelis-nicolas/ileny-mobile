// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'employee_models.dart';

class EmployeeRepository {
  EmployeeRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<EmployeeResponse> me() async {
    try {
      final response =
          await _dioClient.dio.get<Map<String, dynamic>>('/employees/me');
      return EmployeeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Self-service photo change (Phase 5) — resolves the employee from the
  /// authenticated user server-side, so it works for every role without
  /// needing the broad `employee:update` authority (see backend
  /// `EmployeeService.uploadMyPhoto`).
  Future<EmployeeResponse> uploadMyPhoto(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dioClient.dio
          .post<Map<String, dynamic>>('/employees/me/photo', data: formData);
      return EmployeeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<EmployeeResponse> getById(String id) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/employees/$id');
      return EmployeeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<EmployeeResponse> updateStatus(String id, String status) async {
    try {
      final response = await _dioClient.dio.patch<Map<String, dynamic>>(
        '/employees/$id/status',
        data: {'status': status},
      );
      return EmployeeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// ORG_ADMIN-only in practice — the backend gates both this and [roles]
  /// on `user:create`, which HR_MANAGER does not hold (see [kOrgAdminRoles]).
  Future<void> invite(String id, List<String> roleIds) async {
    try {
      await _dioClient.dio.post<Map<String, dynamic>>(
        '/employees/$id/invite',
        data: {'roleIds': roleIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RoleResponse>> roles() async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>('/roles');
      return response.data!
          .map((e) => RoleResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `status`/`departmentId`/`branchId` map straight to the backend's
  /// filter params — there is no free-text search param server-side yet.
  Future<PageResponse<EmployeeResponse>> list({
    String? status,
    String? departmentId,
    String? branchId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/employees',
        queryParameters: {
          if (status != null) 'status': status,
          if (departmentId != null) 'departmentId': departmentId,
          if (branchId != null) 'branchId': branchId,
          'page': page,
          'size': size,
        },
      );
      return PageResponse.fromJson(response.data!, EmployeeResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
