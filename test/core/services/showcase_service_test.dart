import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_snap/core/services/showcase_service.dart';

/// 可測試的 ShowcaseService，注入記憶體資料庫
///
/// 因為 ShowcaseService 依賴 DatabaseHelper.instance，
/// 我們用 sqflite_ffi 在記憶體中模擬資料庫行為
class TestableShowcaseService {
  TestableShowcaseService(this._db);
  final Database _db;

  /// 檢查 showcase 是否已完成
  Future<bool> isShowcaseComplete(String key) async {
    final results = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isEmpty) return false;
    return results.first['value'] == 'true';
  }

  /// 標記 showcase 已完成
  Future<void> markShowcaseComplete(String key) async {
    await _db.insert(
      'app_settings',
      {'key': key, 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 重置所有 showcase
  Future<void> resetAllShowcases() async {
    for (final key in [
      ShowcaseService.fabShowcase,
      ShowcaseService.swipeDeleteShowcase,
      ShowcaseService.exportShowcase,
    ]) {
      await _db.insert(
        'app_settings',
        {'key': key, 'value': 'false'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// 取得支出數量
  Future<int> getExpenseCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE deleted_at IS NULL',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late TestableShowcaseService service;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // 建立 app_settings 表
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        // 建立 expenses 表（用於 getExpenseCount）
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            original_amount INTEGER NOT NULL,
            original_currency TEXT NOT NULL,
            exchange_rate INTEGER NOT NULL,
            exchange_rate_source TEXT NOT NULL,
            hkd_amount INTEGER NOT NULL,
            description TEXT NOT NULL,
            category TEXT,
            target_currency TEXT NOT NULL DEFAULT 'HKD',
            receipt_image_path TEXT,
            thumbnail_path TEXT,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            deleted_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );

    service = TestableShowcaseService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ShowcaseService', () {
    group('常數定義', () {
      test('fabShowcase 鍵值應正確', () {
        expect(ShowcaseService.fabShowcase, equals('showcase_fab'));
      });

      test('swipeDeleteShowcase 鍵值應正確', () {
        expect(
          ShowcaseService.swipeDeleteShowcase,
          equals('showcase_swipe_delete'),
        );
      });

      test('exportShowcase 鍵值應正確', () {
        expect(ShowcaseService.exportShowcase, equals('showcase_export'));
      });
    });

    group('instance', () {
      test('應為單例模式', () {
        final instance1 = ShowcaseService.instance;
        final instance2 = ShowcaseService.instance;
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('isShowcaseComplete', () {
      test('未設定的 showcase 應為未完成', () async {
        final result = await service.isShowcaseComplete('showcase_fab');
        expect(result, isFalse);
      });

      test('標記完成後應為已完成', () async {
        await service.markShowcaseComplete('showcase_fab');

        final result = await service.isShowcaseComplete('showcase_fab');
        expect(result, isTrue);
      });

      test('不存在的鍵值應回傳 false', () async {
        final result = await service.isShowcaseComplete('non_existent_key');
        expect(result, isFalse);
      });
    });

    group('markShowcaseComplete', () {
      test('應將 showcase 標記為已完成', () async {
        await service.markShowcaseComplete(ShowcaseService.fabShowcase);

        final result = await service.isShowcaseComplete(
          ShowcaseService.fabShowcase,
        );
        expect(result, isTrue);
      });

      test('重複標記不應拋出錯誤', () async {
        await service.markShowcaseComplete(ShowcaseService.fabShowcase);
        await service.markShowcaseComplete(ShowcaseService.fabShowcase);

        final result = await service.isShowcaseComplete(
          ShowcaseService.fabShowcase,
        );
        expect(result, isTrue);
      });

      test('應獨立追蹤各個 showcase', () async {
        await service.markShowcaseComplete(ShowcaseService.fabShowcase);

        // 其他 showcase 應仍為未完成
        final swipe = await service.isShowcaseComplete(
          ShowcaseService.swipeDeleteShowcase,
        );
        final export = await service.isShowcaseComplete(
          ShowcaseService.exportShowcase,
        );

        expect(swipe, isFalse);
        expect(export, isFalse);
      });
    });

    group('resetAllShowcases', () {
      test('應重置所有 showcase 為未完成', () async {
        // 先標記全部完成
        await service.markShowcaseComplete(ShowcaseService.fabShowcase);
        await service.markShowcaseComplete(ShowcaseService.swipeDeleteShowcase);
        await service.markShowcaseComplete(ShowcaseService.exportShowcase);

        // 重置
        await service.resetAllShowcases();

        // 驗證全部為未完成
        expect(
          await service.isShowcaseComplete(ShowcaseService.fabShowcase),
          isFalse,
        );
        expect(
          await service.isShowcaseComplete(ShowcaseService.swipeDeleteShowcase),
          isFalse,
        );
        expect(
          await service.isShowcaseComplete(ShowcaseService.exportShowcase),
          isFalse,
        );
      });

      test('未設定過的 showcase 重置後也應為未完成', () async {
        // 直接 reset（即使從未設定）
        await service.resetAllShowcases();

        expect(
          await service.isShowcaseComplete(ShowcaseService.fabShowcase),
          isFalse,
        );
      });
    });

    group('getExpenseCount', () {
      test('無資料時應回傳 0', () async {
        final count = await service.getExpenseCount();
        expect(count, equals(0));
      });

      test('應正確計算非刪除的支出數量', () async {
        // 插入 3 筆正常支出
        for (int i = 0; i < 3; i++) {
          await db.insert('expenses', {
            'date': '2025-01-10',
            'original_amount': 1000,
            'original_currency': 'HKD',
            'exchange_rate': 1000000,
            'exchange_rate_source': 'auto',
            'hkd_amount': 1000,
            'description': '支出$i',
            'target_currency': 'HKD',
            'is_deleted': 0,
            'created_at': '2025-01-10T10:00:00',
            'updated_at': '2025-01-10T10:00:00',
          });
        }

        final count = await service.getExpenseCount();
        expect(count, equals(3));
      });

      test('不應計算已軟刪除的支出', () async {
        // 插入 2 筆正常 + 1 筆已刪除
        await db.insert('expenses', {
          'date': '2025-01-10',
          'original_amount': 1000,
          'original_currency': 'HKD',
          'exchange_rate': 1000000,
          'exchange_rate_source': 'auto',
          'hkd_amount': 1000,
          'description': '正常支出',
          'target_currency': 'HKD',
          'is_deleted': 0,
          'created_at': '2025-01-10T10:00:00',
          'updated_at': '2025-01-10T10:00:00',
        });
        await db.insert('expenses', {
          'date': '2025-01-11',
          'original_amount': 2000,
          'original_currency': 'HKD',
          'exchange_rate': 1000000,
          'exchange_rate_source': 'auto',
          'hkd_amount': 2000,
          'description': '已刪除支出',
          'target_currency': 'HKD',
          'is_deleted': 1,
          'deleted_at': '2025-01-12T10:00:00',
          'created_at': '2025-01-11T10:00:00',
          'updated_at': '2025-01-11T10:00:00',
        });

        final count = await service.getExpenseCount();
        expect(count, equals(1));
      });
    });

    group('完整流程', () {
      test('標記 → 驗證 → 重置 → 驗證 完整流程', () async {
        // 1. 初始狀態 - 全部未完成
        expect(
          await service.isShowcaseComplete(ShowcaseService.fabShowcase),
          isFalse,
        );

        // 2. 標記 FAB 完成
        await service.markShowcaseComplete(ShowcaseService.fabShowcase);
        expect(
          await service.isShowcaseComplete(ShowcaseService.fabShowcase),
          isTrue,
        );

        // 3. 標記 Swipe 完成
        await service.markShowcaseComplete(ShowcaseService.swipeDeleteShowcase);
        expect(
          await service.isShowcaseComplete(ShowcaseService.swipeDeleteShowcase),
          isTrue,
        );

        // 4. 重置全部
        await service.resetAllShowcases();
        expect(
          await service.isShowcaseComplete(ShowcaseService.fabShowcase),
          isFalse,
        );
        expect(
          await service.isShowcaseComplete(ShowcaseService.swipeDeleteShowcase),
          isFalse,
        );
      });
    });
  });
}
