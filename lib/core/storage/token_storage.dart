import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the access token in memory for the running session (fast,
/// synchronous reads for the dio interceptor) and mirrors it to secure
/// storage so a cold start has something to try before the refresh-cookie
/// round trip completes. Secure storage is never treated as the source of
/// truth — a stored token can be stale/expired and the refresh flow is
/// always the real bootstrap path.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _secureStorage;
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<String?> restore() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    return _accessToken;
  }

  Future<void> save(String accessToken) async {
    _accessToken = accessToken;
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _secureStorage.delete(key: _accessTokenKey);
  }
}
