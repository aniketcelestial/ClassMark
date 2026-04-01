import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> generateOTP() async {
    final random = Random();
    String otp = (100000 + random.nextInt(900000)).toString();

    await _db.collection('attendance_sessions').add({
      'otp': otp,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 5)),
    });

    return otp;
  }

  Future<void> markAttendance(String otp, String uid) async {
    var snapshot = await _db
        .collection('attendance_sessions')
        .where('otp', isEqualTo: otp)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Invalid OTP');
    }

    var doc = snapshot.docs.first;
    var data = doc.data();

    if (data['expiresAt'] != null &&
        DateTime.now().isAfter(data['expiresAt'].toDate())) {
      throw Exception('OTP expired');
    }

    await _db
        .collection('attendance_sessions')
        .doc(doc.id)
        .collection('present_students')
        .doc(uid)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }
}