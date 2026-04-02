import 'package:geolocator/geolocator.dart';
import '../../core/utils/logger.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appLogger.w('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        appLogger.w('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      appLogger.w('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      appLogger.e('Get position error: $e');
      return null;
    }
  }

  /// Returns distance in meters between two coordinates
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if student is within [radiusMeters] of teacher
  static bool isWithinRange({
    required double teacherLat,
    required double teacherLon,
    required double studentLat,
    required double studentLon,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: teacherLat,
      lon1: teacherLon,
      lat2: studentLat,
      lon2: studentLon,
    );
    appLogger.i('Distance from teacher: ${distance.toStringAsFixed(2)}m');
    return distance <= radiusMeters;
  }
}