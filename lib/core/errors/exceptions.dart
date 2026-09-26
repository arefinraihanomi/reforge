/// Base class for all data-level application exceptions.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Thrown when a network connectivity or HTTP transport error occurs.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection failed. Please check your internet connection.',
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

/// Thrown when authentication or session authorization fails.
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

/// Thrown when a requested resource (Idea, Project, Post-Mortem) is not found.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.details,
  });
}

/// Thrown when a remote server or database operation returns an unhandled error.
class ServerException extends AppException {
  const ServerException({
    super.message = 'A server error occurred. Please try again later.',
    super.code = 'SERVER_ERROR',
    super.details,
  });
}

/// Thrown when user input violates validation constraints.
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}
