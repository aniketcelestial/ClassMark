import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/otp_session_model.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/services/otp_service.dart';
import '../../../shared/services/location_service.dart';
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
      // Get location with a specific error message
      final locResult = await LocationService.getPositionWithReason();
      if (locResult.position == null) {
        appLogger.e('Location failed: ${locResult.error}');
        return locResult.error;
      }

      final pos = locResult.position!;
      appLogger.i('Creating OTP session for $teacherName at ${pos.latitude}, ${pos.longitude}');

      final session = await _otpService.createOtpSession(
        teacherId: teacherId,
        teacherName: teacherName,
        subject: subject,
        className: className,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      state = session;
      appLogger.i('OTP generated successfully: ${session.otp}');
      return null;
    } catch (e, stack) {
      appLogger.e('Generate OTP error', error: e, stackTrace: stack);
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
