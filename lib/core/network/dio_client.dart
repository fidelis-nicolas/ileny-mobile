import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

/// Two Dio instances share one cookie jar, so the refresh cookie set by
/// login/refresh is visible to both:
///  - [authDio]: the unauthenticated auth endpoints (login, 2fa/verify,
///    refresh, forgot/reset-password). Deliberately has no auth
///    interceptor — the refresh call itself must not recurse into the
///    refresh-and-retry logic.
///  - [dio]: every other API call. Attaches the bearer token and retries
///    once through [authDio]'s refresh endpoint on a 401.
class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    required CookieJar cookieJar,
    required void Function() onSessionExpired,
  })  : authDio = Dio(_baseOptions())..interceptors.add(CookieManager(cookieJar)),
        dio = Dio(_baseOptions())..interceptors.add(CookieManager(cookieJar)) {
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        refresh: () => _refreshAccessToken(tokenStorage),
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  final Dio authDio;
  final Dio dio;

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    );
  }

  Future<String> _refreshAccessToken(TokenStorage tokenStorage) async {
    final response = await authDio.post<Map<String, dynamic>>('/auth/refresh');
    final accessToken = response.data!['accessToken'] as String;
    await tokenStorage.save(accessToken);
    return accessToken;
  }
}
