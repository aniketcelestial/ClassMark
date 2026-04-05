import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/otp_session_model.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/services/otp_service.dart';
import '../../../shared/services/ble_service.dart';
import '../../../core/utils/logger.dart';

final otpServiceProvider = Provider<OtpService>((ref) => OtpService());

final activeSessionProvider =
StateNotifierProvider<ActiveSessionNotifier, OtpSession?>(
      (ref) => ActiveSessionNotifier(ref.read(otpServiceProvider)),
);

class ActiveSessionNotifier extends StateNotifier<OtpSession?> {
  final OtpService _otpService;
  ActiveSessionNotifier(this._otpService) : super(null);

  Future<String?> generateOtp({
    required String teacherId,
    required String teacherName,
    required String subject,
    required String className,
  }) async {
    try {
      debugPrint('>>> GENERATE OTP CALLED');

      final btResult = await BleService.getBluetoothAddress()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return (id: 'SESSION_${DateTime.now().millisecondsSinceEpoch}', error: null);
      });

      debugPrint('>>> BT result: ${btResult.id}');

      final session = await _otpService.createOtpSession(
        teacherId: teacherId,
        teacherName: teacherName,
        subject: subject,
        className: className,
        bluetoothId: btResult.id ?? 'SESSION_${DateTime.now().millisecondsSinceEpoch}',
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Firestore timeout — check internet connection');
      });

      state = session;
      debugPrint('>>> OTP generated: ${session.otp}');
      return null;
    } catch (e, stack) {
      debugPrint('>>> generateOtp ERROR: $e');
      debugPrint('>>> $stack');
      return 'Error: ${e.toString()}';
    }
  }

  Future<void> loadActiveSession(String teacherId) async {
    try {
      final session = await _otpService.getActiveSession(teacherId);
      appLogger.i('Loaded session: ${session?.otp ?? 'none'}');
      state = session;
    } catch (e, stack) {
      appLogger.e('Load session error', error: e, stackTrace: stack);
    }
  }

  Future<void> deactivateSession() async {
    if (state == null) return;
    try {
      await _otpService.deactivateSession(state!.id);
      state = null;
    } catch (e) {
      appLogger.e('Deactivate error: $e');
    }
  }
}

final presentStudentsProvider =
StreamProvider.family<List<AttendanceRecord>, String>(
      (ref, sessionId) =>
      ref.read(otpServiceProvider).getPresentStudents(sessionId),
);