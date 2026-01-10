import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:synchronized/synchronized.dart';

/// DatabaseHelper 並發測試
///
/// 這些測試驗證並發存取時的線程安全機制
/// 由於單元測試無法存取真實資料庫，這裡測試 Lock 機制本身
void main() {
  group('並發初始化測試', () {
    test('Lock 應確保初始化只執行一次', () async {
      var initCount = 0;
      final lock = Lock();
      String? value;

      // 模擬 10 個並發初始化請求
      final futures = List.generate(10, (_) async {
        return lock.synchronized(() async {
          if (value != null) return value;

          // 模擬初始化延遲
          await Future.delayed(const Duration(milliseconds: 10));
          initCount++;
          value = 'initialized-$initCount';
          return value;
        });
      });

      final results = await Future.wait(futures);

      // 應該只初始化一次
      expect(initCount, 1);
      // 所有結果應該相同
      expect(results.every((r) => r == 'initialized-1'), true);
    });

    test('雙重檢查鎖定模式應有效', () async {
      var initCount = 0;
      final lock = Lock();
      String? value;

      Future<String?> getValue() async {
        // 快速路徑
        if (value != null) return value;

        // 同步區塊
        return lock.synchronized(() async {
          // 雙重檢查
          if (value != null) return value;

          await Future.delayed(const Duration(milliseconds: 5));
          initCount++;
          value = 'value-$initCount';
          return value;
        });
      }

      // 第一輪：10 個並發請求
      final results1 = await Future.wait(
        List.generate(10, (_) => getValue()),
      );
      expect(initCount, 1);
      expect(results1.every((r) => r == 'value-1'), true);

      // 第二輪：value 已存在，應直接返回（不經過 Lock）
      final results2 = await Future.wait(
        List.generate(100, (_) => getValue()),
      );
      expect(initCount, 1); // 仍為 1
      expect(results2.every((r) => r == 'value-1'), true);
    });

    test('多個 Lock 應獨立運作', () async {
      final lock1 = Lock();
      final lock2 = Lock();
      var count1 = 0;
      var count2 = 0;

      // 同時對兩個 Lock 發起請求
      await Future.wait([
        lock1.synchronized(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          count1++;
        }),
        lock2.synchronized(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          count2++;
        }),
      ]);

      expect(count1, 1);
      expect(count2, 1);
    });
  });

  group('ServiceLocator 初始化競爭測試', () {
    test('模擬 ServiceLocator 初始化競爭', () async {
      var isInitialized = false;
      var initializeCallCount = 0;
      final lock = Lock();

      Future<void> ensureInitialized() async {
        if (isInitialized) return;

        await lock.synchronized(() async {
          if (isInitialized) return;

          await Future.delayed(const Duration(milliseconds: 20));
          initializeCallCount++;
          isInitialized = true;
        });
      }

      // 模擬多個服務同時請求初始化
      await Future.wait([
        ensureInitialized(),
        ensureInitialized(),
        ensureInitialized(),
        ensureInitialized(),
        ensureInitialized(),
      ]);

      expect(isInitialized, true);
      expect(initializeCallCount, 1);
    });
  });

  group('讀寫並發測試', () {
    test('讀取操作不應被寫入阻塞過久', () async {
      // 這測試模擬 WAL 模式的行為：讀寫可並發
      final data = <String, int>{'count': 0};
      final readResults = <int>[];

      // 模擬寫入操作
      final writeTask = Future.delayed(const Duration(milliseconds: 50), () {
        data['count'] = 100;
      });

      // 模擬讀取操作（應能在寫入期間讀取舊值）
      final readTasks = List.generate(5, (i) async {
        await Future.delayed(Duration(milliseconds: i * 10));
        readResults.add(data['count']!);
      });

      await Future.wait([writeTask, ...readTasks]);

      // 驗證讀取操作確實發生
      expect(readResults.length, 5);
      // 最後的值應該是 100（寫入完成後）
      expect(data['count'], 100);
    });
  });

  group('異常處理測試', () {
    test('Lock 內異常不應導致死鎖', () async {
      final lock = Lock();
      var successCount = 0;

      Future<void> taskWithError(bool shouldFail) async {
        await lock.synchronized(() async {
          if (shouldFail) {
            throw Exception('Simulated error');
          }
          successCount++;
        });
      }

      // 第一個任務失敗
      try {
        await taskWithError(true);
      } catch (_) {}

      // 第二個任務應該能正常執行（不應被第一個任務阻塞）
      await taskWithError(false);
      expect(successCount, 1);

      // 第三個任務也應正常
      await taskWithError(false);
      expect(successCount, 2);
    });

    test('timeout 處理不應影響後續操作', () async {
      final lock = Lock();
      var count = 0;

      Future<void> slowTask() async {
        await lock.synchronized(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          count++;
        });
      }

      Future<void> fastTask() async {
        await lock.synchronized(() async {
          await Future.delayed(const Duration(milliseconds: 5));
          count++;
        });
      }

      // 啟動慢任務但不等待
      unawaited(slowTask());

      // 快任務需要等待慢任務完成
      await fastTask();

      // 等待慢任務完成
      await Future.delayed(const Duration(milliseconds: 150));

      expect(count, 2);
    });
  });

  group('高並發壓力測試', () {
    test('100 個並發請求應正確處理', () async {
      final lock = Lock();
      var value = 0;

      final futures = List.generate(100, (i) async {
        return lock.synchronized(() async {
          final current = value;
          await Future.delayed(const Duration(microseconds: 100));
          value = current + 1;
          return value;
        });
      });

      final results = await Future.wait(futures);

      // 值應該從 1 到 100
      expect(value, 100);
      // 每個結果應該是遞增的
      final sortedResults = List<int>.from(results)..sort();
      expect(sortedResults, List.generate(100, (i) => i + 1));
    });

    test('混合讀寫 50 個並發請求', () async {
      final lock = Lock();
      final data = <int>[];

      // 25 個寫入任務
      final writeTasks = List.generate(25, (i) async {
        await lock.synchronized(() async {
          await Future.delayed(const Duration(microseconds: 50));
          data.add(i);
        });
      });

      // 25 個讀取任務
      final readTasks = List.generate(25, (_) async {
        return lock.synchronized(() async {
          await Future.delayed(const Duration(microseconds: 50));
          return data.length;
        });
      });

      await Future.wait([...writeTasks, ...readTasks]);

      // 所有寫入應該完成
      expect(data.length, 25);
    });
  });
}
