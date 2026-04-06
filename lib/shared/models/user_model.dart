import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'teacher' or 'student'
  final String? enrollmentNumber; // students only
  final String? department;       // teachers only
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.enrollmentNumber,
    this.department,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      enrollmentNumber: map['enrollmentNumber'],
      department: map['department'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      if (enrollmentNumber != null) 'enrollmentNumber': enrollmentNumber,
      if (department != null) 'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid, String? name, String? email, String? role,
    String? enrollmentNumber, String? department, DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}