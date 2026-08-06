import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// The refresh token only exists as an httpOnly cookie scoped to
/// `/api/v1/auth` (see plan.txt section 4) — dio does not persist cookies
/// on its own, so this jar is what makes the refresh flow survive an app
/// restart.
Future<PersistCookieJar> createPersistedCookieJar() async {
  final directory = await getApplicationSupportDirectory();
  return PersistCookieJar(storage: FileStorage('${directory.path}/.cookies'));
}
