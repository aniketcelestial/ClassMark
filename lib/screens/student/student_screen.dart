import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance_model.dart';
import 'package:classmark/widgets/custom_button.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isSubmitting = false;
  bool showOtpField = false;

  Future<void> submitOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      var snapshot = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('otp', isEqualTo: otp)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid OTP")));
        return;
      }

      // Update students array
      var docRef = snapshot.docs.first.reference;
      await docRef.update({
        'students': FieldValue.arrayUnion([uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance marked successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting OTP: $e")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> viewMonthlyAttendance() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      var snapshot = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('students', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No attendance records found")));
        return;
      }

      // Map to AttendanceModel
      List<AttendanceModel> sessions = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.id, doc.data()))
          .toList();

      // Group by month
      Map<String, List<DateTime>> monthly = {};
      for (var session in sessions) {
        if (session.createdAt == null) continue;
        String key =
            "${session.createdAt!.year}-${session.createdAt!.month.toString().padLeft(2, '0')}";
        monthly.putIfAbsent(key, () => []);
        monthly[key]!.add(session.createdAt!);
      }

      // Show dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Monthly Attendance"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: monthly.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ...entry.value.map((date) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                          "- ${date.day}-${date.month}-${date.year}"),
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
                child: const Text("Close"))
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching attendance: $e")));
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
            CustomButton(
              text: "Mark Attendance",
              onPressed: () {
                setState(() {
                  showOtpField = true; // Show OTP input when clicked
                });
              },
            ),
            const SizedBox(height: 20),
            if (showOtpField) ...[
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                    labelText: "Enter OTP", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Submit OTP",
                onPressed: submitOtp,
                isLoading: isSubmitting,
              ),
            ],
            const SizedBox(height: 20),
            CustomButton(
              text: "View Attendance",
              onPressed: viewMonthlyAttendance,
            ),
          ],
        ),
      ),
    );
  }
}