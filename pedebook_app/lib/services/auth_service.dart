import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';

class AuthService {
  static final SupabaseClient _supabase = SupabaseService.client;

  static User? get currentAuthUser => _supabase.auth.currentUser;
  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Google OAuth
  static Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'https://www.pedebook.com/auth/callback',
    );
  }

  /// Sign up with email, password, and display name
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': displayName.trim()},
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Update user profile metadata
  static Future<UserResponse> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    return await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': displayName.trim(),
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ),
    );
  }

  /// Fetch user profile from Supabase 'profiles' table
  static Future<AppUser?> getUserProfile() async {
    final user = currentAuthUser;
    if (user == null) return null;

    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        return AppUser.fromSupabase(res);
      }
    } catch (_) {}

    // Fallback based on auth metadata
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'] ??
          user.email?.split('@').first ??
          'ผู้ใช้งาน',
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }
}
