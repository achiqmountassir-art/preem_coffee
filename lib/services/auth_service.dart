import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_tables.dart';

/// Admin-only Supabase Auth helpers (customer stays anonymous).
class AuthService {
  AuthService({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final row = await _supabase
        .from(SupabaseTables.adminUsers)
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();
    return row != null;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _supabase.auth.signOut();
}
