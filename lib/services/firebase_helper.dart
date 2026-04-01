import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

/// Check if the device has internet
Future<bool> hasInternet() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

/// Retry wrapper with exponential backoff
Future<T> retry<T>(Future<T> Function() action, {int maxRetries = 5}) async {
  int attempt = 0;
  while (true) {
    try {
      return await action();
    } catch (e) {
      attempt++;
      if (attempt > maxRetries) rethrow;
      int delay = 500 * (1 << attempt); // exponential backoff: 500ms, 1s, 2s, 4s...
      await Future.delayed(Duration(milliseconds: delay));
    }
  }
}

Future<Position?> safeGetLocation(BuildContext context) async {
  try {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enable location services")),
      );
      return null;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission permanently denied")),
      );
      return null;
    }

    // Get location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    return position;
  } catch (e) {
    debugPrint("Location error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location error: $e")),
    );
    return null;
  }
}