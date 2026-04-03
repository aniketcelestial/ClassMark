import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classmark/shared/models/user_model.dart';
import 'package:classmark/shared/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>(
  (ref) => CurrentUserNotifier(ref.read(authServiceProvider)),
);

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      state = await _authService.getUserData(firebaseUser.uid);
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signIn(email: email, password: password);
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
