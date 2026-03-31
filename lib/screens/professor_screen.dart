import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorScreen extends StatefulWidget {

  @override
  _ProfessorScreenState createState() => _ProfessorScreenState();
}

class _ProfessorScreenState extends State<ProfessorScreen> {

  String generatedOtp = "";

  String generateOTP() {
    Random random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  Future<void> createSession() async {
    try {
      String otp = generateOTP();

      await FirebaseFirestore.instance.collection('attendance_sessions').add({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'students': []
      });

      setState(() {
        generatedOtp = otp;
      });
    } catch (e) {
      print("Error creating session: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Professor Dashboard")),
      body: Padding(
          padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: createSession,
              child: Text("Generate OTP"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            SizedBox(height: 20),

            if (generatedOtp.isNotEmpty) ...[
              Text(
                "Your OTP is:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                generatedOtp,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
            ],

            ElevatedButton(
              onPressed: () {

                //todo show present student
              },
              child: Text("View Present Students"),
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