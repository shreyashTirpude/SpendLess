import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_models.dart';

/// Exposes the current authenticated account and auth operations.
/// Backed by [AuthService] (local enterprise auth, Supabase when configured).
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthAccount?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthAccount?>> {
  AuthNotifier() : super(AsyncValue.data(AuthService.currentUser));

  AuthAccount? get account => state.valueOrNull;

  Future<AuthResult> login(String email, String password,
      {String? mfaCode}) async {
    state = const AsyncValue.loading();
    final res = await AuthService.login(
        email: email, password: password, mfaCode: mfaCode);
    state = AsyncValue.data(res.ok ? res.account : AuthService.currentUser);
    return res;
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    final res = await AuthService.signUp(
        name: name, email: email, password: password);
    state = AsyncValue.data(res.ok ? res.account : AuthService.currentUser);
    return res;
  }

  Future<AuthResult> requestReset(String email) =>
      AuthService.requestPasswordReset(email);

  Future<AuthResult> confirmReset(
          String email, String otp, String newPassword) =>
      AuthService.confirmPasswordReset(
          email: email, otp: otp, newPassword: newPassword);

  void refresh() => state = AsyncValue.data(AuthService.currentUser);

  Future<void> signOut() async {
    await AuthService.signOut();
    state = const AsyncValue.data(null);
  }
}

/// Convenience: the live account (auto-refreshes when authProvider changes).
final currentAccountProvider = Provider<AuthAccount?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
