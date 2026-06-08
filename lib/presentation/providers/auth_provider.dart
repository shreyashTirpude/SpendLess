import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(AsyncValue.data(FirebaseAuth.instance.currentUser));

  Future<bool> loginWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password,
      );
      state = AsyncValue.data(result.user);
      return result.user != null;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Login failed', StackTrace.current);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      if (result.user != null && name.isNotEmpty) {
        await result.user!.updateDisplayName(name);
      }
      state = AsyncValue.data(result.user);
      return result.user != null;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Signup failed', StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }
}
