import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/student_controller.dart';

class EnterOtpScreen extends ConsumerStatefulWidget {
  const EnterOtpScreen({super.key});

  @override
  ConsumerState<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends ConsumerState<EnterOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  OtpSubmitResult? _lastResult;
  String _otp = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the 6-digit OTP'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    final result = await ref
        .read(studentControllerProvider)
        .submitOtp(
          otp: _otp,
          studentId: user.uid,
          studentName: user.name,
        );

    setState(() {
      _isLoading = false;
      _lastResult = result;
    });
  }

  String _resultMessage(OtpSubmitResult result) {
    switch (result) {
      case OtpSubmitResult.success:
        return '🎉 Attendance marked successfully!';
      case OtpSubmitResult.invalidOtp:
        return '❌ Invalid OTP. Please check and try again.';
      case OtpSubmitResult.expired:
        return '⏰ This OTP has expired. Ask your teacher to generate a new one.';
      case OtpSubmitResult.outOfRange:
        return '📍 You are too far from the teacher (>20m). Move closer and try again.';
      case OtpSubmitResult.locationError:
        return '🛰️ Could not get your location. Please enable location access.';
      case OtpSubmitResult.alreadyMarked:
        return '✅ You have already marked attendance for this session.';
      case OtpSubmitResult.error:
        return '⚠️ Something went wrong. Please try again.';
    }
  }

  Color _resultColor(OtpSubmitResult result) {
    switch (result) {
      case OtpSubmitResult.success:
      case OtpSubmitResult.alreadyMarked:
        return AppTheme.accentGreen;
      case OtpSubmitResult.outOfRange:
      case OtpSubmitResult.locationError:
        return AppTheme.accentOrange;
      default:
        return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [AppTheme.accentCyan, AppTheme.accentGreen],
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
                        'Mark Attendance',
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
                      const SizedBox(height: 40),
                      // Animated fingerprint icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accentCyan.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.accentCyan.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppTheme.accentCyan,
                          size: 52,
                        ),
                      )
                          .animate(
                              onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                              end: 1.08,
                              duration: 2000.ms,
                              curve: Curves.easeInOut)
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 24),
                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the 6-digit OTP provided\nby your teacher',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 40),
                      // PIN Input
                      GlassCard(
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          onChanged: (v) => setState(() => _otp = v),
                          onCompleted: (_) => _submit(),
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.scale,
                          animationDuration:
                              const Duration(milliseconds: 200),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 58,
                            fieldWidth: 46,
                            activeFillColor:
                                AppTheme.accentCyan.withOpacity(0.15),
                            inactiveFillColor: AppTheme.glassWhite,
                            selectedFillColor:
                                AppTheme.accentCyan.withOpacity(0.1),
                            activeColor: AppTheme.accentCyan,
                            inactiveColor: AppTheme.glassBorder,
                            selectedColor: AppTheme.accentCyan,
                          ),
                          enableActiveFill: true,
                          textStyle: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      // Result feedback
                      if (_lastResult != null)
                        GlassCard(
                          backgroundColor:
                              _resultColor(_lastResult!).withOpacity(0.1),
                          borderColor:
                              _resultColor(_lastResult!).withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                _lastResult == OtpSubmitResult.success ||
                                        _lastResult ==
                                            OtpSubmitResult.alreadyMarked
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: _resultColor(_lastResult!),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _resultMessage(_lastResult!),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _resultColor(_lastResult!),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                      if (_lastResult != null)
                        const SizedBox(height: 16),
                      if (_lastResult != OtpSubmitResult.success)
                        GradientButton(
                          label: 'Submit OTP',
                          colors: AppTheme.studentGradient,
                          icon: Icons.check_rounded,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _submit,
                        ).animate(delay: 400.ms).fadeIn(),
                      if (_lastResult == OtpSubmitResult.success) ...[
                        GlassCard(
                          backgroundColor:
                              AppTheme.accentGreen.withOpacity(0.1),
                          borderColor:
                              AppTheme.accentGreen.withOpacity(0.3),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.celebration_rounded,
                                color: AppTheme.accentGreen,
                                size: 40,
                              )
                                  .animate()
                                  .scale(
                                      begin: const Offset(0.5, 0.5),
                                      curve: Curves.elasticOut)
                                  .fadeIn(),
                              const SizedBox(height: 12),
                              const Text(
                                'Attendance Marked!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Your presence has been recorded for this session.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().scale(
                            begin: const Offset(0.9, 0.9),
                            curve: Curves.elasticOut),
                      ],
                      const SizedBox(height: 32),
                      // Proximity note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar_rounded,
                              color: AppTheme.textMuted, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Must be within 20m of teacher',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
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
