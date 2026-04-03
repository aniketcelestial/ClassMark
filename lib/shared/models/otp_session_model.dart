import 'package:cloud_firestore/cloud_firestore.dart';

class OtpSession {
  final String id;
  final String teacherId;
  final String teacherName;
  final String subject;
  final String className;
  final String otp;
  final double teacherLatitude;
  final double teacherLongitude;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  const OtpSession({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.className,
    required this.otp,
    required this.teacherLatitude,
    required this.teacherLongitude,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
  });

  factory OtpSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OtpSession(
      id: doc.id,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      subject: data['subject'] ?? '',
      className: data['className'] ?? '',
      otp: data['otp'] ?? '',
      teacherLatitude: (data['teacherLatitude'] ?? 0.0).toDouble(),
      teacherLongitude: (data['teacherLongitude'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'className': className,
      'otp': otp,
      'teacherLatitude': teacherLatitude,
      'teacherLongitude': teacherLongitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
