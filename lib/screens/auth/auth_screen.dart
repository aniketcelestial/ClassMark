import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../professor/professor_screen.dart';
import '../student/student_screen.dart';
import 'package:classmark/widgets/custom_button.dart';
import 'package:classmark/services/firebase_helper.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;

  Future<void> authenticate() async {
    if (!await hasInternet()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No internet connection")));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await retry(() {
        if (isLogin) {
          return FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());
        } else {
          return FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());
        }
      });

      if (!isLogin) {
        await retry(() {
          return FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': emailController.text.trim(),
            'role': widget.role,
          });
        });
      }

      // Navigate to role-specific screen
      if (widget.role == "professor") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ProfessorScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => StudentScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login / Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: isLogin ? "Login" : "Signup",
              onPressed: authenticate,
              isLoading: isLoading,
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Create new account" : "Already have an account"),
            ),
          ],
        ),
      ),
    );
  }
}