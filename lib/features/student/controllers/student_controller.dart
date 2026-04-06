import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/models/otp_session_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/ble_service.dart';
import '../../../shared/services/otp_service.dart';
import '../../teacher/controllers/teacher_controller.dart';

final monthlyAttendanceProvider =
FutureProvider.family<List<AttendanceModel>, Map<String, dynamic>>(
      (ref, args) async {
    return ref.watch(otpServiceProvider).getMonthlyAttendance(
      studentId: args['studentId'] as String,
      year: args['year'] as int,
      month: args['month'] as int,
    );
  },
);

class StudentSubmitState {
  final bool isLoading;
  final bool isScanning;
  final String? error;
  final bool isPermanentlyDenied;
  final bool isBluetoothOff;
  final OtpSessionModel? successSession;

  const StudentSubmitState({
    this.isLoading = false,
    this.isScanning = false,
    this.error,
    this.isPermanentlyDenied = false,
    this.isBluetoothOff = false,
    this.successSession,
  });

  StudentSubmitState copyWith({
    bool? isLoading,
    bool? isScanning,
    String? error,
    bool? isPermanentlyDenied,
    bool? isBluetoothOff,
    OtpSessionModel? successSession,
  }) {
    return StudentSubmitState(
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      error: error,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
      isBluetoothOff: isBluetoothOff ?? this.isBluetoothOff,
      successSession: successSession ?? this.successSession,
    );
  }
}

class StudentNotifier extends StateNotifier<StudentSubmitState> {
  final OtpService _otpService;
  final BleService _bleService;

  StudentNotifier(this._otpService, this._bleService)
      : super(const StudentSubmitState());

  Future<bool> submitOtp({
    required String otp,
    required UserModel student,
    bool skipBle = false,
  }) async {
    state = const StudentSubmitState(isLoading: true);

    try {
      if (!skipBle) {
        state = state.copyWith(isScanning: true);
        try {
          final isNear = await _bleService.isStudentNearTeacher();
          state = state.copyWith(isScanning: false);
          if (!isNear) {
            state = state.copyWith(
              isLoading: false,
              error:
              "You're too far from the teacher. Move within 10 meters and try again.",
            );
            return false;
          }
        } on BlePermissionException catch (e) {
          state = state.copyWith(
            isLoading: false,
            isScanning: false,
            error: e.message,
            isPermanentlyDenied: e.isPermanentlyDenied,
          );
          return false;
        } on BleBluetoothOffException catch (e) {
          state = state.copyWith(
            isLoading: false,
            isScanning: false,
            error: e.message,
            isBluetoothOff: true,
          );
          return false;
        } on BleTeacherNotFoundException catch (e) {
          state = state.copyWith(
            isLoading: false,
            isScanning: false,
            error: e.message,
          );
          return false;
        }
      }

      final session = await _otpService.validateAndSubmitOtp(
        otp: otp,
        student: student,
      );

      state = StudentSubmitState(successSession: session);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isScanning: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
  void clearSuccess() => state = const StudentSubmitState();
}

final studentNotifierProvider =
StateNotifierProvider<StudentNotifier, StudentSubmitState>((ref) {
  return StudentNotifier(
    ref.watch(otpServiceProvider),
    ref.watch(bleServiceProvider),
  );
});