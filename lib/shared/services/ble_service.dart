import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum BlePermissionStatus { granted, denied, permanentlyDenied }

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Request all required BLE permissions with proper rationale
  Future<BlePermissionStatus> requestPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (status.isGranted) return BlePermissionStatus.granted;
      if (status.isPermanentlyDenied) return BlePermissionStatus.permanentlyDenied;
      return BlePermissionStatus.denied;
    }
    return BlePermissionStatus.granted;
  }

  Future<BlePermissionStatus> _requestAndroidPermissions() async {
    // Android 12+ (API 31+)
    if (await _isAndroid12OrAbove()) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      appLogger.d('BLE permissions status: $statuses');

      final anyPermanentlyDenied = statuses.values
          .any((s) => s == PermissionStatus.permanentlyDenied);
      if (anyPermanentlyDenied) return BlePermissionStatus.permanentlyDenied;

      final allGranted = statuses.values.every((s) => s.isGranted);
      return allGranted
          ? BlePermissionStatus.granted
          : BlePermissionStatus.denied;
    } else {
      // Android 11 and below needs location
      final statuses = await [
        Permission.bluetooth,
        Permission.location,
      ].request();

      final anyPermanentlyDenied = statuses.values
          .any((s) => s == PermissionStatus.permanentlyDenied);
      if (anyPermanentlyDenied) return BlePermissionStatus.permanentlyDenied;

      final allGranted = statuses.values.every((s) => s.isGranted);
      return allGranted
          ? BlePermissionStatus.granted
          : BlePermissionStatus.denied;
    }
  }

  Future<bool> _isAndroid12OrAbove() async {
    if (!Platform.isAndroid) return false;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      appLogger.d('Android SDK version: ${androidInfo.version.sdkInt}');
      return androidInfo.version.sdkInt >= 31;
    } catch (e) {
      appLogger.e('Could not get Android SDK version: $e');
      // Default to Android 12+ behavior to be safe
      return true;
    }
  }

  Future<bool> isBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  /// Enable bluetooth programmatically (Android only)
  Future<void> turnOnBluetooth() async {
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<bool> startAdvertising() async {
    appLogger.i('BLE: Teacher device is now discoverable as ClassMark-Teacher');
    return true;
  }

  Future<void> stopAdvertising() async {
    appLogger.i('BLE: Teacher stopped advertising');
  }

  /// Full proximity check with proper permission handling
  /// Returns RSSI value if teacher found, throws detailed exception otherwise
  Future<double> scanForTeacherRssi({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Check permissions
    final permStatus = await requestPermissions();
    if (permStatus == BlePermissionStatus.permanentlyDenied) {
      throw BlePermissionException(
        'Bluetooth permission permanently denied. Please enable it in app settings.',
        isPermanentlyDenied: true,
      );
    }
    if (permStatus == BlePermissionStatus.denied) {
      throw BlePermissionException(
        'Bluetooth permission denied.',
        isPermanentlyDenied: false,
      );
    }

    // Check if bluetooth is on
    final btOn = await isBluetoothOn();
    if (!btOn) {
      try {
        await turnOnBluetooth();
        await Future.delayed(const Duration(seconds: 1));
        final btOnNow = await isBluetoothOn();
        if (!btOnNow) {
          throw const BleBluetoothOffException(
            'Bluetooth is turned off. Please enable Bluetooth to verify proximity.',
          );
        }
      } catch (e) {
        if (e is BleBluetoothOffException) rethrow;
        throw const BleBluetoothOffException(
          'Please turn on Bluetooth to verify proximity.',
        );
      }
    }

    double? bestRssi;
    final completer = Completer<double>();

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      appLogger.e('BLE scan start error: $e');
      throw Exception('Failed to start Bluetooth scan. Please try again.');
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen(
          (results) {
        for (final result in results) {
          final name = result.device.platformName.toLowerCase();
          appLogger.d(
            'Found BLE device: "${result.device.platformName}" RSSI: ${result.rssi}',
          );

          if (name.contains('classmark') ||
              name.contains('attendx') ||
              name.contains('attend-x') ||
              name.contains('classmark-teacher')) {
            final rssi = result.rssi.toDouble();
            if (bestRssi == null || rssi > bestRssi!) {
              bestRssi = rssi;
            }
            if (!completer.isCompleted) {
              completer.complete(rssi);
            }
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Bluetooth scan error: $e'),
          );
        }
      },
    );

    // Timeout fallback
    Future.delayed(timeout + const Duration(seconds: 1), () {
      if (!completer.isCompleted) {
        if (bestRssi != null) {
          completer.complete(bestRssi!);
        } else {
          completer.completeError(
            const BleTeacherNotFoundException(
              "Teacher's device not found nearby. Make sure you're within 10 meters and teacher's Bluetooth is ON.",
            ),
          );
        }
      }
    });

    try {
      final rssi = await completer.future;
      await stopScan();
      return rssi;
    } catch (e) {
      await stopScan();
      rethrow;
    }
  }

  Future<bool> isStudentNearTeacher() async {
    final rssi = await scanForTeacherRssi();
    appLogger.i(
      'BLE RSSI: $rssi (threshold: ${AppConstants.bleProximityThreshold})',
    );
    return rssi >= AppConstants.bleProximityThreshold;
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

// Custom BLE exceptions for precise error handling
class BlePermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;
  const BlePermissionException(this.message,
      {required this.isPermanentlyDenied});
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