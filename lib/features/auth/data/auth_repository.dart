import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/supabase_client.dart';
import '../models/user_profile.dart';

/// Abstract contract for authentication and user profile data operations.
abstract interface class AuthRepository {
  /// Stream emitting changes to the authentication state.
  Stream<AuthState> get authStateChanges;

  /// The currently authenticated user, or null if unauthenticated.
  User? get currentUser;

  /// Returns the current active session, or null if unauthenticated.
  Session? getCurrentSession();

  /// Signs up a new user using email and password.
  ///
  /// Optionally passes [displayName] in user metadata to trigger profile population.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in an existing user using email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Signs out the currently authenticated user session.
  Future<void> signOut();

  /// Fetches the public [UserProfile] corresponding to [userId].
  Future<UserProfile> getProfile(String userId);

  /// Updates profile metadata for [userId] and returns the updated [UserProfile].
  Future<UserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  });
}

/// Supabase implementation of [AuthRepository].
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient client;

  SupabaseAuthRepository({required this.client});

  @override
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  @override
  User? get currentUser => client.auth.currentUser;

  @override
  Session? getCurrentSession() => client.auth.currentSession;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null && displayName.trim().isNotEmpty
            ? {'display_name': displayName.trim()}
            : null,
      );
      return response;
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<UserProfile> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (displayName != null) 'display_name': displayName.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }
}

/// Riverpod provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client: client);
});
