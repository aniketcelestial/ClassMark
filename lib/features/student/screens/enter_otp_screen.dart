import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../controllers/student_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class EnterOtpScreen extends ConsumerStatefulWidget {
  final UserModel student;
  const EnterOtpScreen({super.key, required this.student});

  @override
  ConsumerState<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends ConsumerState<EnterOtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _success = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_otp.length != AppConstants.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // For dev/testing: skip BLE if running in debug
    // Set skipBle: true to bypass BLE check during development
    final success = await ref.read(studentNotifierProvider.notifier).submitOtp(
      otp: _otp,
      student: widget.student,
      skipBle: false, // Set to true to bypass BLE during testing
    );

    if (success && mounted) {
      setState(() => _success = true);
    }
  }

  void _handleStateChange(StudentSubmitState state) {
    if (state.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
    } else if (state.isBluetoothOff) {
      _showBluetoothOffDialog();
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1530),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text(
              'Permission Required',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Bluetooth permission was permanently denied.\n\nTo mark attendance, go to App Settings → Permissions → Nearby Devices and allow it.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
              openAppSettings(); // permission_handler built-in
            },
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1530),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_rounded, color: AppColors.warning),
            SizedBox(width: 12),
            Text(
              'Bluetooth is Off',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Please turn on Bluetooth to verify that you are near your teacher. This is required to mark attendance.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Re-trigger submit which will auto turn on BT
              _submit();
            },
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentNotifierProvider);

    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _success
                ? _buildSuccess()
                : Column(
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
                  'Enter OTP',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ask your teacher for the 6-digit OTP',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),
                GlassCard(
                  child: Column(
                    children: [
                      // BLE scanning indicator
                      if (state.isScanning) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Verifying proximity via Bluetooth...',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // OTP Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          AppConstants.otpLength,
                              (index) => _OtpBox(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            onChanged: (val) =>
                                _onDigitEntered(index, val),
                            onBackspace: () {
                              if (_controllers[index].text.isEmpty &&
                                  index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        ),
                      ),

                      if (state.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      GradientButton(
                        text: state.isScanning
                            ? 'Scanning BLE...'
                            : 'Mark Attendance',
                        isLoading: state.isLoading,
                        onPressed:
                        (state.isLoading || _otp.length != 6)
                            ? null
                            : _submit,
                        icon: Icons.check_circle_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: const [
                      Icon(Icons.bluetooth_rounded,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Make sure Bluetooth is ON. You must be within 10m of your teacher\'s phone.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final session = ref.read(studentNotifierProvider).successSession;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF00A896)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 28),
          const Text(
            'Attendance Marked!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session?.subject ?? '',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          GradientButton(
            text: 'Back to Dashboard',
            onPressed: () {
              ref.read(studentNotifierProvider.notifier).clearSuccess();
              context.pop();
            },
            gradient: const LinearGradient(
              colors: [AppColors.success, Color(0xFF00A896)],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}