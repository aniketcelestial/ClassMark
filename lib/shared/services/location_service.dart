import 'package:geolocator/geolocator.dart';
import '../../core/utils/logger.dart';

class LocationService {
  /// Returns position or a clear error string explaining what went wrong
  static Future<({Position? position, String? error})>
      getPositionWithReason() async {
    // 1. Check if GPS service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (
        position: null,
        error:
            'GPS is turned off. Please enable Location Services in device Settings and try again.'
      );
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return (
        position: null,
        error:
            'Location permission denied. Please allow location access when prompted.'
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return (
        position: null,
        error:
            'Location permanently denied. Go to App Settings → Permissions → Location and enable it.'
      );
    }

    // 3. Try to get current position
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
          forceLocationManager: false,
        ),
      );
      appLogger.i(
          'Location: ${pos.latitude}, ${pos.longitude} (±${pos.accuracy.toStringAsFixed(0)}m)');
      return (position: pos, error: null);
    } catch (e) {
      appLogger.w('High accuracy GPS failed: $e');
    }

    // 4. Fallback: last known position
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        appLogger
            .i('Using last known: ${last.latitude}, ${last.longitude}');
        return (position: last, error: null);
      }
    } catch (e) {
      appLogger.w('Last known position error: $e');
    }

    return (
      position: null,
      error:
          'Unable to get location. Ensure GPS is on and you are outdoors or near a window.'
    );
  }

  static Future<Position?> getCurrentPosition() async {
    final r = await getPositionWithReason();
    return r.position;
  }

  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

  static bool isWithinRange({
    required double teacherLat,
    required double teacherLon,
    required double studentLat,
    required double studentLon,
    required double radiusMeters,
  }) {
    final d = calculateDistance(
        lat1: teacherLat,
        lon1: teacherLon,
        lat2: studentLat,
        lon2: studentLon);
    appLogger.i('Distance from teacher: ${d.toStringAsFixed(1)}m');
    return d <= radiusMeters;
  }
}
