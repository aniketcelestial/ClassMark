import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/text_field.dart';
import '../controllers/teacher_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/services/ble_service.dart';

class GenerateOtpScreen extends ConsumerStatefulWidget {
  final UserModel teacher;
  const GenerateOtpScreen({super.key, required this.teacher});

  @override
  ConsumerState<GenerateOtpScreen> createState() => _GenerateOtpScreenState();
}

class _GenerateOtpScreenState extends ConsumerState<GenerateOtpScreen> {
  final _subjectCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<bool> _checkBlePermissions() async {
    final bleService = ref.read(bleServiceProvider);
    final status = await bleService.requestPermissions();

    if (status == BlePermissionStatus.permanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0D1530),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Bluetooth Permission Required',
                style: TextStyle(color: AppColors.textPrimary)),
            content: const Text(
              'Bluetooth permission is required so students can detect your device for proximity verification.\n\nGo to App Settings → Permissions → Nearby Devices and allow it.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text('Open Settings',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return status == BlePermissionStatus.granted;
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    final hasPermission = await _checkBlePermissions();
    if (!hasPermission) return;

    final session = await ref.read(teacherNotifierProvider.notifier).generateOtp(
      teacher: widget.teacher,
      subject: _subjectCtrl.text.trim(),
    );
    if (session != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherNotifierProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Generate OTP',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a session for your class',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Subject Name',
                          hint: 'e.g. Data Structures, Physics Lab',
                          controller: _subjectCtrl,
                          prefixIcon: Icons.book_rounded,
                          validator: (v) =>
                          v!.isEmpty ? 'Subject is required' : null,
                        ),
                        const SizedBox(height: 24),
                        // BLE Info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'BLE Proximity Active',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Students within 10m can mark attendance',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          text: 'Generate OTP',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _generate,
                          icon: Icons.generating_tokens_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'How it works',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 12),
                        _Tip(
                          icon: Icons.timer_rounded,
                          text: 'OTP expires in 10 minutes',
                        ),
                        SizedBox(height: 8),
                        _Tip(
                          icon: Icons.bluetooth_searching_rounded,
                          text: 'BLE verifies student is within 10m',
                        ),
                        SizedBox(height: 8),
                        _Tip(
                          icon: Icons.lock_rounded,
                          text: 'Each student can only mark once per session',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}