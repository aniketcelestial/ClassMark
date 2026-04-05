import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [
          AppTheme.primaryBlue,
          AppTheme.primaryPurple,
          AppTheme.accentCyan,
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: AppTheme.teacherGradient,
                            ),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ClassMark',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 40),
                    const Text(
                      'Who are\nyou today?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    const Text(
                      'Choose your role to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 500.ms),
                  ],
                ),
                const SizedBox(height: 56),
                // Teacher Card
                _RoleCard(
                  title: 'Teacher',
                  subtitle: 'Generate OTP sessions\nand track attendance',
                  icon: Icons.cast_for_education_rounded,
                  gradientColors: AppTheme.teacherGradient,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.teacherLogin),
                  delay: 400,
                  tag: 'EDUCATOR',
                ),
                const SizedBox(height: 20),
                // Student Card
                _RoleCard(
                  title: 'Student',
                  subtitle: 'Mark attendance with OTP\nand view your records',
                  icon: Icons.person_rounded,
                  gradientColors: AppTheme.studentGradient,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.studentLogin),
                  delay: 500,
                  tag: 'LEARNER',
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Secure · Proximity-Verified · Real-time',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ).animate(delay: 700.ms).fadeIn(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final int delay;
  final String tag;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    required this.delay,
    required this.tag,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderColor: widget.gradientColors.first.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: widget.gradientColors.first.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors.first.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: widget.gradientColors
                                    .map((c) => c.withOpacity(0.2))
                                    .toList()),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  widget.gradientColors.first.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            widget.tag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: widget.gradientColors.first,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.gradientColors.first.withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.2, curve: Curves.easeOut);
  }
}
