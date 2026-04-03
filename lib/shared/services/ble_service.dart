import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';

class BleService {
  static const int _txPower = -59;
  static const double _pathLoss = 2.5;

  static Future<({bool granted, String? error})> requestPermissions() async {
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

  /// Student scans for teacher's device by Bluetooth address and checks RSSI.
  /// [teacherBluetoothId] is stored in Firestore when teacher generates OTP.
  /// [rssiThreshold] default -75 dBm ≈ 15–20m indoors.
  static Future<({bool inRange, double? meters, String? error})>
  checkProximityToTeacher({
    required String teacherBluetoothId,
    int rssiThreshold = -75,
  }) async {
    final perm = await requestPermissions();
    if (!perm.granted) {
      return (inRange: false, meters: null, error: perm.error);
    }

    final completer =
    Completer<({bool inRange, double? meters, String? error})>();
    StreamSubscription? sub;

    sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.remoteId.str == teacherBluetoothId) {
          final rssi = r.rssi;
          final dist = _rssiToMeters(rssi);
          appLogger.i(
              'Teacher BLE found. RSSI=$rssi dBm, ~${dist.toStringAsFixed(1)}m');
          if (!completer.isCompleted) {
            completer.complete((
            inRange: rssi >= rssiThreshold,
            meters: dist,
            error: null,
            ));
          }
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    await Future.delayed(const Duration(seconds: 9));
    await sub.cancel();
    await FlutterBluePlus.stopScan();

    if (!completer.isCompleted) {
      completer.complete((
      inRange: false,
      meters: null,
      error:
      "Teacher's Bluetooth device not found nearby. Make sure you are close to the teacher and their Bluetooth is on.",
      ));
    }

    return completer.future;
  }

  /// Returns this device's Bluetooth MAC address.
  /// Called by teacher when generating OTP — stored in Firestore session.
  static Future<({String? id, String? error})> getBluetoothAddress() async {
    final perm = await requestPermissions();
    if (!perm.granted) return (id: null, error: perm.error);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 1));
      await FlutterBluePlus.stopScan();

      final name = await FlutterBluePlus.adapterName;
      if (name.isEmpty) {
        return (id: null, error: 'Could not read Bluetooth identifier. Ensure Bluetooth is on.');
      }
      appLogger.i('Bluetooth adapter name: $name');
      return (id: name, error: null);
    } catch (e) {
      appLogger.e('getBluetoothAddress error: $e');
      return (id: null, error: 'Bluetooth error: $e');
    }
  }

  static double _rssiToMeters(int rssi) {
    if (rssi == 0) return 99.0;
    final ratio = (_txPower - rssi) / (10.0 * _pathLoss);
    return math.pow(10, ratio).toDouble();
  }
}