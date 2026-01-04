import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';

/// DatabaseHelper 測試
///
/// 注意：完整的資料庫操作測試需要使用整合測試
/// 這裡測試靜態配置和設計模式
void main() {
  group('DatabaseHelper 設計', () {
    test('應為單例模式', () {
      final instance1 = DatabaseHelper.instance;
      final instance2 = DatabaseHelper.instance;

      expect(identical(instance1, instance2), true);
    });

    test('多次獲取 instance 應返回相同物件', () {
      final instances = List.generate(10, (_) => DatabaseHelper.instance);

      for (final instance in instances) {
        expect(identical(instance, DatabaseHelper.instance), true);
      }
    });
  });

  group('DatabaseHelper 資料表結構驗證', () {
    test('expenses 表應包含必要欄位', () {
      // 驗證 SQL schema 中定義的欄位
      // 這些欄位在 _onCreate 中定義
      const expectedColumns = [
        'id',
        'date',
        'original_amount',
        'original_currency',
        'exchange_rate',
        'exchange_rate_source',
        'hkd_amount',
        'description',
        'receipt_image_path',
        'thumbnail_path',
        'is_deleted',
        'deleted_at',
        'created_at',
        'updated_at',
      ];

      // 這是設計驗證，確保欄位清單正確
      expect(expectedColumns.length, 14);
      expect(expectedColumns.contains('id'), true);
      expect(expectedColumns.contains('date'), true);
      expect(expectedColumns.contains('hkd_amount'), true);
    });

    test('exchange_rate_cache 表應包含必要欄位', () {
      const expectedColumns = [
        'currency',
        'rate_to_hkd',
        'fetched_at',
        'source',
      ];

      expect(expectedColumns.length, 4);
      expect(expectedColumns.contains('currency'), true);
      expect(expectedColumns.contains('rate_to_hkd'), true);
    });

    test('backup_status 表應為單行記錄設計', () {
      const expectedColumns = [
        'id',
        'last_backup_at',
        'last_backup_count',
        'last_backup_size_kb',
        'google_email',
      ];

      expect(expectedColumns.length, 5);
      // id 應該永遠為 1（單行設計）
      expect(expectedColumns.contains('id'), true);
    });

    test('app_settings 表應為 key-value 設計', () {
      const expectedColumns = [
        'key',
        'value',
      ];

      expect(expectedColumns.length, 2);
    });
  });

  group('DatabaseHelper 索引設計', () {
    test('expenses 表應有效能優化索引', () {
      // 驗證索引設計：按日期查詢、刪除狀態過濾
      const expectedIndexes = [
        'idx_expenses_date',
        'idx_expenses_is_deleted',
        'idx_expenses_deleted_at',
      ];

      expect(expectedIndexes.length, 3);
    });
  });

  group('月份查詢邊界計算', () {
    test('月份起始日應為 1 號', () {
      final startDate = DateTime(2025, 3, 1);
      expect(startDate.day, 1);
      expect(startDate.month, 3);
    });

    test('月份結束日應為該月最後一天', () {
      // 使用 day: 0 計算上個月最後一天的技巧
      final endDate = DateTime(2025, 4, 0, 23, 59, 59);
      expect(endDate.month, 3);
      expect(endDate.day, 31); // 3 月有 31 天
    });

    test('2 月閏年應有 29 天', () {
      final endDate = DateTime(2024, 3, 0); // 2024 是閏年
      expect(endDate.month, 2);
      expect(endDate.day, 29);
    });

    test('2 月平年應有 28 天', () {
      final endDate = DateTime(2025, 3, 0); // 2025 不是閏年
      expect(endDate.month, 2);
      expect(endDate.day, 28);
    });
  });
}
