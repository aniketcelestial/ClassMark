import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/text_field.dart';
import '../controllers/auth_controller.dart';

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() =>
      _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _classCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _rollCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await ref.read(currentUserProvider.notifier).signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await ref.read(currentUserProvider.notifier).signUp(
          email: _signupEmailCtrl.text,
          password: _signupPasswordCtrl.text,
          name: _nameCtrl.text,
          role: 'student',
          rollNumber: _rollCtrl.text,
          className: _classCtrl.text,
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [
          AppTheme.accentCyan,
          AppTheme.accentGreen,
        ],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentCyan),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'STUDENT',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentCyan,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: AppTheme.studentGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentCyan.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 36),
                      ).animate().fadeIn(duration: 400.ms).scale(
                          begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 20),
                      const Text(
                        'Student\nPortal',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 32),
                      GlassCard(
                        padding: const EdgeInsets.all(4),
                        borderRadius: 14,
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: AppTheme.studentGradient,
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Register'),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLoginForm(),
                            _buildSignUpForm(),
                          ],
                        ),
                      ),
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

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          ClassMarkTextField(
            label: 'Email',
            hint: 'student@school.edu',
            prefixIcon: Icons.email_outlined,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ClassMarkTextField(
            label: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passwordCtrl,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Sign In',
            colors: AppTheme.studentGradient,
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _login,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            ClassMarkTextField(
              label: 'Full Name',
              hint: 'Arjun Sharma',
              prefixIcon: Icons.badge_outlined,
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            ClassMarkTextField(
              label: 'Email',
              hint: 'student@school.edu',
              prefixIcon: Icons.email_outlined,
              controller: _signupEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            ClassMarkTextField(
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              controller: _signupPasswordCtrl,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            ClassMarkTextField(
              label: 'Roll Number',
              hint: 'CS-2024-001',
              prefixIcon: Icons.numbers_rounded,
              controller: _rollCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Roll number is required' : null,
            ),
            const SizedBox(height: 14),
            ClassMarkTextField(
              label: 'Class / Section',
              hint: '10-A',
              prefixIcon: Icons.groups_outlined,
              controller: _classCtrl,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Class is required' : null,
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Create Account',
              colors: AppTheme.studentGradient,
              icon: Icons.person_add_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signUp,
            ),
          ],
        ),
      ),
    );
  }
}
