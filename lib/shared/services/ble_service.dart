import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';

class BleService {
  static const int _txPower = -59;
  static const double _pathLoss = 2.5;

  static Future<({bool granted, String? error})> requestPermissions() async {
    debugPrint('>>> BLE requestPermissions called');
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    final anyDenied = statuses.values.any((s) =>
    s == PermissionStatus.denied ||
        s == PermissionStatus.permanentlyDenied);

    if (anyDenied) {
      return (
      granted: false,
      error:
      'Bluetooth permissions denied. Go to App Settings → Permissions → Bluetooth and enable all.'
      );
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      return (
      granted: false,
      error: 'Bluetooth is off. Please turn on Bluetooth and try again.'
      );
    }

    return (granted: true, error: null);
  }

  static Future<({String? id, String? error})> getBluetoothAddress() async {
    // Teacher side doesn't need actual BLE scanning
    // Just generate a unique session token
    final id = 'SESSION_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('>>> Session ID: $id');
    return (id: id, error: null);
  }

  /// Student: scan for any BLE devices and check if signal is strong enough
  /// Strong signal = physically close to teacher
  /// rssiThreshold: -75 dBm ≈ 15-20m, -65 dBm ≈ 5-8m
  static Future<({bool inRange, double? meters, String? error})>
  checkProximityToTeacher({
    required String teacherBluetoothId, // kept for API compatibility, not used
    int rssiThreshold = -75,
  }) async {
    final perm = await requestPermissions();
    if (!perm.granted) {
      return (inRange: false, meters: null, error: perm.error);
    }

    try {
      // Scan for 5 seconds and collect all visible devices
      final List<int> rssiValues = [];

      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.rssi != 0) rssiValues.add(r.rssi);
        }
      });


      await Future.delayed(const Duration(seconds: 6));
      await sub.cancel();
      await FlutterBluePlus.stopScan();

      if (rssiValues.isEmpty) {
        return (
        inRange: false,
        meters: null,
        error: 'No Bluetooth devices detected nearby. Make sure teacher has Bluetooth on.',
        );
      }

      // Take the strongest signal found
      rssiValues.sort((a, b) => b.compareTo(a));
      final bestRssi = rssiValues.first;
      final dist = _rssiToMeters(bestRssi);
      appLogger.i('Best RSSI: $bestRssi dBm (~${dist.toStringAsFixed(1)}m), threshold: $rssiThreshold dBm');

      return (
      inRange: bestRssi >= rssiThreshold,
      meters: dist,
      error: null,
      );
    } catch (e) {
      appLogger.e('BLE scan error: $e');
      return (inRange: false, meters: null, error: 'Bluetooth scan error: $e');
    }
  }

  static double _rssiToMeters(int rssi) {
    if (rssi == 0) return 99.0;
    final ratio = (_txPower - rssi) / (10.0 * _pathLoss);
    return math.pow(10, ratio).toDouble();
  }
}