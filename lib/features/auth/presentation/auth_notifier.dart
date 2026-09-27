import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../data/auth_repository.dart';

/// UI state for authentication operations.
class AuthUiState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier handling authentication actions and feedback state.
class AuthNotifier extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Clears any active error or success feedback.
  void clearFeedback() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Signs in a user using email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected authentication error occurred.',
      );
      return false;
    }
  }

  /// Registers a new user account.
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      final hasSession = response.session != null;
      final message = hasSession
          ? 'Account created successfully!'
          : 'Account created! Please check your email to confirm your account.';

      state = state.copyWith(isLoading: false, successMessage: message);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected signup error occurred.',
      );
      return false;
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.signOut();
      state = state.copyWith(isLoading: false);
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred while signing out.',
      );
    }
  }
}

/// Riverpod provider exposing [AuthNotifier] and [AuthUiState].
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthUiState>(() {
  return AuthNotifier();
});
