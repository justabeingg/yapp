import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Auth actions
final authProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.yapp.app://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
