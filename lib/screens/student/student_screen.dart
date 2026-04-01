import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classmark/widgets/custom_button.dart';
import 'package:classmark/services/firebase_helper.dart';
import 'package:geolocator/geolocator.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController otpController = TextEditingController();
  bool showOtpField = false;
  bool isSubmitting = false;

  Future<void> submitOtp() async {
    setState(() => isSubmitting = true);

    try {
      String enteredOtp = otpController.text.trim();
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // ✅ Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled");
      }

      // ✅ Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied");
      }

      // ✅ Accurate location (2 readings)


      Future<Position> getAccurateLocation() async {
        Position pos1 = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        await Future.delayed(const Duration(seconds: 1));

        Position pos2 = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        return pos1.accuracy < pos2.accuracy ? pos1 : pos2;
      }

      Position? studentPos = await safeGetLocation(context);
      if (studentPos == null) return;

      // ❌ Reject low accuracy
      if (studentPos.accuracy > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Low GPS accuracy. Try again.")),
        );
        return;
      }

      // ❌ Reject fake GPS
      if (studentPos.isMocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fake location detected")),
        );
        return;
      }

      // ✅ Fetch session
      var snapshot = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('otp', isEqualTo: enteredOtp)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP")),
        );
        return;
      }

      var doc = snapshot.docs.first;

      // ✅ Check OTP expiry (1 minute)
      DateTime createdAt = (doc['createdAt'] as Timestamp).toDate();

      if (DateTime.now().difference(createdAt).inSeconds > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP expired (1 min)")),
        );
        return;
      }

      double profLat = doc['latitude'];
      double profLng = doc['longitude'];

      // ✅ Distance calculation
      double distance = Geolocator.distanceBetween(
        studentPos.latitude,
        studentPos.longitude,
        profLat,
        profLng,
      );

      if (distance > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are not within 30m range")),
        );
        return;
      }

      // ✅ Mark attendance
      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(doc.id)
          .update({
        'students': FieldValue.arrayUnion([uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance marked successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void viewMonthlyAttendance() {
    // Placeholder: you can implement monthly attendance fetch here
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Monthly attendance feature")));
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
              onPressed: () => setState(() => showOtpField = true),
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