// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'whistleblow_models.dart';

/// The whistleblowing channel.
///
/// Only the reporter's half is here. Filing a concern and following it are things somebody does
/// on their phone, quite possibly not at their desk and not on a work computer — which is exactly
/// the point. Reading the queue and investigating a report is a sit-down job and stays on the web
/// client, the same split performance management already makes.
///
/// **Anonymity, and what it does and does not promise.** An anonymous report stores no reporter:
/// there is no field a handler can read and no query that finds a report from a user. Filing is
/// still authenticated, because a report has to belong to an organisation — so the identity is
/// known to the server for the length of the request and deliberately never written down. That
/// protects the reporter from everyone inside their organisation, which is what this is for, and
/// not from whoever operates the database. The UI says as much rather than overselling it.
class WhistleblowRepository {
  WhistleblowRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Files a report.
  ///
  /// [anonymous] is always sent explicitly rather than left to the server's default: a report
  /// filed anonymously by mistake costs the reporter nothing, and one attributed by mistake
  /// cannot be taken back, so the choice should never be implicit.
  Future<WhistleblowSubmitResult> submit({
    required bool anonymous,
    required String category,
    required String subject,
    required String body,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/whistleblow/reports',
        data: {
          'anonymous': anonymous,
          'category': category,
          'subject': subject,
          'body': body,
        },
      );
      return WhistleblowSubmitResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Reads a report back with its case code and passphrase.
  ///
  /// An unknown code and a wrong passphrase come back identically as a 404, on purpose: telling
  /// them apart would confirm to a guesser that a code exists.
  Future<TrackedWhistleblowReport> track({
    required String caseCode,
    required String passphrase,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/whistleblow/reports/track',
        data: {'caseCode': caseCode, 'passphrase': passphrase},
      );
      return TrackedWhistleblowReport.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Adds the reporter's reply, authenticated by case code and passphrase like the read above.
  ///
  /// Returns the whole thread rather than the one message, which is what the server sends and
  /// what the screen needs — there is no separate refresh to make afterwards.
  Future<TrackedWhistleblowReport> addMessage({
    required String caseCode,
    required String passphrase,
    required String body,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/whistleblow/reports/track/messages',
        data: {'caseCode': caseCode, 'passphrase': passphrase, 'body': body},
      );
      return TrackedWhistleblowReport.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
