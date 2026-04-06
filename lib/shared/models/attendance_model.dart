import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String enrollmentNumber;
  final String teacherId;
  final String otpSessionId;
  final String subject;
  final DateTime markedAt;
  final bool isPresent;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.enrollmentNumber,
    required this.teacherId,
    required this.otpSessionId,
    required this.subject,
    required this.markedAt,
    this.isPresent = true,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      enrollmentNumber: map['enrollmentNumber'] ?? '',
      teacherId: map['teacherId'] ?? '',
      otpSessionId: map['otpSessionId'] ?? '',
      subject: map['subject'] ?? '',
      markedAt: (map['markedAt'] as Timestamp).toDate(),
      isPresent: map['isPresent'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'enrollmentNumber': enrollmentNumber,
      'teacherId': teacherId,
      'otpSessionId': otpSessionId,
      'subject': subject,
      'markedAt': Timestamp.fromDate(markedAt),
      'isPresent': isPresent,
    };
  }
}