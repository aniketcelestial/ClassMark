import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/common/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(const MyApp());
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    runApp(const MyApp()); // Optional: still run app to show error screen
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClassMark',
      home: const RoleSelectionScreen(),
    );
  }
}