import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/text_field.dart';
import '../controllers/auth_controller.dart';
import '../../../shared/models/user_model.dart';

class TeacherLoginScreen extends ConsumerStatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  ConsumerState<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen> {
  bool _isRegistering = false;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    UserModel? user;

    if (_isRegistering) {
      user = await notifier.registerTeacher(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        department: _deptCtrl.text.trim(),
      );
    } else {
      user = await notifier.loginTeacher(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.when(
      data: (_) {
        if (user != null) context.go(AppRoutes.teacherDashboard);
      },
      error: (e, _) => _showError(e.toString()),
      loading: () {},
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isRegistering ? 'Create Teacher Account' : 'Teacher Login',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegistering
                        ? 'Register with your college email'
                        : 'Sign in to manage your classes',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 36),
                  GlassCard(
                    child: Column(
                      children: [
                        if (_isRegistering) ...[
                          AppTextField(
                            label: 'Full Name',
                            controller: _nameCtrl,
                            prefixIcon: Icons.person_rounded,
                            validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Department',
                            controller: _deptCtrl,
                            prefixIcon: Icons.business_rounded,
                            validator: (v) =>
                            v!.isEmpty ? 'Department is required' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppTextField(
                          label: 'College Email',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            final domain = v.split('@').last.toLowerCase();
                            const blocked = [
                              'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'
                            ];
                            if (blocked.contains(domain)) {
                              return 'Use your college/institutional email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          prefixIcon: Icons.lock_rounded,
                          isPassword: true,
                          validator: (v) => v!.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          text: _isRegistering ? 'Create Account' : 'Sign In',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                          icon: _isRegistering
                              ? Icons.person_add_rounded
                              : Icons.login_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _isRegistering = !_isRegistering),
                      child: Text(
                        _isRegistering
                            ? 'Already have an account? Sign In'
                            : "Don't have an account? Register",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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