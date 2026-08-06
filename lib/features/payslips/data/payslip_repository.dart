// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'payslip_models.dart';

class PayslipRepository {
  PayslipRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<PageResponse<PayslipResponse>> me({int page = 0, int size = 20}) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/payslips/me',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, PayslipResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PayslipResponse> getById(String id) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/payslips/$id');
      return PayslipResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Streams the payslip PDF through the authenticated `/payslips/{id}/download`
  /// endpoint — payslips are not served through the generic `/files/**` gate.
  Future<PayslipFile> download(String id) async {
    try {
      final response = await _dioClient.dio.get<List<int>>(
        '/payslips/$id/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return PayslipFile(
        bytes: response.data!,
        filename: _filenameFrom(response.headers.value('content-disposition')),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _filenameFrom(String? contentDisposition) {
    const fallback = 'payslip.pdf';
    if (contentDisposition == null) return fallback;
    final match = RegExp('filename="?([^";]+)"?').firstMatch(contentDisposition);
    return match?.group(1) ?? fallback;
  }
}
