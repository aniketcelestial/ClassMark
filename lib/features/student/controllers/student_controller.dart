import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/services/otp_service.dart';
import '../../../shared/services/ble_service.dart';
import '../../../core/utils/logger.dart';
import '../../teacher/controllers/teacher_controller.dart';

enum OtpSubmitResult {
  success,
  invalidOtp,
  expired,
  outOfRange,
  bluetoothError,
  alreadyMarked,
  error,
}

final studentControllerProvider = Provider<StudentController>(
        (ref) => StudentController(ref.read(otpServiceProvider)));

class StudentController {
  final OtpService _otpService;
  StudentController(this._otpService);

  Future<OtpSubmitResult> submitOtp({
    required String otp,
    required String studentId,
    required String studentName,
  }) async {
    try {
      // 1. Validate OTP exists and is active
      final session = await _otpService.validateOtp(otp);
      if (session == null) return OtpSubmitResult.invalidOtp;
      if (session.isExpired) return OtpSubmitResult.expired;

      // 2. Check already marked
      final alreadyMarked = await _otpService.hasStudentMarkedAttendance(
        studentId: studentId,
        sessionId: session.id,
      );
      if (alreadyMarked) return OtpSubmitResult.alreadyMarked;

      // 3. BLE proximity check
      appLogger.i('Scanning for teacher BT: ${session.teacherBluetoothId}');
      final bleResult = await BleService.checkProximityToTeacher(
        teacherBluetoothId: session.teacherBluetoothId,
      );

      if (bleResult.error != null && bleResult.meters == null) {
        // Device not found at all
        appLogger.w('BLE proximity error: ${bleResult.error}');
        return OtpSubmitResult.outOfRange;
      }

      if (!bleResult.inRange) {
        appLogger.w(
            'Student out of range: ${bleResult.meters?.toStringAsFixed(1)}m');
        return OtpSubmitResult.outOfRange;
      }

      // 4. Mark attendance
      final record = AttendanceRecord(
        id: '',
        studentId: studentId,
        studentName: studentName,
        teacherId: session.teacherId,
        subject: session.subject,
        className: session.className,
        sessionId: session.id,
        markedAt: DateTime.now(),
        distanceFromTeacher: bleResult.meters ?? 0.0,
      );

      await _otpService.markAttendance(record);
      appLogger.i(
          'Attendance marked! BLE distance: ${bleResult.meters?.toStringAsFixed(1)}m');
      return OtpSubmitResult.success;
    } catch (e, stack) {
      appLogger.e('submitOtp error', error: e, stackTrace: stack);
      return OtpSubmitResult.error;
    }
  }
}