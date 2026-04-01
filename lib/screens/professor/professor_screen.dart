import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classmark/widgets/custom_button.dart';
import 'package:classmark/services/firebase_helper.dart';
import 'package:geolocator/geolocator.dart';

class ProfessorScreen extends StatefulWidget {
  const ProfessorScreen({super.key});

  @override
  _ProfessorScreenState createState() => _ProfessorScreenState();
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
      // ✅ Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled");
      }

      // ✅ Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied");
      }

      // ✅ Get more accurate location (2 readings)
      Future<Position> getAccurateLocation() async {
        Position pos1 = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        await Future.delayed(const Duration(seconds: 1));

        Position pos2 = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        return pos1.accuracy < pos2.accuracy ? pos1 : pos2;
      }

      Position? position = await safeGetLocation(context);
      if (position == null) return;

      // ❌ Reject poor accuracy
      if (position.accuracy > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Low GPS accuracy. Try again.")),
        );
        return;
      }

      // ❌ Reject mock location
      if (position.isMocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fake location detected")),
        );
        return;
      }

      // ✅ Generate OTP
      String otp = generateOTP();

      // ✅ Store in Firestore
      await FirebaseFirestore.instance.collection('attendance_sessions').add({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'students': [],
      });

      setState(() => generatedOtp = otp);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP generated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void viewPresentStudents() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("View Present Students feature")));
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
              Text("Your OTP is:", style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(
                generatedOtp,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
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