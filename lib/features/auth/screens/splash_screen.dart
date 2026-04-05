import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(currentUserProvider);
    });
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final user = ref.read(currentUserProvider);

      if (user?.role == 'teacher') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.teacherDashboard,
        );
      } else if (user?.role == 'student') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentDashboard,
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.roleSelect,
        );
      }
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.roleSelect,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    // Watch authReady — when it flips to true, navigate
    final authReady = ref.watch(authReadyProvider);
    Future.delayed(const Duration(seconds: 4), () {
      if (!_navigated && mounted) {
        _navigate();
      }
    });


    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [
          AppTheme.primaryBlue,
          AppTheme.primaryPurple,
          AppTheme.accentCyan,
        ],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: AppTheme.teacherGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 52),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.elasticOut),

              const SizedBox(height: 28),

              // App name with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryPurple,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'ClassMark',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white, // overridden by shader
                    letterSpacing: -1,
                  ),
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut),

              const SizedBox(height: 8),

              const Text(
                'Smart Attendance, Simplified',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 64),

              // Show spinner while waiting for auth
              if (!authReady)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue.withOpacity(0.7),
                    ),
                  ),
                ).animate(delay: 800.ms).fadeIn()
              else
                const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
