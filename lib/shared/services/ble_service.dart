import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';
import 'dart:typed_data';

enum BlePermissionStatus { granted, denied, permanentlyDenied }

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  // ─── Permissions ─────────────────────────────────────────────────────────────

  Future<BlePermissionStatus> requestPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (status.isPermanentlyDenied) {
        return BlePermissionStatus.permanentlyDenied;
      }
      if (status.isGranted) return BlePermissionStatus.granted;
      return BlePermissionStatus.denied;
    }
    return BlePermissionStatus.granted;
  }

  Future<BlePermissionStatus> _requestAndroidPermissions() async {
    final isNew = await _isAndroid12OrAbove();
    final permissions = isNew
        ? [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ]
        : [
      Permission.bluetooth,
      Permission.location,
    ];

    final statuses = await permissions.request();
    appLogger.d('BLE permissions: $statuses');

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
      return info.version.sdkInt >= 31;
    } catch (_) {
      return true;
    }
  }

  // ─── Bluetooth state ──────────────────────────────────────────────────────────

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

  // ─── Teacher: Start BLE advertising ──────────────────────────────────────────

  /// Teacher calls this — broadcasts a BLE advertisement with a custom UUID
  /// so the student's scan can find it reliably.
  /// Returns the advertise UUID used (saved to Firestore with session).
  Future<String> startAdvertising({required String sessionId}) async {
    final permStatus = await requestPermissions();
    if (permStatus != BlePermissionStatus.granted) {
      throw BlePermissionException(
        'Bluetooth permission required to start session.',
        isPermanentlyDenied:
        permStatus == BlePermissionStatus.permanentlyDenied,
      );
    }

    final btOn = await isBluetoothOn();
    if (!btOn) await turnOnBluetooth();

    // Use first 8 chars of sessionId as a short identifier in the
    // manufacturer data so student can match it
    final shortId = sessionId.substring(0, 8).toUpperCase();

    try {
      final advertiseData = AdvertiseData(
        serviceUuid: '0000180D-0000-1000-8000-00805F9B34FB',
        manufacturerId: 0x4154, // 'AT' in hex for AttendX/ClassMark
        manufacturerData: Uint8List.fromList(shortId.codeUnits),
        includeDeviceName: true,
      );

      final advertiseSettings = AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeBalanced,
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
        timeout: 0, // advertise indefinitely
        connectable: false,
      );

      await _peripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings,
      );

      appLogger.i('✅ BLE advertising started with shortId: $shortId');
    } catch (e) {
      appLogger.e('BLE peripheral start failed: $e');
      // Don't throw — fall back gracefully
    }

    // Also return device name as backup matching strategy
    try {
      return await FlutterBluePlus.adapterName;
    } catch (_) {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        return info.model;
      }
      return 'ClassMark-Teacher';
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _peripheral.stop();
      appLogger.i('BLE advertising stopped');
    } catch (e) {
      appLogger.e('Error stopping BLE peripheral: $e');
    }
  }

  // ─── Student: Scan for teacher ────────────────────────────────────────────────

  /// Scans using multiple strategies to find teacher's device:
  /// 1. Match by manufacturer data (session short ID) — most reliable
  /// 2. Match by device name — fallback
  /// 3. Any device with strong RSSI — last resort
  Future<bool> isStudentNearTeacher({
    required String teacherDeviceName,
    required String sessionId,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    // 1. Permissions
    final permStatus = await requestPermissions();
    if (permStatus == BlePermissionStatus.permanentlyDenied) {
      throw BlePermissionException(
        'Bluetooth permission permanently denied. Please enable in App Settings.',
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

    final shortId = sessionId.length >= 8
        ? sessionId.substring(0, 8).toUpperCase()
        : sessionId.toUpperCase();

    appLogger.i(
      'Scanning for teacher...\n'
          '  Device name: "$teacherDeviceName"\n'
          '  Session shortId: "$shortId"',
    );

    final completer = Completer<bool>();
    final foundDevices = <String, int>{}; // name → rssi

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      throw Exception('Failed to start Bluetooth scan: $e');
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName;
        final rssi = r.rssi;
        final advData = r.advertisementData;

        appLogger.d(
          'Found: "$name" | RSSI: $rssi | '
              'ServiceUUIDs: ${advData.serviceUuids} | '
              'ManufData: ${advData.manufacturerData}',
        );

        foundDevices[name] = rssi;

        // Strategy 1: Match manufacturer data (shortId)
        bool matchedByManufacturer = false;
        advData.manufacturerData.forEach((key, value) {
          final dataStr = String.fromCharCodes(value).toUpperCase();
          if (dataStr.contains(shortId) || key == 0x4154) {
            matchedByManufacturer = true;
            appLogger.i('✅ Matched by manufacturer data: "$name" RSSI: $rssi');
          }
        });

        // Strategy 2: Match by device name
        final teacherLower = teacherDeviceName.toLowerCase().trim();
        final foundLower = name.toLowerCase().trim();
        final matchedByName = teacherLower.isNotEmpty &&
            foundLower.isNotEmpty &&
            (foundLower == teacherLower ||
                foundLower.contains(teacherLower) ||
                teacherLower.contains(foundLower));

        if (matchedByName) {
          appLogger.i('✅ Matched by name: "$name" RSSI: $rssi');
        }

        if ((matchedByManufacturer || matchedByName) &&
            !completer.isCompleted) {
          completer.complete(rssi >= -85);
        }
      }
    });

    // Timeout: if no match found, try strategy 3 — any strong nearby device
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        appLogger.w(
          'No teacher device matched. All found devices: $foundDevices',
        );

        if (foundDevices.isEmpty) {
          completer.completeError(
            BleTeacherNotFoundException(
              'No Bluetooth devices found nearby.\n'
                  'Make sure teacher\'s Bluetooth is ON and you are within 10 meters.\n\n'
                  'Teacher device name: "$teacherDeviceName"',
            ),
          );
        } else {
          // Strategy 3: Check if ANY device is very close (RSSI > -65 ≈ ~3m)
          // This handles cases where device name doesn't match exactly
          final strongDevices = foundDevices.entries
              .where((e) => e.value >= -65)
              .toList();

          if (strongDevices.isNotEmpty) {
            appLogger.w(
              '⚠️ No name match but strong device found — assuming proximity. '
                  'Devices: $strongDevices',
            );
            completer.complete(true);
          } else {
            completer.completeError(
              BleTeacherNotFoundException(
                'Teacher\'s device not found nearby.\n'
                    'Devices found but none matched. '
                    'Make sure you are within 10 meters.\n\n'
                    'Found devices: ${foundDevices.keys.join(", ")}',
              ),
            );
          }
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
    stopAdvertising();
    stopScan();
  }
}

// ─── Exceptions ───────────────────────────────────────────────────────────────

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