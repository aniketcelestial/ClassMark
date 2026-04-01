import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String otp;
  final DateTime? createdAt;
  final List<String> students;

  AttendanceModel({
    required this.id,
    required this.otp,
    required this.createdAt,
    required this.students,
  });

  /// Convert Firestore → Model
  factory AttendanceModel.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      otp: data['otp'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      students: List<String>.from(data['students'] ?? []),
    );
  }

  /// Convert Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'otp': otp,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'students': students,
    };
  }
}