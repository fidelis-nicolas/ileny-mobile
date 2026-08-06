// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'notification_models.dart';

class NotificationRepository {
  NotificationRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<PageResponse<NotificationResponse>> list({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, NotificationResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The backend returns this as a bare JSON number, not `{ "count": n }`.
  Future<int> unreadCount() async {
    try {
      final response = await _dioClient.dio.get<Object?>('/notifications/unread-count');
      return (response.data as num).toInt();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dioClient.dio.patch<void>('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `platform` is `'ANDROID'`/`'IOS'`/`'WEB'` — matches the backend's
  /// `DevicePlatform` enum (see `PushNotificationService`, Phase 5).
  Future<void> registerDeviceToken({required String token, required String platform}) async {
    try {
      await _dioClient.dio.post<void>(
        '/notifications/device-token',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _dioClient.dio.delete<void>('/notifications/device-token/$token');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
