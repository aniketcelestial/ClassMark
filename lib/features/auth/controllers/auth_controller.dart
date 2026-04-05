import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authReadyProvider = StateProvider<bool>((ref) => false);

// Global cache — survives provider recreation during navigation
UserModel? _cachedUser;

final currentUserProvider =
StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref.read(authServiceProvider), ref);
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;
  final Ref _ref;

  CurrentUserNotifier(this._authService, this._ref) : super(_cachedUser) {
    // Start with cached user immediately — no flicker, no null state
    if (_cachedUser != null) {
      debugPrint('>>> Provider recreated, restored from cache: ${_cachedUser?.name}');
      _ref.read(authReadyProvider.notifier).state = true;
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    debugPrint('>>> AUTH INIT STARTED');
    try {
      final firebaseUser = await Future.any([
        FirebaseAuth.instance.authStateChanges().first,
        Future.delayed(const Duration(seconds: 8), () => null),
      ]);

      if (firebaseUser != null) {
        debugPrint('>>> Restoring session: ${firebaseUser.email}');
        try {
          final user = await _authService
              .getUserData(firebaseUser.uid)
              .timeout(const Duration(seconds: 6));
          state = user;
          _cachedUser = user;
          debugPrint('>>> Session restored: ${state?.name}, role=${state?.role}');
        } catch (e) {
          debugPrint('>>> getUserData failed: $e');
          state = null;
          _cachedUser = null;
        }
      } else {
        debugPrint('>>> No active session');
        state = null;
        _cachedUser = null;
      }
    } catch (e) {
      debugPrint('>>> Auth init error: $e');
      state = null;
    } finally {
      _ref.read(authReadyProvider.notifier).state = true;
      debugPrint('>>> authReady = true');
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signIn(email: email, password: password);
      state = user;
      _cachedUser = user;
      debugPrint('>>> signIn: ${user?.name}, role=${user?.role}');
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
      _cachedUser = user;
      debugPrint('>>> signUp: ${user.name}, role=${user.role}');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
    _cachedUser = null;
    debugPrint('>>> signed out, cache cleared');
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