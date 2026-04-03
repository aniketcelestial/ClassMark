import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/utils/logger.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Tracks whether the initial Firebase auth check is complete
final authReadyProvider = StateProvider<bool>((ref) => false);

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>(
  (ref) => CurrentUserNotifier(
    ref.read(authServiceProvider),
    ref,
  ),
);

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;
  final Ref _ref;

  CurrentUserNotifier(this._authService, this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Wait for Firebase Auth to emit its first event
      // This guarantees we know the real auth state before proceeding
      final firebaseUser = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );

      if (firebaseUser != null) {
        appLogger.i('Restoring session for: ${firebaseUser.email}');
        state = await _authService.getUserData(firebaseUser.uid);
        appLogger.i('Session restored: ${state?.name} (${state?.role})');
      } else {
        appLogger.i('No active session found');
        state = null;
      }
    } catch (e) {
      appLogger.e('Auth init error: $e');
      state = null;
    } finally {
      // Signal splash screen that auth check is complete regardless
      _ref.read(authReadyProvider.notifier).state = true;
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user =
          await _authService.signIn(email: email, password: password);
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? subject,
    String? rollNumber,
    String? className,
  }) async {
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        subject: subject,
        rollNumber: rollNumber,
        className: className,
      );
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
