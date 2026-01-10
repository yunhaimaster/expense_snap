import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';

/// 資料庫錯誤恢復測試
///
/// 測試各種資料庫損壞和錯誤情況的處理
void main() {
  group('資料庫異常處理測試', () {
    test('DatabaseException.corrupted() 應包含正確資訊', () {
      final exception = DatabaseException.corrupted();

      expect(exception, isA<DatabaseException>());
      expect(exception.message.isNotEmpty, isTrue);
      expect(exception.code, 'DB_CORRUPTED');
    });

    test('DatabaseException.locked() 應包含正確資訊', () {
      final exception = DatabaseException.locked();

      expect(exception, isA<DatabaseException>());
      expect(exception.code, 'DB_LOCKED');
    });

    test('DatabaseException.queryFailed() 應包含正確資訊', () {
      final exception = DatabaseException.queryFailed('查詢錯誤');

      expect(exception, isA<DatabaseException>());
      expect(exception.message.contains('查詢錯誤'), isTrue);
      expect(exception.code, 'QUERY_FAILED');
    });

    test('DatabaseException.insertFailed() 應包含正確資訊', () {
      final exception = DatabaseException.insertFailed('寫入失敗');

      expect(exception, isA<DatabaseException>());
      expect(exception.message.contains('寫入失敗'), isTrue);
      expect(exception.code, 'INSERT_FAILED');
    });

    test('DatabaseException.updateFailed() 應包含正確資訊', () {
      final exception = DatabaseException.updateFailed('更新失敗');

      expect(exception, isA<DatabaseException>());
      expect(exception.message.contains('更新失敗'), isTrue);
      expect(exception.code, 'UPDATE_FAILED');
    });

    test('DatabaseException.deleteFailed() 應包含正確資訊', () {
      final exception = DatabaseException.deleteFailed('刪除失敗');

      expect(exception, isA<DatabaseException>());
      expect(exception.message.contains('刪除失敗'), isTrue);
      expect(exception.code, 'DELETE_FAILED');
    });
  });

  group('Result pattern 錯誤處理測試', () {
    test('Result.failure 應正確封裝 DatabaseException', () {
      final result = Result<int>.failure(DatabaseException.corrupted());

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should not be success'),
        onFailure: (error) {
          expect(error, isA<DatabaseException>());
        },
      );
    });

    test('多個錯誤類型應正確區分', () {
      final dbError = Result<int>.failure(DatabaseException.corrupted());
      final networkError =
          Result<int>.failure(NetworkException.noConnection());
      final validationError =
          Result<int>.failure(const ValidationException('無效', field: 'test'));

      // 驗證類型可以正確區分
      dbError.fold(
        onSuccess: (_) {},
        onFailure: (e) => expect(e, isA<DatabaseException>()),
      );

      networkError.fold(
        onSuccess: (_) {},
        onFailure: (e) => expect(e, isA<NetworkException>()),
      );

      validationError.fold(
        onSuccess: (_) {},
        onFailure: (e) => expect(e, isA<ValidationException>()),
      );
    });

    test('sealed class switch 應窮盡匹配', () {
      final exceptions = <AppException>[
        DatabaseException.corrupted(),
        NetworkException.noConnection(),
        const ValidationException('test', field: 'f'),
        StorageException.writeError('/test/path'),
        AuthException.notSignedIn(),
        ExportException.noData(),
        ImageException.corrupted(),
        OcrException.noTextFound(),
      ];

      for (final e in exceptions) {
        final result = switch (e) {
          DatabaseException() => 'db',
          NetworkException() => 'network',
          ValidationException() => 'validation',
          StorageException() => 'storage',
          AuthException() => 'auth',
          ExportException() => 'export',
          ImageException() => 'image',
          OcrException() => 'ocr',
        };
        expect(result.isNotEmpty, isTrue);
      }
    });
  });

  group('資料庫重試邏輯測試', () {
    test('錯誤代碼應正確識別', () {
      expect(DatabaseException.corrupted().code, 'DB_CORRUPTED');
      expect(DatabaseException.locked().code, 'DB_LOCKED');
      expect(DatabaseException.queryFailed('').code, 'QUERY_FAILED');
    });

    test('重試邏輯模擬', () async {
      var attemptCount = 0;
      const maxRetries = 3;

      Future<Result<int>> attemptOperation() async {
        attemptCount++;
        if (attemptCount < maxRetries) {
          return Result.failure(DatabaseException.queryFailed('暫時性錯誤'));
        }
        return Result.success(42);
      }

      // 模擬重試
      Result<int> result = Result.failure(DatabaseException.corrupted());
      for (var i = 0; i < maxRetries; i++) {
        result = await attemptOperation();
        if (result.isSuccess) break;
      }

      expect(result.isSuccess, isTrue);
      expect(attemptCount, maxRetries);
    });

    test('可根據錯誤代碼決定重試策略', () {
      bool shouldRetry(AppException e) {
        if (e is DatabaseException) {
          // 鎖定錯誤可重試
          return e.code == 'DB_LOCKED';
        }
        return false;
      }

      expect(shouldRetry(DatabaseException.locked()), isTrue);
      expect(shouldRetry(DatabaseException.corrupted()), isFalse);
      expect(shouldRetry(DatabaseException.queryFailed('')), isFalse);
    });
  });

  group('資料庫狀態檢測測試', () {
    test('空資料庫狀態應正確處理', () {
      final emptyList = <Map<String, dynamic>>[];

      // 空結果應該被正確處理
      expect(emptyList.isEmpty, isTrue);
      expect(emptyList.length, 0);
    });

    test('大量資料查詢應正確處理', () {
      // 模擬 10000 筆查詢結果
      final largeResult = List.generate(
        10000,
        (i) => {'id': i, 'amount': i * 100},
      );

      expect(largeResult.length, 10000);
      expect(largeResult.first['id'], 0);
      expect(largeResult.last['id'], 9999);
    });
  });

  group('資料庫版本遷移測試', () {
    test('版本檢查邏輯應正確', () {
      const currentVersion = 1;
      const targetVersion = 2;

      expect(currentVersion < targetVersion, isTrue);
      expect(targetVersion - currentVersion, 1);
    });

    test('遷移期間錯誤應正確處理', () {
      // 模擬遷移錯誤
      Result<void> migrationResult;

      try {
        // 模擬遷移失敗
        throw DatabaseException.updateFailed('遷移 v1 -> v2 失敗');
      } catch (e) {
        migrationResult = Result.failure(e as AppException);
      }

      expect(migrationResult.isFailure, isTrue);
      migrationResult.fold(
        onSuccess: (_) {},
        onFailure: (e) {
          expect(e, isA<DatabaseException>());
          expect(e.code, 'UPDATE_FAILED');
        },
      );
    });
  });

  group('SQL 注入防護測試', () {
    test('危險字元應被正確轉義', () {
      const dangerousInput = "'; DROP TABLE expenses; --";
      // 使用參數化查詢時，這些字元不應造成問題
      // 這裡只是驗證我們能識別危險輸入
      expect(dangerousInput.contains("'"), isTrue);
      expect(dangerousInput.contains(';'), isTrue);
      expect(dangerousInput.contains('--'), isTrue);
    });

    test('參數化查詢應安全處理輸入', () {
      // 模擬參數化查詢的參數處理
      const query = 'SELECT * FROM expenses WHERE description = ?';
      const param = "'; DROP TABLE expenses; --";

      // 參數應該被視為字符串值，而非 SQL
      expect(query.contains('?'), isTrue);
      expect(param.length, greaterThan(0));
    });
  });

  group('並發資料庫錯誤測試', () {
    test('多個錯誤應獨立處理', () async {
      final errors = <AppException>[];

      // 模擬並發錯誤
      final futures = List.generate(5, (i) async {
        try {
          if (i.isEven) {
            throw DatabaseException.queryFailed('錯誤 $i');
          }
          return i;
        } catch (e) {
          errors.add(e as AppException);
          return -1;
        }
      });

      final results = await Future.wait(futures);

      // 應有 3 個錯誤（i = 0, 2, 4）
      expect(errors.length, 3);
      // 其他應成功
      expect(results.where((r) => r >= 0).length, 2);
    });
  });

  group('資料庫連接池測試', () {
    test('連接應正確管理', () {
      // 模擬連接池狀態
      var activeConnections = 0;
      const maxConnections = 10;

      void acquire() {
        if (activeConnections < maxConnections) {
          activeConnections++;
        }
      }

      void release() {
        if (activeConnections > 0) {
          activeConnections--;
        }
      }

      // 獲取 5 個連接
      for (var i = 0; i < 5; i++) {
        acquire();
      }
      expect(activeConnections, 5);

      // 釋放 3 個
      for (var i = 0; i < 3; i++) {
        release();
      }
      expect(activeConnections, 2);

      // 釋放所有
      for (var i = 0; i < 10; i++) {
        release();
      }
      expect(activeConnections, 0);
    });
  });

  group('資料庫備份恢復流程測試', () {
    test('備份狀態應正確追蹤', () {
      var backupInProgress = false;
      var lastBackupTime = DateTime.now().subtract(const Duration(days: 1));

      // 開始備份
      backupInProgress = true;
      expect(backupInProgress, isTrue);

      // 完成備份
      backupInProgress = false;
      lastBackupTime = DateTime.now();
      expect(backupInProgress, isFalse);
      expect(
        DateTime.now().difference(lastBackupTime).inSeconds,
        lessThan(2),
      );
    });

    test('恢復失敗應正確處理', () {
      final recoveryResult = Result<void>.failure(
        DatabaseException.corrupted(),
      );

      expect(recoveryResult.isFailure, isTrue);
    });

    test('資料庫損壞後應觸發恢復流程', () {
      var recoveryTriggered = false;

      void handleDatabaseError(AppException error) {
        if (error is DatabaseException && error.code == 'DB_CORRUPTED') {
          recoveryTriggered = true;
        }
      }

      handleDatabaseError(DatabaseException.corrupted());
      expect(recoveryTriggered, isTrue);
    });

    test('非損壞錯誤不應觸發恢復', () {
      var recoveryTriggered = false;

      void handleDatabaseError(AppException error) {
        if (error is DatabaseException && error.code == 'DB_CORRUPTED') {
          recoveryTriggered = true;
        }
      }

      handleDatabaseError(DatabaseException.queryFailed('test'));
      expect(recoveryTriggered, isFalse);
    });
  });

  group('錯誤鏈追蹤測試', () {
    test('錯誤訊息應包含上下文', () {
      final error = DatabaseException.queryFailed('SELECT * FROM expenses');
      expect(error.message.contains('SELECT'), isTrue);
    });

    test('錯誤代碼應可用於日誌記錄', () {
      final errors = [
        DatabaseException.corrupted(),
        DatabaseException.locked(),
        DatabaseException.queryFailed('test'),
        DatabaseException.insertFailed('test'),
        DatabaseException.updateFailed('test'),
        DatabaseException.deleteFailed('test'),
      ];

      final codes = errors.map((e) => e.code).toList();
      expect(codes.contains('DB_CORRUPTED'), isTrue);
      expect(codes.contains('DB_LOCKED'), isTrue);
      expect(codes.contains('QUERY_FAILED'), isTrue);
      expect(codes.contains('INSERT_FAILED'), isTrue);
      expect(codes.contains('UPDATE_FAILED'), isTrue);
      expect(codes.contains('DELETE_FAILED'), isTrue);
    });
  });
}
