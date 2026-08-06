// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'discipline_models.dart';

class DisciplineRepository {
  DisciplineRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Own team's cases only (mobile scope — not the full org list, that's
  /// web) achieved by always passing a specific [employeeId].
  Future<PageResponse<DisciplinaryCaseResponse>> casesForEmployee(
    String employeeId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/discipline/employees/$employeeId/cases',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, DisciplinaryCaseResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DisciplinaryCaseResponse> createCase({
    required String employeeId,
    required String category,
    required String description,
    required String incidentDate,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/discipline/cases',
        data: {
          'employeeId': employeeId,
          'category': category,
          'description': description,
          'incidentDate': incidentDate,
        },
      );
      return DisciplinaryCaseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `payrollCycleId` is only required when [actionType] is
  /// `SALARY_DEDUCTION` — mobile doesn't offer that action type (no cycle
  /// picker in this narrow slice), so it's always omitted here.
  Future<DisciplinaryActionResponse> createAction({
    required String caseId,
    required String actionType,
    required String actionDate,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/discipline/cases/$caseId/actions',
        data: {
          'actionType': actionType,
          'actionDate': actionDate,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return DisciplinaryActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DisciplinaryActionResponse> uploadDocument(String actionId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/discipline/actions/$actionId/document',
        data: formData,
      );
      return DisciplinaryActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
