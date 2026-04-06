import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';

enum BlePermissionStatus { granted, denied, permanentlyDenied }

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // ─── Permissions ────────────────────────────────────────────────────────────

  Future<BlePermissionStatus> requestPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (status.isPermanentlyDenied) return BlePermissionStatus.permanentlyDenied;
      if (status.isGranted) return BlePermissionStatus.granted;
      return BlePermissionStatus.denied;
    }
    return BlePermissionStatus.granted;
  }

  Future<BlePermissionStatus> _requestAndroidPermissions() async {
    final isNew = await _isAndroid12OrAbove();

    List<Permission> permissions;
    if (isNew) {
      permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ];
    } else {
      permissions = [
        Permission.bluetooth,
        Permission.location,
      ];
    }

    final statuses = await permissions.request();
    appLogger.d('BLE permission statuses: $statuses');

    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      return BlePermissionStatus.permanentlyDenied;
    }
    if (statuses.values.every((s) => s.isGranted)) {
      return BlePermissionStatus.granted;
    }
    return BlePermissionStatus.denied;
  }

  Future<bool> _isAndroid12OrAbove() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      appLogger.d('Android SDK: ${info.version.sdkInt}');
      return info.version.sdkInt >= 31;
    } catch (_) {
      return true; // assume new
    }
  }

  // ─── Bluetooth state ─────────────────────────────────────────────────────────

  Future<bool> isBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<void> turnOnBluetooth() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        appLogger.e('Could not turn on BT: $e');
      }
    }
  }

  // ─── Get this device's Bluetooth name ────────────────────────────────────────

  Future<String> getDeviceName() async {
    try {
      // Get the phone's own Bluetooth adapter name
      final adapterName = await FlutterBluePlus.adapterName;
      appLogger.i('This device BT name: $adapterName');
      return adapterName;
    } catch (e) {
      appLogger.e('Could not get device name: $e');
      // Fallback to Android device name
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        return info.model;
      }
      return 'Unknown';
    }
  }

  // ─── Teacher side ─────────────────────────────────────────────────────────────

  /// Teacher calls this — returns their BT device name to save in Firestore
  Future<String> startAdvertising() async {
    final permStatus = await requestPermissions();
    if (permStatus != BlePermissionStatus.granted) {
      throw BlePermissionException(
        'Bluetooth permission required.',
        isPermanentlyDenied: permStatus == BlePermissionStatus.permanentlyDenied,
      );
    }

    final btOn = await isBluetoothOn();
    if (!btOn) await turnOnBluetooth();

    final name = await getDeviceName();
    appLogger.i('Teacher advertising as: $name');
    return name; // This name is saved to Firestore with the OTP session
  }

  Future<void> stopAdvertising() async {
    appLogger.i('Teacher stopped advertising');
  }

  // ─── Student side ─────────────────────────────────────────────────────────────

  /// Student scans for teacher's device by name fetched from Firestore
  /// [teacherDeviceName] — the BT name saved when teacher generated OTP
  Future<bool> isStudentNearTeacher({
    required String teacherDeviceName,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    // 1. Permissions
    final permStatus = await requestPermissions();
    if (permStatus == BlePermissionStatus.permanentlyDenied) {
      throw BlePermissionException(
        'Bluetooth permission permanently denied. Please enable it in App Settings.',
        isPermanentlyDenied: true,
      );
    }
    if (permStatus == BlePermissionStatus.denied) {
      throw BlePermissionException(
        'Bluetooth permission denied.',
        isPermanentlyDenied: false,
      );
    }

    // 2. Bluetooth on
    final btOn = await isBluetoothOn();
    if (!btOn) {
      await turnOnBluetooth();
      final btOnNow = await isBluetoothOn();
      if (!btOnNow) {
        throw const BleBluetoothOffException(
          'Please turn on Bluetooth to verify proximity.',
        );
      }
    }

    appLogger.i('Scanning for teacher device: "$teacherDeviceName"');

    final completer = Completer<bool>();
    double? bestRssi;

    // 3. Scan
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      throw Exception('Failed to start Bluetooth scan: $e');
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final foundName = r.device.platformName;
        final rssi = r.rssi;

        appLogger.d('BLE found: "$foundName" RSSI: $rssi');

        // Match teacher device name (case-insensitive, partial match)
        final teacherLower = teacherDeviceName.toLowerCase().trim();
        final foundLower = foundName.toLowerCase().trim();

        final isMatch = foundLower == teacherLower ||
            foundLower.contains(teacherLower) ||
            teacherLower.contains(foundLower);

        if (isMatch) {
          appLogger.i('✅ Teacher device found! "$foundName" RSSI: $rssi');
          if (bestRssi == null || rssi > bestRssi!) {
            bestRssi = rssi.toDouble();
          }
          if (!completer.isCompleted) {
            // RSSI threshold: -80 dBm ≈ ~15m, -70 dBm ≈ ~10m
            // Using -80 to be slightly lenient with walls/obstacles
            completer.complete(rssi >= -80);
          }
        }
      }
    });

    // Timeout
    Future.delayed(timeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        if (bestRssi != null) {
          completer.complete(bestRssi! >= -80);
        } else {
          completer.completeError(
            BleTeacherNotFoundException(
              'Teacher\'s device ("$teacherDeviceName") not found nearby.\n'
                  'Make sure both Bluetooth are ON and you are within 10 meters.',
            ),
          );
        }
      }
    });

    try {
      final result = await completer.future;
      await stopScan();
      return result;
    } catch (e) {
      await stopScan();
      rethrow;
    }
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
  }

  void dispose() {
    stopScan();
  }
}

// ─── Custom Exceptions ────────────────────────────────────────────────────────

class BlePermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;
  const BlePermissionException(this.message, {required this.isPermanentlyDenied});
  @override
  String toString() => message;
}

class BleBluetoothOffException implements Exception {
  final String message;
  const BleBluetoothOffException(this.message);
  @override
  String toString() => message;
}

class BleTeacherNotFoundException implements Exception {
  final String message;
  const BleTeacherNotFoundException(this.message);
  @override
  String toString() => message;
}