import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/attendance_model.dart';
import '../models/otp_session_model.dart';
import '../models/user_model.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateOtp() {
    final rand = Random.secure();
    return List.generate(AppConstants.otpLength, (_) => rand.nextInt(10)).join();
  }

  Future<OtpSessionModel> generateOtpSession({
    required UserModel teacher,
    required String subject,
  }) async {
    // Deactivate previous sessions for this teacher
    final prev = await _firestore
        .collection(AppConstants.otpSessionsCollection)
        .where('teacherId', isEqualTo: teacher.uid)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in prev.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();

    final now = DateTime.now();
    final session = OtpSessionModel(
      id: '',
      teacherId: teacher.uid,
      teacherName: teacher.name,
      otp: _generateOtp(),
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: AppConstants.otpExpiryMinutes)),
      isActive: true,
      subject: subject,
    );

    final ref = await _firestore
        .collection(AppConstants.otpSessionsCollection)
        .add(session.toMap());

    appLogger.i('OTP session created: ${ref.id}');
    return OtpSessionModel(
      id: ref.id,
      teacherId: session.teacherId,
      teacherName: session.teacherName,
      otp: session.otp,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      isActive: session.isActive,
      subject: session.subject,
    );
  }

  Future<OtpSessionModel?> validateAndSubmitOtp({
    required String otp,
    required UserModel student,
  }) async {
    final query = await _firestore
        .collection(AppConstants.otpSessionsCollection)
        .where('otp', isEqualTo: otp)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid or expired OTP. Please try again.');
    }

    final session = OtpSessionModel.fromMap(
      query.docs.first.data(),
      query.docs.first.id,
    );

    if (session.isExpired) {
      await query.docs.first.reference.update({'isActive': false});
      throw Exception('OTP has expired. Ask your teacher to generate a new one.');
    }

    // Check duplicate attendance
    final existing = await _firestore
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: student.uid)
        .where('otpSessionId', isEqualTo: session.id)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Attendance already marked for this session.');
    }

    // Mark attendance
    final attendance = AttendanceModel(
      id: '',
      studentId: student.uid,
      studentName: student.name,
      enrollmentNumber: student.enrollmentNumber ?? '',
      teacherId: session.teacherId,
      otpSessionId: session.id,
      subject: session.subject,
      markedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.attendanceCollection)
        .add(attendance.toMap());

    appLogger.i('Attendance marked for student: ${student.uid}');
    return session;
  }

  Stream<List<AttendanceModel>> getPresentStudentsForSession(String sessionId) {
    return _firestore
        .collection(AppConstants.attendanceCollection)
        .where('otpSessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => AttendanceModel.fromMap(d.data(), d.id))
        .toList());
  }

  Stream<OtpSessionModel?> watchActiveSession(String teacherId) {
    return _firestore
        .collection(AppConstants.otpSessionsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final session = OtpSessionModel.fromMap(
        snap.docs.first.data(),
        snap.docs.first.id,
      );
      return session.isExpired ? null : session;
    });
  }

  Future<List<AttendanceModel>> getMonthlyAttendance({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final query = await _firestore
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .where('markedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('markedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('markedAt', descending: true)
        .get();

    return query.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList();
  }

  Future<void> deactivateSession(String sessionId) async {
    await _firestore
        .collection(AppConstants.otpSessionsCollection)
        .doc(sessionId)
        .update({'isActive': false});
  }
}