import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ProfessorScreen extends StatefulWidget {
  const ProfessorScreen({super.key});

  @override
  State<ProfessorScreen> createState() => _ProfessorScreenState();
}

class _ProfessorScreenState extends State<ProfessorScreen> {
  String generatedOtp = "";
  bool isLoading = false;

  String generateOTP() {
    Random random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  Future<void> createSession() async {
    setState(() => isLoading = true);

    try {
      String otp = generateOTP();

      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .add({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'students': [],
      });

      setState(() {
        generatedOtp = otp;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professor Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : createSession,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Generate OTP"),
            ),

            const SizedBox(height: 20),

            if (generatedOtp.isNotEmpty) ...[
              const Text(
                "Your OTP is:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                generatedOtp,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
            ],

            ElevatedButton(
              onPressed: () async {
                if (generatedOtp.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please generate OTP first")),
                  );
                  return;
                }

                try {
                  // 1️⃣ Find session with current OTP
                  var snapshot = await FirebaseFirestore.instance
                      .collection('attendance_sessions')
                      .where('otp', isEqualTo: generatedOtp)
                      .get();

                  if (snapshot.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No session found for this OTP")),
                    );
                    return;
                  }

                  var doc = snapshot.docs.first;
                  List students = doc['students'] ?? [];

                  // 2️⃣ Fetch student emails from 'users' collection
                  List<String> studentEmails = [];

                  for (String uid in students) {
                    var userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get();
                    if (userDoc.exists) {
                      studentEmails.add(userDoc['email'] ?? uid);
                    } else {
                      studentEmails.add(uid); // fallback to UID
                    }
                  }

                  // 3️⃣ Show in dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Present Students"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: studentEmails.length,
                          itemBuilder: (_, index) {
                            return ListTile(
                              title: Text(studentEmails[index]),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("View Present Students"),
            ),
          ],
        ),
      ),
    );
  }
}