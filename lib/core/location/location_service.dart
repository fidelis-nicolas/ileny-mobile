import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Thrown for any GPS failure the UI needs to explain to the user (services
/// off, permission denied, or a timeout getting a fix) — distinct from
/// [ApiException] so callers can tell "couldn't get a position" apart from
/// "server rejected the position".
class LocationException implements Exception {
  LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps `geolocator` with the permission/service checks geofenced
/// clock-in/out needs. No backend or app state, so it isn't Provider-wired —
/// each call site constructs one directly.
class LocationService {
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(
        'Location services are turned off. Turn on GPS to clock in.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permission is required to clock in.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it in system '
        'settings to clock in.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw LocationException('Could not get your location. Try again.');
    }
  }
}
