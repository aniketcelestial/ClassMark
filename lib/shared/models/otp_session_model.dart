import 'package:cloud_firestore/cloud_firestore.dart';

class OtpSession {
  final String id;
  final String teacherId;
  final String teacherName;
  final String subject;
  final String className;
  final String otp;
  final String teacherBluetoothId;
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
    required this.teacherBluetoothId,
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
      teacherBluetoothId: data['teacherBluetoothId'] ?? '',
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
      'teacherBluetoothId': teacherBluetoothId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}