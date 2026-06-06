import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(AsyncValue.data(Supabase.instance.client.auth.currentUser));

  Future<void> sendPhoneOtp(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signInWithOtp(phone: '+91$phone');
      return state.value;
    });
  }

  Future<bool> verifyPhoneOtp(String phone, String token) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: '+91$phone',
        token: token,
        type: OtpType.sms,
      );
      return response.user;
    });

    state = result.whenData((user) => user);
    return result.hasValue && result.value != null;
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      return response.user;
    });

    state = result.whenData((user) => user);
    return result.hasValue && result.value != null;
  }

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'name': name})
            .eq('id', response.user!.id);
      }
      return response.user;
    });

    state = result.whenData((user) => user);
    return result.hasValue && result.value != null;
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncValue.data(null);
  }
}
