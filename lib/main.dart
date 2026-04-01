import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/common/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    runApp(const MyApp());
  } catch (e) {
    // If Firebase fails to initialize, show error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Firebase initialization failed:\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
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