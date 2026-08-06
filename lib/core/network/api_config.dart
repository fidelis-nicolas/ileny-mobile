class ApiConfig {
  ApiConfig._();

  /// The deployed backend. This is the default so that a plain
  /// `flutter run` / `flutter build` can never accidentally ship a build
  /// pointed at a developer's machine.
  static const String _defaultBaseUrl = 'https://api.ileny.app/api/v1';

  /// Compile-time override for local development, e.g.
  ///
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api/v1
  ///
  /// 10.0.2.2 is the Android emulator's alias for the host machine's
  /// localhost; a physical device on the same network needs the host's LAN
  /// IP instead. Cleartext http is only permitted in debug builds (see
  /// android/app/src/debug/AndroidManifest.xml), so a release build must
  /// use an https URL.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _override.isEmpty ? _defaultBaseUrl : _override;
}
