import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/services/otp_service.dart';
import '../../../shared/services/location_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../teacher/controllers/teacher_controller.dart';

enum OtpSubmitResult {
  success,
  invalidOtp,
  expired,
  outOfRange,
  locationError,
  alreadyMarked,
  error,
}

final studentControllerProvider =
    Provider<StudentController>((ref) {
  return StudentController(ref.read(otpServiceProvider));
});

class StudentController {
  final OtpService _otpService;
  StudentController(this._otpService);

  Future<OtpSubmitResult> submitOtp({
    required String otp,
    required String studentId,
    required String studentName,
  }) async {
    try {
      // 1. Validate OTP
      final session = await _otpService.validateOtp(otp);
      if (session == null) return OtpSubmitResult.invalidOtp;
      if (session.isExpired) return OtpSubmitResult.expired;

      // 2. Check if already marked
      final alreadyMarked = await _otpService.hasStudentMarkedAttendance(
        studentId: studentId,
        sessionId: session.id,
      );
      if (alreadyMarked) return OtpSubmitResult.alreadyMarked;

      // 3. Get student location
      final position = await LocationService.getCurrentPosition();
      if (position == null) return OtpSubmitResult.locationError;

      // 4. Check proximity (20m range)
      final distance = LocationService.calculateDistance(
        lat1: session.teacherLatitude,
        lon1: session.teacherLongitude,
        lat2: position.latitude,
        lon2: position.longitude,
      );

      if (distance > AppConstants.proximityRadiusMeters) {
        appLogger.w(
            'Student out of range: ${distance.toStringAsFixed(1)}m');
        return OtpSubmitResult.outOfRange;
      }

      // 5. Mark attendance
      final record = AttendanceRecord(
        id: '',
        studentId: studentId,
        studentName: studentName,
        teacherId: session.teacherId,
        subject: session.subject,
        className: session.className,
        sessionId: session.id,
        markedAt: DateTime.now(),
        studentLatitude: position.latitude,
        studentLongitude: position.longitude,
        distanceFromTeacher: distance,
      );

      await _otpService.markAttendance(record);
      appLogger.i('Attendance marked! Distance: ${distance.toStringAsFixed(1)}m');
      return OtpSubmitResult.success;
    } catch (e) {
      appLogger.e('Submit OTP error: $e');
      return OtpSubmitResult.error;
    }
  }
}
