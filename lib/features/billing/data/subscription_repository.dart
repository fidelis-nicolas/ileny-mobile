// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'subscription_models.dart';

/// The organisation's subscription, read-only.
///
/// **No plan changes here, deliberately.** Paying for a plan goes through
/// Paystack Inline, a browser widget with no Flutter equivalent in this app,
/// and half-implementing card capture on mobile would mean either shipping a
/// second payment integration or collecting card details ourselves. Neither is
/// worth it for a screen an admin visits a few times a year. The mobile job is
/// to *answer the question* — what are we on, when does it renew, did the last
/// charge work — and hand off to the web for the change itself.
///
/// Auto-renew is not toggled here for the same reason: switching it off is the
/// closest thing to cancelling, and it belongs next to the payment screen that
/// explains what happens when the period ends.
class SubscriptionRepository {
  SubscriptionRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Requires `settings:read` — held by ORG_ADMIN and HR_MANAGER.
  Future<SubscriptionResponse> current() async {
    try {
      final response =
          await _dioClient.dio.get<Map<String, dynamic>>('/tenant/subscription');
      return SubscriptionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<SubscriptionPaymentResponse>> payments() async {
    try {
      final response = await _dioClient.dio
          .get<List<dynamic>>('/tenant/subscription/payments');
      return response.data!
          .map((e) => SubscriptionPaymentResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
