import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/teacher_controller.dart';
import 'generate_otp_screen.dart';
import 'present_students_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref
            .read(activeSessionProvider.notifier)
            .loadActiveSession(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeSession = ref.watch(activeSessionProvider);

    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [AppTheme.primaryBlue, AppTheme.primaryPurple],
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
                            user?.name ?? 'Teacher',
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
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              // Subject / class chip
              if (user?.subject != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${user!.subject} · ${user.className ?? ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
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
                      // Active session banner
                      if (activeSession != null && !activeSession.isExpired)
                        _ActiveSessionBanner(session: activeSession)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.1),
                      if (activeSession != null && !activeSession.isExpired)
                        const SizedBox(height: 24),
                      // Section title
                      const Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 16),
                      // Action cards
                      _ActionCard(
                        title: 'Generate OTP',
                        description:
                            'Create a proximity-locked attendance session for your class',
                        icon: Icons.generating_tokens_rounded,
                        colors: AppTheme.teacherGradient,
                        badge: activeSession != null ? 'ACTIVE' : null,
                        badgeColor: AppTheme.accentGreen,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GenerateOtpScreen()),
                        ),
                        delay: 300,
                      ),
                      const SizedBox(height: 16),
                      _ActionCard(
                        title: 'Present Students',
                        description:
                            'View students who have marked attendance in the active session',
                        icon: Icons.how_to_reg_rounded,
                        colors: [
                          AppTheme.accentCyan,
                          AppTheme.accentGreen,
                        ],
                        badge: activeSession != null
                            ? 'LIVE'
                            : null,
                        badgeColor: AppTheme.accentCyan,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const PresentStudentsScreen()),
                        ),
                        delay: 400,
                      ),
                      const SizedBox(height: 32),
                      // Info Section
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'How it works',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                                icon: Icons.location_on_rounded,
                                text:
                                    'Your location is captured when OTP is generated'),
                            _InfoRow(
                                icon: Icons.radar_rounded,
                                text:
                                    'Students must be within 20m radius to mark attendance'),
                            _InfoRow(
                                icon: Icons.timer_rounded,
                                text:
                                    'OTP expires after 10 minutes automatically'),
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

class _ActiveSessionBanner extends StatelessWidget {
  final dynamic session;
  const _ActiveSessionBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
      borderColor: AppTheme.accentGreen.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentGreen,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(end: 1.5, duration: 800.ms)
              .then()
              .scaleXY(end: 1.0, duration: 800.ms),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Active',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'OTP: ${session.otp}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.accentGreen,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  final int delay;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    this.badge,
    this.badgeColor,
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
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.badgeColor!.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      widget.badgeColor!.withOpacity(0.4)),
                            ),
                            child: Text(
                              widget.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: widget.badgeColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
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
    ).animate(delay: Duration(milliseconds: widget.delay)).fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
