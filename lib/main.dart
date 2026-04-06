import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/student_login_screen.dart';
import 'features/auth/screens/teacher_login_screen.dart';
import 'features/student/screens/enter_otp_screen.dart';
import 'features/student/screens/monthly_attendance_screen.dart';
import 'features/student/screens/student_dashboard_screen.dart';
import 'features/teacher/screens/generate_otp_screen.dart';
import 'features/teacher/screens/present_students_screen.dart';
import 'features/teacher/screens/teacher_dashboard_screen.dart';
import 'firebase_options.dart';
import 'shared/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Already initialized — safe to ignore
    appLogger.w('Firebase already initialized: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  appLogger.i('ClassMark App Starting...');
  runApp(const ProviderScope(child: ClassMarkApp()));
}

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.roleSelect,
      builder: (_, __) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: AppRoutes.teacherLogin,
      builder: (_, __) => const TeacherLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.studentLogin,
      builder: (_, __) => const StudentLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.teacherDashboard,
      builder: (context, state) {
        final user = state.extra as UserModel?;
        if (user != null) return TeacherDashboardScreen(teacher: user);
        return const _UserLoaderScreen(role: 'teacher');
      },
    ),
    GoRoute(
      path: AppRoutes.generateOtp,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return GenerateOtpScreen(teacher: user);
      },
    ),
    GoRoute(
      path: AppRoutes.presentStudents,
      builder: (context, state) {
        final sessionId = state.extra as String;
        return PresentStudentsScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: AppRoutes.studentDashboard,
      builder: (context, state) {
        final user = state.extra as UserModel?;
        if (user != null) return StudentDashboardScreen(student: user);
        return const _UserLoaderScreen(role: 'student');
      },
    ),
    GoRoute(
      path: AppRoutes.enterOtp,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return EnterOtpScreen(student: user);
      },
    ),
    GoRoute(
      path: AppRoutes.monthlyAttendance,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return MonthlyAttendanceScreen(student: user);
      },
    ),
  ],
);

class ClassMarkApp extends StatelessWidget {
  const ClassMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClassMark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

class _UserLoaderScreen extends ConsumerWidget {
  final String role;
  const _UserLoaderScreen({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.go(AppRoutes.roleSelect),
          );
          return const SplashScreen();
        }
        if (role == 'teacher') {
          return TeacherDashboardScreen(teacher: user);
        }
        return StudentDashboardScreen(student: user);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.go(AppRoutes.roleSelect),
        );
        return const SplashScreen();
      },
    );
  }
}