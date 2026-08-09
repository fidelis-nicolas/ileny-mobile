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

  // --------------------------------------------------------------
  // The employee's side.
  //
  // Everything above needs `discipline:create`/`discipline:read`, which an
  // ordinary employee does not hold. These four do not: the backend scopes
  // them to the caller's own employee record, which is why none of them takes
  // an employee id. An employee who cannot read a query raised against them
  // cannot answer it, so this is the half that makes the feature a process
  // rather than a filing cabinet.
  // --------------------------------------------------------------

  /// Cases raised against the signed-in employee. An account with no linked
  /// employee record (an admin-only login) gets an empty page, not an error.
  Future<PageResponse<DisciplinaryCaseResponse>> myCases({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/discipline/cases/me',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, DisciplinaryCaseResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// One of the caller's own cases, with its actions and reply thread. A case
  /// that is not theirs answers 403.
  Future<DisciplinaryCaseResponse> myCase(String caseId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/discipline/cases/me/$caseId',
      );
      return DisciplinaryCaseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The thread on a case, oldest first. Readable by the employee the case is
  /// about *and* by case handlers, so both sides of the app use this one call.
  Future<List<DisciplinaryResponseResponse>> caseResponses(String caseId) async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>(
        '/discipline/cases/$caseId/responses',
      );
      return response.data!
          .map((e) => DisciplinaryResponseResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Adds a message to a case's thread.
  ///
  /// One endpoint for both sides — nothing here says which side the message is
  /// from, because the server decides that from who is calling. Sending it
  /// would defeat the point.
  Future<DisciplinaryResponseResponse> addResponse({
    required String caseId,
    required String message,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/discipline/cases/$caseId/responses',
        data: {'message': message},
      );
      return DisciplinaryResponseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Attaches evidence to a response. Only its author may attach to it, so
  /// this answers 403 on someone else's message.
  Future<DisciplinaryResponseResponse> uploadResponseDocument(
    String responseId,
    String filePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/discipline/responses/$responseId/document',
        data: formData,
      );
      return DisciplinaryResponseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
