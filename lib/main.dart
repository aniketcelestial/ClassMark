import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/teacher_login_screen.dart';
import 'features/auth/screens/student_login_screen.dart';
import 'features/teacher/screens/teacher_dashboard_screen.dart';
import 'features/teacher/screens/generate_otp_screen.dart';
import 'features/teacher/screens/present_students_screen.dart';
import 'features/student/screens/student_dashboard_screen.dart';
import 'features/student/screens/enter_otp_screen.dart';
import 'features/student/screens/monthly_attendance_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: ClassMarkApp(),
    ),
  );
}

class ClassMarkApp extends StatelessWidget {
  const ClassMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassMark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.roleSelect: (_) => const RoleSelectScreen(),
        AppRoutes.teacherLogin: (_) => const TeacherLoginScreen(),
        AppRoutes.studentLogin: (_) => const StudentLoginScreen(),
        AppRoutes.teacherDashboard: (_) => const TeacherDashboardScreen(),
        AppRoutes.generateOtp: (_) => const GenerateOtpScreen(),
        AppRoutes.presentStudents: (_) => const PresentStudentsScreen(),
        AppRoutes.studentDashboard: (_) => const StudentDashboardScreen(),
        AppRoutes.enterOtp: (_) => const EnterOtpScreen(),
        AppRoutes.monthlyAttendance: (_) => const MonthlyAttendanceScreen(),
      },
    );
  }
}
