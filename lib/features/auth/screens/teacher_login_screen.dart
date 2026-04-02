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

class TeacherLoginScreen extends ConsumerStatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  ConsumerState<TeacherLoginScreen> createState() =>
      _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Sign Up
  final _nameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
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
    _subjectCtrl.dispose();
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
      Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await ref.read(currentUserProvider.notifier).signUp(
      email: _signupEmailCtrl.text,
      password: _signupPasswordCtrl.text,
      name: _nameCtrl.text,
      role: 'teacher',
      subject: _subjectCtrl.text,
      className: _classCtrl.text,
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [
          AppTheme.primaryBlue,
          AppTheme.primaryPurple,
        ],
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
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
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'TEACHER',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryBlue,
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
                      // Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: AppTheme.teacherGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cast_for_education_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                          begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 20),
                      const Text(
                        'Teacher\nPortal',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 32),
                      // Tab bar
                      GlassCard(
                        padding: const EdgeInsets.all(4),
                        borderRadius: 14,
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: AppTheme.teacherGradient,
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
                      // Forms
                      SizedBox(
                        height: 420,
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
            hint: 'teacher@school.edu',
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
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passwordCtrl,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showResetDialog(),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GradientButton(
            label: 'Sign In',
            colors: AppTheme.teacherGradient,
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
              hint: 'Dr. John Smith',
              prefixIcon: Icons.badge_outlined,
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
              v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            ClassMarkTextField(
              label: 'Email',
              hint: 'teacher@school.edu',
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
              label: 'Subject',
              hint: 'Mathematics',
              prefixIcon: Icons.book_outlined,
              controller: _subjectCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
              v == null || v.isEmpty ? 'Subject is required' : null,
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
              colors: AppTheme.teacherGradient,
              icon: Icons.person_add_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signUp,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: ClassMarkTextField(
          label: 'Email',
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await ref
                  .read(currentUserProvider.notifier)
                  .resetPassword(ctrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error ?? 'Reset email sent!'),
                  backgroundColor:
                  error != null ? AppTheme.errorRed : AppTheme.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            },
            child: const Text('Send',
                style: TextStyle(color: AppTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }
}