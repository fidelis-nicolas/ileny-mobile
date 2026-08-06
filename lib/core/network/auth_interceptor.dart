// Named constructor params can't reuse a private (`_`-prefixed) field name
// as an initializing formal across library boundaries, so these are
// assigned in the initializer list instead.
// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

typedef RefreshTokenCallback = Future<String> Function();

/// Injects the bearer token on every request and, on a 401, runs the
/// refresh-and-retry dance exactly once per failure — concurrent 401s
/// share a single in-flight refresh instead of each firing their own.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required RefreshTokenCallback refresh,
    required void Function() onSessionExpired,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _refresh = refresh,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final RefreshTokenCallback _refresh;
  final void Function() _onSessionExpired;

  Future<String>? _refreshInFlight;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await (_refreshInFlight ??= _refresh());
      _refreshInFlight = null;

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra['retried'] = true;
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      _refreshInFlight = null;
      await _tokenStorage.clear();
      _onSessionExpired();
      handler.next(err);
    }
  }
}
