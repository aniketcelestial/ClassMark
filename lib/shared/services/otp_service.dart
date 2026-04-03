import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/otp_session_model.dart';
import '../models/attendance_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class OtpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String generateOtp() {
    final r = Random.secure();
    return List.generate(AppConstants.otpLength, (_) => r.nextInt(10)).join();
  }

  Future<OtpSession> createOtpSession({
    required String teacherId,
    required String teacherName,
    required String subject,
    required String className,
    required String bluetoothId,
  }) async {
    await _deactivateExistingSessions(teacherId);

    final otp = generateOtp();
    final now = DateTime.now();
    final expiresAt =
    now.add(Duration(minutes: AppConstants.otpExpiryMinutes));

    final docRef = _db.collection(AppConstants.otpCollection).doc();
    final session = OtpSession(
      id: docRef.id,
      teacherId: teacherId,
      teacherName: teacherName,
      subject: subject,
      className: className,
      otp: otp,
      teacherBluetoothId: bluetoothId,
      createdAt: now,
      expiresAt: expiresAt,
      isActive: true,
    );

    await docRef.set(session.toMap());
    appLogger.i('OTP created: ${session.otp} | BT: $bluetoothId');
    return session;
  }

  Future<void> _deactivateExistingSessions(String teacherId) async {
    final snap = await _db
        .collection(AppConstants.otpCollection)
        .where('teacherId', isEqualTo: teacherId)
        .get();
    for (final doc in snap.docs) {
      if (doc.data()['isActive'] == true) {
        await doc.reference.update({'isActive': false});
      }
    }
  }

  Future<OtpSession?> getActiveSession(String teacherId) async {
    final snap = await _db
        .collection(AppConstants.otpCollection)
        .where('teacherId', isEqualTo: teacherId)
        .get();

    if (snap.docs.isEmpty) return null;

    final active = snap.docs
        .where((d) => d.data()['isActive'] == true)
        .toList();
    if (active.isEmpty) return null;

    active.sort((a, b) {
      final ta = (a.data()['createdAt'] as Timestamp).toDate();
      final tb = (b.data()['createdAt'] as Timestamp).toDate();
      return tb.compareTo(ta);
    });

    final session = OtpSession.fromFirestore(active.first);
    if (session.isExpired) {
      await active.first.reference.update({'isActive': false});
      return null;
    }
    return session;
  }

  Future<OtpSession?> validateOtp(String otp) async {
    final snap = await _db
        .collection(AppConstants.otpCollection)
        .where('otp', isEqualTo: otp)
        .get();

    if (snap.docs.isEmpty) return null;

    final active = snap.docs
        .where((d) => d.data()['isActive'] == true)
        .toList();
    if (active.isEmpty) return null;

    final session = OtpSession.fromFirestore(active.first);
    if (session.isExpired) {
      await active.first.reference.update({'isActive': false});
      return null;
    }
    return session;
  }

  Future<bool> hasStudentMarkedAttendance({
    required String studentId,
    required String sessionId,
  }) async {
    final snap = await _db
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .where('sessionId', isEqualTo: sessionId)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> markAttendance(AttendanceRecord record) async {
    await _db.collection(AppConstants.attendanceCollection).add(record.toMap());
    appLogger.i('Attendance marked for ${record.studentName}');
  }

  Future<void> deactivateSession(String sessionId) async {
    await _db
        .collection(AppConstants.otpCollection)
        .doc(sessionId)
        .update({'isActive': false});
  }

  Stream<List<AttendanceRecord>> getPresentStudents(String sessionId) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList());
  }

  Future<List<AttendanceRecord>> getStudentMonthlyAttendance({
    required String studentId,
    required DateTime month,
  }) async {
    final snap = await _db
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .get();

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth =
    DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final records = snap.docs
        .map((d) => AttendanceRecord.fromFirestore(d))
        .where((r) =>
    r.markedAt.isAfter(
        startOfMonth.subtract(const Duration(seconds: 1))) &&
        r.markedAt
            .isBefore(endOfMonth.add(const Duration(seconds: 1))))
        .toList();

    records.sort((a, b) => a.markedAt.compareTo(b.markedAt));
    return records;
  }
}