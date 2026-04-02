import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/otp_session_model.dart';
import '../models/attendance_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateOtp() {
    final random = Random.secure();
    return List.generate(AppConstants.otpLength, (_) => random.nextInt(10))
        .join();
  }

  Future<OtpSession> createOtpSession({
    required String teacherId,
    required String teacherName,
    required String subject,
    required String className,
    required double latitude,
    required double longitude,
  }) async {
    // Deactivate any existing active session for this teacher
    await _deactivateExistingSessions(teacherId);

    final otp = generateOtp();
    final now = DateTime.now();
    final expiresAt =
    now.add(Duration(minutes: AppConstants.otpExpiryMinutes));

    final docRef = _firestore.collection(AppConstants.otpCollection).doc();
    final session = OtpSession(
      id: docRef.id,
      teacherId: teacherId,
      teacherName: teacherName,
      subject: subject,
      className: className,
      otp: otp,
      teacherLatitude: latitude,
      teacherLongitude: longitude,
      createdAt: now,
      expiresAt: expiresAt,
      isActive: true,
    );

    await docRef.set(session.toMap());
    appLogger.i('OTP Session created: ${session.id}');
    return session;
  }

  Future<void> _deactivateExistingSessions(String teacherId) async {
    final query = await _firestore
        .collection(AppConstants.otpCollection)
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in query.docs) {
      await doc.reference.update({'isActive': false});
    }
  }

  Future<OtpSession?> getActiveSession(String teacherId) async {
    final query = await _firestore
        .collection(AppConstants.otpCollection)
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final session = OtpSession.fromFirestore(query.docs.first);
    if (session.isExpired) {
      await query.docs.first.reference.update({'isActive': false});
      return null;
    }
    return session;
  }

  Future<OtpSession?> validateOtp(String otp) async {
    final query = await _firestore
        .collection(AppConstants.otpCollection)
        .where('otp', isEqualTo: otp)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final session = OtpSession.fromFirestore(query.docs.first);
    if (session.isExpired) {
      await query.docs.first.reference.update({'isActive': false});
      return null;
    }
    return session;
  }

  Future<bool> hasStudentMarkedAttendance({
    required String studentId,
    required String sessionId,
  }) async {
    final query = await _firestore
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> markAttendance(AttendanceRecord record) async {
    await _firestore
        .collection(AppConstants.attendanceCollection)
        .add(record.toMap());
    appLogger.i('Attendance marked for student: ${record.studentId}');
  }

  Future<void> deactivateSession(String sessionId) async {
    await _firestore
        .collection(AppConstants.otpCollection)
        .doc(sessionId)
        .update({'isActive': false});
  }

  Stream<List<AttendanceRecord>> getPresentStudents(String sessionId) {
    return _firestore
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc))
        .toList());
  }

  Future<List<AttendanceRecord>> getStudentMonthlyAttendance({
    required String studentId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = await _firestore
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .where('markedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('markedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('markedAt', descending: false)
        .get();

    return query.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc))
        .toList();
  }
}