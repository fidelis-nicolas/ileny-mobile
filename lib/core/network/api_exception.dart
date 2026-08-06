import 'package:dio/dio.dart';

/// Normalizes the backend's inconsistent error envelopes (ErrorResponse
/// `{status,message,timestamp}`, field-validation maps, and bare
/// `{message}` maps) into a single shape the UI can read.
class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.fieldErrors});

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiException(
        message: error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout
            ? 'The connection timed out. Check your network and try again.'
            : 'Could not reach the server. Check your network and try again.',
      );
    }

    final data = response.data;
    final statusCode = response.statusCode;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) {
        return ApiException(message: message, statusCode: statusCode);
      }

      final fieldErrors = data.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return ApiException(
        message: fieldErrors.values.first,
        statusCode: statusCode,
        fieldErrors: fieldErrors,
      );
    }

    return ApiException(
      message: 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}
