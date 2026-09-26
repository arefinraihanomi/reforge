import 'package:flutter_test/flutter_test.dart';
import 'package:reforge/core/errors/exceptions.dart';
import 'package:reforge/core/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('AppFailure & Exception Mapping Tests', () {
    test('NetworkException maps to NetworkFailure', () {
      const exception = NetworkException(
        message: 'No internet connection',
        code: 'NET_TIMEOUT',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, equals('No internet connection'));
      expect(failure.code, equals('NET_TIMEOUT'));
    });

    test('AuthException maps to AuthFailure', () {
      const exception = AuthException(
        message: 'Invalid email or password',
        code: 'INVALID_CREDENTIALS',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<AuthFailure>());
      expect(failure.message, equals('Invalid email or password'));
      expect(failure.code, equals('INVALID_CREDENTIALS'));
    });

    test('NotFoundException maps to NotFoundFailure', () {
      const exception = NotFoundException(
        message: 'Idea not found',
        code: 'IDEA_NOT_FOUND',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, equals('Idea not found'));
      expect(failure.code, equals('IDEA_NOT_FOUND'));
    });

    test('ValidationException maps to ValidationFailure', () {
      const exception = ValidationException(
        message: 'Project title cannot be empty',
        code: 'EMPTY_TITLE',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, equals('Project title cannot be empty'));
      expect(failure.code, equals('EMPTY_TITLE'));
    });

    test('ServerException maps to ServerFailure', () {
      const exception = ServerException(
        message: 'Internal database error',
        code: 'DB_ERROR',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, equals('Internal database error'));
      expect(failure.code, equals('DB_ERROR'));
    });

    test('Supabase AuthException maps to AuthFailure', () {
      const exception = supabase.AuthException(
        'User not found',
        statusCode: '404',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<AuthFailure>());
      expect(failure.message, equals('User not found'));
      expect(failure.code, equals('404'));
    });

    test('Supabase PostgrestException PGRST116 maps to NotFoundFailure', () {
      const exception = supabase.PostgrestException(
        message: 'JSON object requested, multiple (or no) rows returned',
        code: 'PGRST116',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, equals('PGRST116'));
    });

    test('Supabase PostgrestException other error codes map to ServerFailure', () {
      const exception = supabase.PostgrestException(
        message: 'Relation does not exist',
        code: '42P01',
      );

      final failure = AppFailure.fromException(exception);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, equals('42P01'));
    });

    test('Unhandled exception maps to fallback ServerFailure', () {
      final failure = AppFailure.fromException('Random unexpected error string');

      expect(failure, isA<ServerFailure>());
      expect(failure.message, equals('Random unexpected error string'));
      expect(failure.code, equals('UNKNOWN_ERROR'));
    });

    test('Passing an existing AppFailure returns the same instance', () {
      const original = NetworkFailure(message: 'Offline');
      final result = AppFailure.fromException(original);

      expect(result, same(original));
    });
  });
}
