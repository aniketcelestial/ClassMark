import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/teacher_controller.dart';

class GenerateOtpScreen extends ConsumerStatefulWidget {
  const GenerateOtpScreen({super.key});

  @override
  ConsumerState<GenerateOtpScreen> createState() => _GenerateOtpScreenState();
}

class _GenerateOtpScreenState extends ConsumerState<GenerateOtpScreen> {
  bool _isGenerating = false;
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    final session = ref.read(activeSessionProvider);
    if (session != null && !session.isExpired) {
      _startCountdown(session.expiresAt);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _secondsLeft = expiresAt.difference(DateTime.now()).inSeconds;
    if (_secondsLeft <= 0) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = expiresAt.difference(DateTime.now()).inSeconds;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft = left < 0 ? 0 : left);
      if (left <= 0) {
        timer.cancel();
        ref.read(activeSessionProvider.notifier).deactivateSession();
      }
    });
  }

  Future<void> _generateOtp() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isGenerating = true);
    final error = await ref.read(activeSessionProvider.notifier).generateOtp(
      teacherId: user.uid,
      teacherName: user.name,
      subject: user.subject ?? 'General',
      className: user.className ?? 'Class',
    );
    setState(() => _isGenerating = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } else {
      final session = ref.read(activeSessionProvider);
      if (session != null) _startCountdown(session.expiresAt);
    }
  }

  String get _timerDisplay {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _timerProgress => _secondsLeft / (10 * 60); // 10 min total

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    final hasActiveSession = session != null && !session.isExpired && _secondsLeft > 0;

    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [AppTheme.primaryBlue, AppTheme.primaryPurple],
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Generate OTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      if (hasActiveSession) ...[
                        // OTP Display
                        _OtpDisplay(
                          otp: session.otp,
                          timerDisplay: _timerDisplay,
                          timerProgress: _timerProgress,
                          secondsLeft: _secondsLeft,
                        ),
                        const SizedBox(height: 24),
                        // Session info
                        GlassCard(
                          child: Column(
                            children: [
                              _SessionInfo(
                                  icon: Icons.book_outlined,
                                  label: 'Subject',
                                  value: session.subject),
                              const Divider(color: AppTheme.glassBorder),
                              _SessionInfo(
                                  icon: Icons.groups_outlined,
                                  label: 'Class',
                                  value: session.className),
                              const Divider(color: AppTheme.glassBorder),
                              _SessionInfo(
                                  icon: Icons.location_on_outlined,
                                  label: 'Location',
                                  value:
                                  '${session.teacherLatitude.toStringAsFixed(4)}, ${session.teacherLongitude.toStringAsFixed(4)}'),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 20),
                        // Stop session
                        GradientButton(
                          label: 'Stop Session',
                          colors: [AppTheme.errorRed, const Color(0xFFFF6B6B)],
                          icon: Icons.stop_circle_outlined,
                          onPressed: () async {
                            _countdownTimer?.cancel();
                            await ref
                                .read(activeSessionProvider.notifier)
                                .deactivateSession();
                          },
                        ),
                      ] else ...[
                        // No active session
                        const SizedBox(height: 40),
                        _NoSessionPlaceholder(),
                        const SizedBox(height: 40),
                        GradientButton(
                          label: 'Generate OTP Session',
                          colors: AppTheme.teacherGradient,
                          icon: Icons.generating_tokens_rounded,
                          isLoading: _isGenerating,
                          onPressed: _isGenerating ? null : _generateOtp,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your current location will be captured.\nStudents within 20m can mark attendance.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
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

class _OtpDisplay extends StatelessWidget {
  final String otp;
  final String timerDisplay;
  final double timerProgress;
  final int secondsLeft;

  const _OtpDisplay({
    required this.otp,
    required this.timerDisplay,
    required this.timerProgress,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsLeft < 60;

    return GlassCard(
      backgroundColor: const Color(0x1A4F9DFF),
      borderColor: AppTheme.primaryBlue.withOpacity(0.4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Session OTP',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentGreen),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(end: 1.6, duration: 700.ms)
                        .then()
                        .scaleXY(end: 1.0, duration: 700.ms),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // OTP digits
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: otp.split('').map((digit) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 46,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.teacherGradient
                        .map((c) => c.withOpacity(0.2))
                        .toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Timer
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color:
                isUrgent ? AppTheme.errorRed : AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Expires in $timerDisplay',
                style: TextStyle(
                  fontSize: 13,
                  color: isUrgent
                      ? AppTheme.errorRed
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: otp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP copied!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded,
                          color: AppTheme.textSecondary, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: timerProgress,
              backgroundColor: AppTheme.glassWhite,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUrgent ? AppTheme.errorRed : AppTheme.primaryBlue,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.95, 0.95), curve: Curves.elasticOut);
  }
}

class _NoSessionPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue.withOpacity(0.1),
              border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.generating_tokens_rounded,
              color: AppTheme.primaryBlue,
              size: 36,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.08, duration: 2000.ms, curve: Curves.easeInOut),
          const SizedBox(height: 20),
          const Text(
            'No Active Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate an OTP to start an attendance session.\nStudents nearby can then mark their presence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _SessionInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SessionInfo(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}