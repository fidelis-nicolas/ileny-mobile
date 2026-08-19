// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'announcement_models.dart';

class AnnouncementRepository {
  AnnouncementRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Authoring (create/publish) is Phase 4 — mobile only reads published
  /// announcements in Phase 1.
  Future<PageResponse<AnnouncementResponse>> listPublished({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/announcements',
        queryParameters: {'status': 'PUBLISHED', 'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, AnnouncementResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AnnouncementResponse> getById(String id) async {
    try {
      final response =
          await _dioClient.dio.get<Map<String, dynamic>>('/announcements/$id');
      return AnnouncementResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dioClient.dio.post<void>('/announcements/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Casts or changes this user's answer to a poll.
  ///
  /// Always a list, even on a single-choice poll. Submitting again *replaces* the
  /// previous answer until the poll closes, so there is no separate "change vote"
  /// call — and the backend records a read receipt at the same time.
  ///
  /// Returns the refreshed poll, so the tally can be shown without a second request.
  /// Composing a poll stays web-only; this is the voting half.
  Future<PollResponse> vote(String announcementId, List<String> optionIds) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/announcements/$announcementId/poll/vote',
        data: {'optionIds': optionIds},
      );
      return PollResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Authoring — Tier B, HR Manager/Org Admin only. `audience` is fixed to
  /// `ORGANIZATION` on mobile; branch/department-scoped audiences stay
  /// web-only (no branch/department picker in this narrow slice).
  Future<AnnouncementResponse> create({
    required String title,
    required String body,
    required String priority,
    String status = 'DRAFT',
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/announcements',
        data: {
          'title': title,
          'body': body,
          'priority': priority,
          'status': status,
          'audience': 'ORGANIZATION',
        },
      );
      return AnnouncementResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AnnouncementResponse> publish(String id) async {
    try {
      final response =
          await _dioClient.dio.patch<Map<String, dynamic>>('/announcements/$id/publish');
      return AnnouncementResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
