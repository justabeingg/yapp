import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the full auth state of the app
enum AppAuthStatus {
  loading,        // Still checking — show nothing
  unauthenticated, // No session — show login
  authenticated,  // Logged in, has profile — show feed
  needsProfile,   // Logged in, no profile — show username picker
}

/// Single source of truth for auth + profile state.
/// Created once, never recreated.
/// GoRouter listens to this via ChangeNotifier.
class AppAuthNotifier extends ChangeNotifier {
  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _authSubscription;

  AppAuthStatus _status = AppAuthStatus.loading;
  AppAuthStatus get status => _status;

  AppAuthNotifier(this._client) {
    // Check current session immediately on startup
    _checkStatus();

    // Listen to all future auth changes (login, logout, token refresh)
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      _updateStatus(AppAuthStatus.unauthenticated);
      return;
    }

    // User is logged in — check if profile exists
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _updateStatus(AppAuthStatus.authenticated);
      } else {
        _updateStatus(AppAuthStatus.needsProfile);
      }
    } catch (_) {
      // If profile check fails, assume needs profile
      _updateStatus(AppAuthStatus.needsProfile);
    }
  }

  /// Call this after saving profile to immediately update state
  Future<void> profileSaved() async {
    await _checkStatus();
  }

  void _updateStatus(AppAuthStatus newStatus) {
    if (_status == newStatus) return; // No change — don't notify
    _status = newStatus;
    notifyListeners(); // Tell the router to re-evaluate redirect
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
