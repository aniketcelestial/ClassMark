import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/models/otp_session_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/ble_service.dart';
import '../../../shared/services/otp_service.dart';

final otpServiceProvider = Provider<OtpService>((ref) => OtpService());
final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final activeSessionProvider = StreamProvider.family<OtpSessionModel?, String>(
      (ref, teacherId) {
    return ref.watch(otpServiceProvider).watchActiveSession(teacherId);
  },
);

final presentStudentsProvider =
StreamProvider.family<List<AttendanceModel>, String>(
      (ref, sessionId) {
    return ref.watch(otpServiceProvider).getPresentStudentsForSession(sessionId);
  },
);

class TeacherNotifier extends StateNotifier<AsyncValue<OtpSessionModel?>> {
  final OtpService _otpService;
  final BleService _bleService;

  TeacherNotifier(this._otpService, this._bleService)
      : super(const AsyncValue.data(null));

  Future<OtpSessionModel?> generateOtp({
    required UserModel teacher,
    required String subject,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get teacher's own Bluetooth device name
      final deviceName = await _bleService.startAdvertising();

      final session = await _otpService.generateOtpSession(
        teacher: teacher,
        subject: subject,
        teacherDeviceName: deviceName,
      );
      state = AsyncValue.data(session);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> deactivateSession(String sessionId) async {
    try {
      await _bleService.stopAdvertising();
      await _otpService.deactivateSession(sessionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final teacherNotifierProvider =
StateNotifierProvider<TeacherNotifier, AsyncValue<OtpSessionModel?>>((ref) {
  return TeacherNotifier(
    ref.watch(otpServiceProvider),
    ref.watch(bleServiceProvider),
  );
});