import 'package:cloud_firestore/cloud_firestore.dart';

class OtpSessionModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String otp;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final String subject;
  final String teacherDeviceName;

  OtpSessionModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.otp,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.subject,
    this.teacherDeviceName = '',
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory OtpSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return OtpSessionModel(
      id: id,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      otp: map['otp'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
      subject: map['subject'] ?? '',
      teacherDeviceName: map['teacherDeviceName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'otp': otp,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'subject': subject,
      'teacherDeviceName': teacherDeviceName,
    };
  }
}