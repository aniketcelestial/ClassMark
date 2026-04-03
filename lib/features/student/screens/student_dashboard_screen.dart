import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/controllers/auth_controller.dart';
import 'enter_otp_screen.dart';
import 'monthly_attendance_screen.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [
          AppTheme.accentCyan,
          AppTheme.accentGreen,
          AppTheme.primaryBlue,
        ],
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            user?.name ?? 'Student',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 14,
                      onTap: () async {
                        await ref
                            .read(currentUserProvider.notifier)
                            .signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.roleSelect,
                            (route) => false,
                          );
                        }
                      },
                      child: const Icon(Icons.logout_rounded,
                          color: AppTheme.textSecondary, size: 22),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              // Roll / class chip
              if (user?.rollNumber != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.accentCyan.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Roll: ${user!.rollNumber} · ${user.className ?? ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 16),
                      _ActionCard(
                        title: 'Mark Attendance',
                        description:
                            'Enter the OTP shared by your teacher to mark your presence',
                        icon: Icons.fingerprint_rounded,
                        colors: AppTheme.studentGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EnterOtpScreen()),
                        ),
                        delay: 300,
                      ),
                      const SizedBox(height: 16),
                      _ActionCard(
                        title: 'My Attendance',
                        description:
                            'Check your monthly attendance records and percentage',
                        icon: Icons.calendar_month_rounded,
                        colors: [
                          AppTheme.primaryPurple,
                          AppTheme.primaryBlue,
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const MonthlyAttendanceScreen()),
                        ),
                        delay: 400,
                      ),
                      const SizedBox(height: 32),
                      // Info card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: AppTheme.accentCyan,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Proximity Verification',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Attendance is only accepted when you are physically within 20 meters of your teacher. This prevents proxy attendance.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 500.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final int delay;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: GlassCard(
          borderColor: widget.colors.first.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: widget.colors.first.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ],
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: widget.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colors.first.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.colors.first.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1);
  }
}
