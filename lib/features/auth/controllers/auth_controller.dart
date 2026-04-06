import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUserModel();
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<UserModel?> registerTeacher({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.registerTeacher(
        name: name, email: email, password: password, department: department,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<UserModel?> registerStudent({
    required String name,
    required String email,
    required String password,
    required String enrollmentNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.registerStudent(
        name: name, email: email, password: password,
        enrollmentNumber: enrollmentNumber,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<UserModel?> loginTeacher({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginTeacher(email: email, password: password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<UserModel?> loginStudent({
    required String enrollmentNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginStudent(
        enrollmentNumber: enrollmentNumber, password: password,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});