// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({required DioClient dioClient, required TokenStorage tokenStorage})
      : _dioClient = dioClient,
        _tokenStorage = tokenStorage;

  final DioClient _dioClient;
  final TokenStorage _tokenStorage;

  /// [tenantId] is null on a first attempt and set only when re-submitting
  /// after the server answered with tenant choices — the address had valid
  /// accounts in more than one organisation. It narrows the lookup; the
  /// password is still checked again against the chosen account.
  Future<LoginResponse> login({
    required String email,
    required String password,
    String? tenantId,
  }) async {
    try {
      final response = await _dioClient.authDio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          if (tenantId != null) 'tenantId': tenantId,
        },
      );
      final login = LoginResponse.fromJson(response.data!);
      if (login.tokens != null) {
        await _tokenStorage.save(login.tokens!.accessToken);
      }
      return login;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TokenResponse> verifyTwoFactor({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dioClient.authDio.post<Map<String, dynamic>>(
        '/auth/2fa/verify',
        data: {'email': email, 'code': code},
      );
      final tokens = TokenResponse.fromJson(response.data!);
      await _tokenStorage.save(tokens.accessToken);
      return tokens;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MeResponse> me() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/auth/me');
      return MeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Cold-start bootstrap: the access token only lives for the running
  /// session (see TokenStorage), so on launch we trade the persisted
  /// refresh cookie for a fresh one before trusting any cached session.
  /// Returns null (rather than throwing) when there's no valid session —
  /// that's the expected "not logged in yet" case, not an error.
  Future<MeResponse?> restoreSession() async {
    try {
      final response = await _dioClient.authDio.post<Map<String, dynamic>>('/auth/refresh');
      final tokens = TokenResponse.fromJson(response.data!);
      await _tokenStorage.save(tokens.accessToken);
      return await me();
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.dio.post<void>('/auth/logout');
    } on DioException {
      // Best-effort — an offline/failed logout call shouldn't strand the
      // user signed in locally, so local state is still cleared below.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.authDio.post<void>(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dioClient.authDio.post<void>(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dioClient.dio.post<void>(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
