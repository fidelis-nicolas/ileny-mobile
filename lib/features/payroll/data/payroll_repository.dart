// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'payroll_models.dart';

/// Narrow mobile slice: browse cycles, preview, single approve action — no
/// cycle creation/regeneration/lock, no component config (plan.txt Tier B).
class PayrollRepository {
  PayrollRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// `GET /payroll/cycles` returns a plain list (cycle history), not a
  /// Spring `Page` like most other list endpoints here.
  Future<List<PayrollCycleResponse>> cycles() async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>('/payroll/cycles');
      return response.data!
          .map((e) => PayrollCycleResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<PayrollRunResponse>> preview(String cycleId) async {
    try {
      final response =
          await _dioClient.dio.get<List<dynamic>>('/payroll/cycles/$cycleId/preview');
      return response.data!
          .map((e) => PayrollRunResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PayrollCycleResponse> approve(String cycleId) async {
    try {
      final response =
          await _dioClient.dio.patch<Map<String, dynamic>>('/payroll/cycles/$cycleId/approve');
      return PayrollCycleResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
