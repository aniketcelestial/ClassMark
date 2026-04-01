import 'package:connectivity_plus/connectivity_plus.dart';

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