import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'exceptions.dart';

/// Base domain failure representing a typed error in application state or logic.
@immutable
abstract class AppFailure {
  final String message;
  final String? code;
  final dynamic details;

  const AppFailure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';

  /// Maps any caught exception or error to a standardized domain [AppFailure].
  factory AppFailure.fromException(dynamic error) {
    if (error is AppFailure) {
      return error;
    }

    if (error is NetworkException) {
      return NetworkFailure(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }

    if (error is AuthException) {
      return AuthFailure(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }

    if (error is NotFoundException) {
      return NotFoundFailure(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }

    if (error is ValidationException) {
      return ValidationFailure(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }

    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }

    // Supabase Specific Exceptions
    if (error is supabase.AuthException) {
      return AuthFailure(
        message: error.message,
        code: error.statusCode,
        details: error,
      );
    }

    if (error is supabase.PostgrestException) {
      if (error.code == 'PGRST116') {
        return NotFoundFailure(
          message: error.message,
          code: error.code,
          details: error.details,
        );
      }
      return ServerFailure(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }

    // Default Fallback
    return ServerFailure(
      message: error?.toString() ?? 'An unexpected error occurred.',
      code: 'UNKNOWN_ERROR',
      details: error,
    );
  }
}

/// Represents network connectivity or timeout issues.
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Unable to connect to server. Please check your internet connection.',
    super.code = 'NETWORK_FAILURE',
    super.details,
  });
}

/// Represents authentication, authorization, or token expiration issues.
class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_FAILURE',
    super.details,
  });
}

/// Represents an entity that does not exist in local or remote storage.
class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'The requested resource could not be found.',
    super.code = 'NOT_FOUND_FAILURE',
    super.details,
  });
}

/// Represents an internal database or remote server failure.
class ServerFailure extends AppFailure {
  const ServerFailure({
    super.message = 'An unexpected server error occurred. Please try again.',
    super.code = 'SERVER_FAILURE',
    super.details,
  });
}

/// Represents client-side input validation failures.
class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_FAILURE',
    super.details,
  });
}
