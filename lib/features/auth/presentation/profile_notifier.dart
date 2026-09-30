import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/supabase_client.dart';
import '../data/auth_repository.dart';
import '../models/user_profile.dart';

/// Extended profile details state including UI feedback and technical preferences.
class UserProfileState {
  final UserProfile profile;
  final String title;
  final String bio;
  final List<String> techStack;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const UserProfileState({
    required this.profile,
    this.title = 'Senior System Architect & Forge Lead',
    this.bio = 'Building resilient software craft, minimalist architectures, and rapid MVP iterations.',
    this.techStack = const [
      'Flutter',
      'Dart',
      'Riverpod',
      'Supabase',
      'PostgreSQL',
      'Clean Architecture',
      'AI Logic',
    ],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    String? title,
    String? bio,
    List<String>? techStack,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      techStack: techStack ?? this.techStack,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Riverpod AsyncNotifier managing user profile data, updates, and craft preferences.
class ProfileNotifier extends AsyncNotifier<UserProfileState> {
  @override
  Future<UserProfileState> build() async {
    final authRepository = ref.watch(authRepositoryProvider);
    final user = authRepository.currentUser;

    if (user != null && SupabaseBootstrap.isInitialized) {
      try {
        final profile = await authRepository.getProfile(user.id);
        return UserProfileState(profile: profile);
      } catch (_) {
        // Fallback profile if row in DB does not exist yet for this auth user
        final displayName = user.userMetadata?['display_name'] as String? ??
            (user.email != null ? user.email!.split('@').first : 'Architect');
        final profile = UserProfile(
          id: user.id,
          displayName: displayName,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
        return UserProfileState(profile: profile);
      }
    }

    // Default local demo mode user profile
    final profile = UserProfile(
      id: 'local-user',
      displayName: user?.email?.split('@').first ?? 'Arefin Raihan',
      avatarUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    );

    return UserProfileState(profile: profile);
  }

  /// Updates display name, title, bio, and tech stack tags.
  Future<bool> updateProfile({
    required String displayName,
    String? title,
    String? bio,
    List<String>? techStack,
  }) async {
    final current = state.value;
    if (current == null) return false;

    state = AsyncValue.data(current.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    final authRepository = ref.read(authRepositoryProvider);
    final userId = current.profile.id;

    try {
      UserProfile updatedProfile = current.profile.copyWith(
        displayName: displayName.trim(),
        updatedAt: DateTime.now(),
      );

      if (SupabaseBootstrap.isInitialized && userId != 'local-user') {
        updatedProfile = await authRepository.updateProfile(
          userId: userId,
          displayName: displayName.trim(),
        );
      }

      state = AsyncValue.data(current.copyWith(
        profile: updatedProfile,
        title: title?.trim() ?? current.title,
        bio: bio?.trim() ?? current.bio,
        techStack: techStack ?? current.techStack,
        isLoading: false,
        successMessage: 'Profile updated successfully!',
      ));
      return true;
    } on AppFailure catch (e) {
      state = AsyncValue.data(current.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      state = AsyncValue.data(current.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile settings.',
      ));
      return false;
    }
  }

  /// Adds a tag to the user's primary tech stack.
  void addTechTag(String tag) {
    final current = state.value;
    if (current == null) return;
    final trimmed = tag.trim();
    if (trimmed.isEmpty || current.techStack.contains(trimmed)) return;

    final updatedStack = [...current.techStack, trimmed];
    state = AsyncValue.data(current.copyWith(techStack: updatedStack));
  }

  /// Removes a tag from the user's primary tech stack.
  void removeTechTag(String tag) {
    final current = state.value;
    if (current == null) return;

    final updatedStack = current.techStack.where((t) => t != tag).toList();
    state = AsyncValue.data(current.copyWith(techStack: updatedStack));
  }

  /// Clears active state feedback messages.
  void clearFeedback() {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(clearError: true, clearSuccess: true));
    }
  }
}

/// Provider for profile state.
final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfileState>(ProfileNotifier.new);
