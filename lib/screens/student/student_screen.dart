import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController otpController = TextEditingController();

  Future<void> verifyOTP() async {
    String enteredOtp = otpController.text.trim();

    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    String uid = user.uid;

    var snapshot = await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .where('otp', isEqualTo: enteredOtp)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      var data = doc.data();

      // ✅ Check expiry
      if (data['expiresAt'] != null &&
          DateTime.now().isAfter(data['expiresAt'].toDate())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP expired")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(doc.id)
          .update({
        'students': FieldValue.arrayUnion([uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance marked successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: verifyOTP,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit OTP"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User not logged in")),
                  );
                  return;
                }

                String uid = user.uid;

                try {
                  // 1️⃣ Fetch all attendance sessions where student is present
                  var snapshot = await FirebaseFirestore.instance
                      .collection('attendance_sessions')
                      .where('students', arrayContains: uid)
                      .orderBy('createdAt', descending: true)
                      .get();

                  if (snapshot.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No attendance records found")),
                    );
                    return;
                  }

                  // 2️⃣ Group by month
                  Map<String, List<DateTime>> monthlyAttendance = {};

                  for (var doc in snapshot.docs) {
                    DateTime? date = (doc['createdAt'] as Timestamp?)?.toDate();
                    if (date != null) {
                      String monthKey = "${date.year}-${date.month.toString().padLeft(2,'0')}";
                      if (!monthlyAttendance.containsKey(monthKey)) {
                        monthlyAttendance[monthKey] = [];
                      }
                      monthlyAttendance[monthKey]!.add(date);
                    }
                  }

                  // 3️⃣ Show in dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Monthly Attendance"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: monthlyAttendance.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key, // "2026-04"
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                ...entry.value.map((date) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    "- ${date.day}-${date.month}-${date.year}",
                                  ),
                                )),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
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
              child: const Text("View Attendance"),
            ),
          ],
        ),
      ),
    );
  }
}