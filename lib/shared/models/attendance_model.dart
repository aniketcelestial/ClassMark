import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String subject;
  final String className;
  final String sessionId;
  final DateTime markedAt;
  final double distanceFromTeacher; // BLE RSSI-estimated metres

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.subject,
    required this.className,
    required this.sessionId,
    required this.markedAt,
    required this.distanceFromTeacher,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      subject: data['subject'] ?? '',
      className: data['className'] ?? '',
      sessionId: data['sessionId'] ?? '',
      markedAt: (data['markedAt'] as Timestamp).toDate(),
      distanceFromTeacher: (data['distanceFromTeacher'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'subject': subject,
      'className': className,
      'sessionId': sessionId,
      'markedAt': Timestamp.fromDate(markedAt),
      'distanceFromTeacher': distanceFromTeacher,
    };
  }
}