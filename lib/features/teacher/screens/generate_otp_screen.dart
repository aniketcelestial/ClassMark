import 'dart:async';
import 'package:classmark/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classmark/core/theme/app_theme.dart';
import 'package:classmark/shared/widgets/animated_bg.dart';
import 'package:classmark/shared/widgets/glass_card.dart';
import 'package:classmark/shared/widgets/gradient_button.dart';
import 'package:classmark/features/auth/controllers/auth_controller.dart';
import 'package:classmark/features/teacher/controllers/teacher_controller.dart';

class GenerateOtpScreen extends ConsumerStatefulWidget {
  const GenerateOtpScreen({super.key});

  @override
  ConsumerState<GenerateOtpScreen> createState() => _GenerateOtpScreenState();
}

class _GenerateOtpScreenState extends ConsumerState<GenerateOtpScreen> {
  bool _isGenerating = false;
  String _loadingStep = '';
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  String? _lastError;

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
    _secondsLeft = expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 999);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = expiresAt.difference(DateTime.now()).inSeconds;
      if (!mounted) { timer.cancel(); return; }
      setState(() => _secondsLeft = left < 0 ? 0 : left);
      if (left <= 0) {
        timer.cancel();
        ref.read(activeSessionProvider.notifier).deactivateSession();
      }
    });
  }

  Future<void> _generateOtp(UserModel user) async {
    debugPrint('>>> _generateOtp() ENTERED');

    debugPrint(
        '>>> user=${user.name}, subject=${user.subject}, className=${user.className}');

    setState(() {
      _isGenerating = true;
      _lastError = null;
      _loadingStep = 'Requesting Bluetooth permission...';
    });

    final error = await ref
        .read(activeSessionProvider.notifier)
        .generateOtp(
      teacherId: user.uid,
      teacherName: user.name,
      subject: user.subject ?? 'General',
      className: user.className ?? 'Class',
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isGenerating = false;
        _loadingStep = '';
        _lastError = error;
      });
    } else {
      setState(() {
        _isGenerating = false;
        _loadingStep = '';
        _lastError = null;
      });

      final session = ref.read(activeSessionProvider);

      if (session != null) {
        _startCountdown(session.expiresAt);
      }
    }
  }

  String get _timerDisplay {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _timerProgress =>
      (_secondsLeft / (10 * 60)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    final user = ref.watch(currentUserProvider);
    final hasActive =
        session != null && !session.isExpired && _secondsLeft > 0;

    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [AppTheme.primaryBlue, AppTheme.primaryPurple],
        child: SafeArea(
          child: Column(
            children: [
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
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // ── Error banner ──────────────────────────────
                      if (_lastError != null)
                        GlassCard(
                          backgroundColor:
                              AppTheme.errorRed.withOpacity(0.12),
                          borderColor:
                              AppTheme.errorRed.withOpacity(0.4),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppTheme.errorRed, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _lastError!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.errorRed,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: -0.1),

                      if (_lastError != null) const SizedBox(height: 20),

                      // ── Active session ────────────────────────────
                      if (hasActive) ...[
                        _OtpDisplay(
                          otp: session.otp,
                          timerDisplay: _timerDisplay,
                          timerProgress: _timerProgress,
                          secondsLeft: _secondsLeft,
                        ),
                        const SizedBox(height: 20),
                        GlassCard(
                          child: Column(
                            children: [
                              _Row(Icons.book_outlined, 'Subject',
                                  session.subject),
                              const Divider(color: AppTheme.glassBorder),
                              _Row(Icons.groups_outlined, 'Class',
                                  session.className),
                              const Divider(color: AppTheme.glassBorder),
                              _Row(
                                Icons.bluetooth_rounded,
                                'BLE Proximity',
                                'Active — Students must be within ~20m',
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'Stop Session',
                          colors: [
                            AppTheme.errorRed,
                            const Color(0xFFFF6B6B)
                          ],
                          icon: Icons.stop_circle_outlined,
                          onPressed: () async {
                            _countdownTimer?.cancel();
                            await ref
                                .read(activeSessionProvider.notifier)
                                .deactivateSession();
                            setState(() => _secondsLeft = 0);
                          },
                        ),
                      ] else ...[
                        // ── No session ────────────────────────────
                        const SizedBox(height: 30),
                        _NoSessionPlaceholder(isLoading: _isGenerating),
                        const SizedBox(height: 32),

                        // Loading step indicator
                        if (_isGenerating)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(
                                    color: AppTheme.primaryBlue,
                                    strokeWidth: 2.5),
                                const SizedBox(height: 14),
                                Text(
                                  _loadingStep,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),

                        GradientButton(
                          label: user == null
                              ? 'Loading profile...'
                              : _isGenerating
                              ? 'Getting Location...'
                              : 'Generate OTP Session',
                          colors: AppTheme.teacherGradient,
                          icon: _isGenerating
                              ? null
                              : Icons.generating_tokens_rounded,
                          isLoading: _isGenerating,
                          onPressed: (_isGenerating || user == null)
                              ? null
                              : () {
                            debugPrint('>>> BUTTON PRESSED');
                            _generateOtp(user);
                          },
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: const [
                              _InfoRow(Icons.bluetooth_rounded, 'Your Bluetooth ID is captured when OTP is generated'),
                              _InfoRow(Icons.radar_rounded, 'Students must be within ~20 metres (BLE range) to mark attendance'),
                              _InfoRow(Icons.timer_outlined, 'OTP expires automatically after 10 minutes'),
                            ],
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

// ─── Sub-widgets ────────────────────────────────────────────────────────────

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
              const Text('Session OTP',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: 20),
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
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(digit,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  color: isUrgent
                      ? AppTheme.errorRed
                      : AppTheme.textSecondary,
                  size: 16),
              const SizedBox(width: 6),
              Text(
                'Expires in $timerDisplay',
                style: TextStyle(
                    fontSize: 13,
                    color: isUrgent
                        ? AppTheme.errorRed
                        : AppTheme.textSecondary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: otp));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('OTP copied!'),
                    duration: Duration(seconds: 1),
                  ));
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
                      Text('Copy',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
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
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.accentGreen),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(end: 1.6, duration: 700.ms)
              .then()
              .scaleXY(end: 1.0, duration: 700.ms),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _NoSessionPlaceholder extends StatelessWidget {
  final bool isLoading;
  const _NoSessionPlaceholder({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue.withOpacity(0.1),
              border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: const Icon(Icons.generating_tokens_rounded,
                color: AppTheme.primaryBlue, size: 36),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.08, duration: 2000.ms, curve: Curves.easeInOut),
          const SizedBox(height: 20),
          const Text(
            'No Active Session',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            isLoading
                ? 'Fetching — this may take up to 20 seconds...'
                : 'Tap the button below to start an attendance session.\nMake sure Bluetooth is enabled on this device.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4)),
        ),
      ],
    );
  }
}
