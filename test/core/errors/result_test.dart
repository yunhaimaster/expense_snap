import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Result.success', () {
      test('should create success result with data', () {
        final result = Result.success(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result, isA<Success<int>>());
        expect((result as Success<int>).data, equals(42));
      });

      test('should work with complex types', () {
        final data = {'key': 'value', 'number': 123};
        final result = Result.success(data);

        expect(result.isSuccess, isTrue);
        expect((result as Success).data, equals(data));
      });

      test('should work with nullable types', () {
        // 測試 Result<String?> 可以成功儲存 null
        final result = Result<String?>.success(null);

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNull);
      });
    });

    group('Result.failure', () {
      test('should create failure result with error', () {
        final error = ValidationException.required('name');
        final result = Result<int>.failure(error);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result, isA<Failure<int>>());
        expect((result as Failure<int>).error, equals(error));
      });
    });

    group('fold', () {
      test('should call onSuccess for success result', () {
        final result = Result.success(10);

        final value = result.fold(
          onFailure: (error) => -1,
          onSuccess: (data) => data * 2,
        );

        expect(value, equals(20));
      });

      test('should call onFailure for failure result', () {
        final result = Result<int>.failure(
          const NetworkException('No connection'),
        );

        final value = result.fold(
          onFailure: (error) => -1,
          onSuccess: (data) => data * 2,
        );

        expect(value, equals(-1));
      });
    });

    group('getOrNull', () {
      test('should return data for success', () {
        final result = Result.success('test');
        expect(result.getOrNull(), equals('test'));
      });

      test('should return null for failure', () {
        final result = Result<String>.failure(
          const StorageException('Error'),
        );
        expect(result.getOrNull(), isNull);
      });
    });

    group('getOrElse', () {
      test('should return data for success', () {
        final result = Result.success(100);
        expect(result.getOrElse(0), equals(100));
      });

      test('should return default value for failure', () {
        final result = Result<int>.failure(
          const DatabaseException('Error'),
        );
        expect(result.getOrElse(0), equals(0));
      });
    });

    group('getOrThrow', () {
      test('should return data for success', () {
        final result = Result.success('value');
        expect(result.getOrThrow(), equals('value'));
      });

      test('should throw error for failure', () {
        final error = AuthException.notSignedIn();
        final result = Result<String>.failure(error);

        expect(result.getOrThrow, throwsA(equals(error)));
      });
    });

    group('map', () {
      test('should transform success data', () {
        final result = Result.success(5);
        final mapped = result.map((data) => data.toString());

        expect(mapped.isSuccess, isTrue);
        expect(mapped.getOrNull(), equals('5'));
      });

      test('should propagate failure', () {
        const error = ExportException('Error');
        final result = Result<int>.failure(error);
        final mapped = result.map((data) => data.toString());

        expect(mapped.isFailure, isTrue);
        expect((mapped as Failure<String>).error, equals(error));
      });
    });

    group('onSuccess', () {
      test('should execute action for success', () {
        var executed = false;
        final result = Result.success(42);

        result.onSuccess((data) {
          executed = true;
          expect(data, equals(42));
        });

        expect(executed, isTrue);
      });

      test('should not execute action for failure', () {
        var executed = false;
        final result = Result<int>.failure(
          const NetworkException('Error'),
        );

        result.onSuccess((data) {
          executed = true;
        });

        expect(executed, isFalse);
      });
    });

    group('onFailure', () {
      test('should execute action for failure', () {
        var executed = false;
        final result = Result<int>.failure(
          const NetworkException('Error'),
        );

        result.onFailure((error) {
          executed = true;
          expect(error, isA<NetworkException>());
        });

        expect(executed, isTrue);
      });

      test('should not execute action for success', () {
        var executed = false;
        final result = Result.success(42);

        result.onFailure((error) {
          executed = true;
        });

        expect(executed, isFalse);
      });
    });
  });
}
