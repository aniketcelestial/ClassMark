import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController otpController = TextEditingController();

  Future<void> verifyOTP() async {
    String enteredOtp = otpController.text.trim();
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var snapshot = await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .where('otp', isEqualTo: enteredOtp)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;

      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(doc.id)
      .update({
        'students': FieldValue.arrayUnion([uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Dashboard")),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              decoration: InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: verifyOTP,
              child: Text("Submit OTP"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                //todo show monthly attendance
              },
              child: Text("View Attendance"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}