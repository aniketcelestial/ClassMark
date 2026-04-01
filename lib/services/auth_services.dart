import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/professor/professor_screen.dart';
import '../screens/student/student_screen.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<User?> loginWithRetry(String email, String password) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        var result = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        return result.user;
      } catch (e) {
        attempts++;
        await Future.delayed(Duration(seconds: 2 * attempts)); // exponential backoff
        if (attempts >= 3) rethrow;
      }
    }
    return null;
  }

  Future<User?> signupWithRetry(String email, String password) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        var result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        return result.user;
      } catch (e) {
        attempts++;
        await Future.delayed(Duration(seconds: 2 * attempts)); // exponential backoff
        if (attempts >= 3) rethrow;
      }
    }
    return null;
  }

  Future<void> authenticate() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user;

      if (isLogin) {
        user = await loginWithRetry(email, password);
      } else {
        user = await signupWithRetry(email, password);

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': email,
            'role': widget.role,
          });
        }
      }

      if (user != null) {
        if (widget.role == "professor") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfessorScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login/Signup failed:\n$e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
            ElevatedButton(
              onPressed: isLoading ? null : authenticate,
              child: isLoading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(isLogin ? "Login" : "Signup"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin
                  ? "Create new account"
                  : "Already have an account"),
            ),
          ],
        ),
      ),
    );
  }
}