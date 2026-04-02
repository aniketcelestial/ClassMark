import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/otp_session_model.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/services/otp_service.dart';
import '../../../shared/services/location_service.dart';
import '../../../core/utils/logger.dart';

final otpServiceProvider = Provider<OtpService>((ref) => OtpService());

// Active OTP session state
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
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        return 'Location permission is required to generate OTP. Please enable location access.';
      }

      final session = await _otpService.createOtpSession(
        teacherId: teacherId,
        teacherName: teacherName,
        subject: subject,
        className: className,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      state = session;
      appLogger.i('OTP generated: ${session.otp}');
      return null;
    } catch (e) {
      appLogger.e('Generate OTP error: $e');
      return 'Failed to generate OTP. Please try again.';
    }
  }

  Future<void> loadActiveSession(String teacherId) async {
    try {
      state = await _otpService.getActiveSession(teacherId);
    } catch (e) {
      appLogger.e('Load session error: $e');
    }
  }

  Future<void> deactivateSession() async {
    if (state == null) return;
    try {
      await _otpService.deactivateSession(state!.id);
      state = null;
    } catch (e) {
      appLogger.e('Deactivate session error: $e');
    }
  }
}

// Present students stream
final presentStudentsProvider =
StreamProvider.family<List<AttendanceRecord>, String>(
      (ref, sessionId) {
    return ref.read(otpServiceProvider).getPresentStudents(sessionId);
  },
);