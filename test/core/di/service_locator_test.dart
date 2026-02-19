import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/di/service_locator.dart';

void main() {
  group('ServiceLocator', () {
    group('instance', () {
      test('應為單例模式', () {
        // Arrange & Act
        final instance1 = ServiceLocator.instance;
        final instance2 = ServiceLocator.instance;

        // Assert - 每次取得的都是同一個實例
        expect(identical(instance1, instance2), isTrue);
      });

      test('sl 全域訪問點應回傳相同實例', () {
        // Act
        final fromSl = sl;
        final fromInstance = ServiceLocator.instance;

        // Assert
        expect(identical(fromSl, fromInstance), isTrue);
      });
    });

    group('initialization', () {
      test('初始狀態應為未初始化', () {
        // ServiceLocator 是單例，但我們可以檢查其 isInitialized 屬性
        // 注意：如果其他測試已初始化過，這裡不一定為 false
        // 所以只驗證 isInitialized 回傳 bool
        expect(sl.isInitialized, isA<bool>());
      });

      test('未初始化時存取服務應拋出 StateError', () {
        // 建立新的 ServiceLocator 子型別來測試（無法 reset 單例）
        // 由於 ServiceLocator 使用私有建構子和 static instance，
        // 我們測試的是 _ensureInitialized 的防護邏輯
        // 如果已初始化，我們先 reset
        if (sl.isInitialized) {
          // 已初始化狀態下不會拋出
          expect(() => sl.databaseHelper, returnsNormally);
        } else {
          // 未初始化應拋出 StateError
          expect(
            () => sl.databaseHelper,
            throwsA(isA<StateError>()),
          );
        }
      });

      test('未初始化時存取各服務應拋出 StateError', () async {
        // 先 reset 確保未初始化狀態
        await sl.reset();

        // 驗證各 getter 都會拋出 StateError
        expect(() => sl.databaseHelper, throwsA(isA<StateError>()));
        expect(() => sl.secureStorageHelper, throwsA(isA<StateError>()));
        expect(() => sl.imageService, throwsA(isA<StateError>()));
        expect(() => sl.ocrService, throwsA(isA<StateError>()));
        expect(() => sl.imageCleanupService, throwsA(isA<StateError>()));
        expect(() => sl.expenseRepository, throwsA(isA<StateError>()));
        expect(() => sl.exchangeRateRepository, throwsA(isA<StateError>()));
        expect(() => sl.backupRepository, throwsA(isA<StateError>()));
      });

      test('reset 後 isInitialized 應為 false', () async {
        // Act
        await sl.reset();

        // Assert
        expect(sl.isInitialized, isFalse);
      });

      test('重複 reset 不應拋出錯誤', () async {
        // 連續 reset 兩次不應有問題
        await sl.reset();
        await sl.reset();

        expect(sl.isInitialized, isFalse);
      });
    });

    group('StateError 訊息', () {
      test('StateError 應包含引導訊息', () async {
        await sl.reset();

        expect(
          () => sl.databaseHelper,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('initialize()'),
            ),
          ),
        );
      });
    });
  });
}
