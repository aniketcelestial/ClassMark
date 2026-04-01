import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance_model.dart';
import 'package:classmark/widgets/custom_button.dart';

class ProfessorScreen extends StatefulWidget {
  @override
  _ProfessorScreenState createState() => _ProfessorScreenState();
}

class _ProfessorScreenState extends State<ProfessorScreen> {
  String generatedOtp = "";
  bool isLoading = false;

  Future<void> createSession() async {
    setState(() => isLoading = true);
    try {
      // Generate OTP
      String otp = (100000 + Random().nextInt(900000)).toString();

      // Create Firestore session
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .add({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'students': [],
      });

      // Wrap in AttendanceModel
      AttendanceModel session = AttendanceModel(
        id: docRef.id,
        otp: otp,
        createdAt: DateTime.now(),
        students: [],
      );

      setState(() {
        generatedOtp = session.otp;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating session: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> viewPresentStudents() async {
    if (generatedOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Generate OTP first")),
      );
      return;
    }

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('otp', isEqualTo: generatedOtp)
          .get();

      if (snapshot.docs.isEmpty) return;

      AttendanceModel session =
      AttendanceModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());

      List<String> studentEmails = [];
      for (String uid in session.students) {
        var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
        studentEmails.add(userDoc.exists ? userDoc['email'] ?? uid : uid);
      }

      // Show dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Present Students"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: studentEmails.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(studentEmails[index]),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching students: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professor Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomButton(
              text: "Generate OTP",
              onPressed: createSession,
              isLoading: isLoading,
            ),
            const SizedBox(height: 20),
            if (generatedOtp.isNotEmpty) ...[
              Text("Your OTP:", style: TextStyle(color: Colors.grey[700])),
              Text(
                generatedOtp,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.blue),
              ),
              const SizedBox(height: 20),
            ],
            CustomButton(
              text: "View Present Students",
              onPressed: viewPresentStudents,
            ),
          ],
        ),
      ),
    );
  }
}