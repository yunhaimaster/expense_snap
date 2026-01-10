import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/data/models/expense.dart';

/// 邊界情況測試
///
/// 測試各種極端情況和邊界條件
void main() {
  group('金額邊界測試', () {
    test('最小金額（1 分）應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1, // 0.01 元
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1,
        description: '最小金額測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.originalAmountCents, 1);
      expect(expense.hkdAmountCents, 1);
    });

    test('大金額（10萬港幣）應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 10000000, // 100,000.00 元
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 10000000,
        description: '大金額測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.originalAmountCents, 10000000);
    });

    test('極大金額（100萬港幣）應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 100000000, // 1,000,000.00 元
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 100000000,
        description: '極大金額測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.originalAmountCents, 100000000);
    });

    test('零金額應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 0,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 0,
        description: '零金額測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.originalAmountCents, 0);
    });
  });

  group('日期邊界測試', () {
    test('月份第一天應正確處理', () {
      final date = DateTime(2024, 1, 1);
      final expense = Expense(
        id: 1,
        date: date,
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '月初測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.date.day, 1);
      expect(expense.date.month, 1);
    });

    test('月份最後一天應正確處理', () {
      final date = DateTime(2024, 1, 31);
      final expense = Expense(
        id: 1,
        date: date,
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '月末測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.date.day, 31);
    });

    test('閏年 2 月 29 日應正確處理', () {
      final date = DateTime(2024, 2, 29); // 2024 是閏年
      final expense = Expense(
        id: 1,
        date: date,
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '閏年測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.date.day, 29);
      expect(expense.date.month, 2);
    });

    test('跨年邊界應正確處理', () {
      final date = DateTime(2023, 12, 31);
      final expense = Expense(
        id: 1,
        date: date,
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '跨年測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.date.year, 2023);
      expect(expense.date.month, 12);
      expect(expense.date.day, 31);
    });

    test('午夜時間應正確處理', () {
      final date = DateTime(2024, 6, 15, 0, 0, 0);
      final expense = Expense(
        id: 1,
        date: date,
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '午夜測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.date.hour, 0);
      expect(expense.date.minute, 0);
    });

    test('23:59:59 應正確處理', () {
      final date = DateTime(2024, 6, 15, 23, 59, 59);
      final expense = Expense(
        id: 1,
        date: date,
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '深夜測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.date.hour, 23);
      expect(expense.date.minute, 59);
    });
  });

  group('匯率邊界測試', () {
    test('1:1 匯率應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000, // 1.0 × 10^6
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '1:1 匯率',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.exchangeRate, 1000000);
    });

    test('極小匯率應正確處理', () {
      // 例如：1 日圓 = 0.05 港幣
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 10000, // 100 日圓
        originalCurrency: 'JPY',
        exchangeRate: 50000, // 0.05 × 10^6
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 500, // 5 港幣
        description: '極小匯率測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.exchangeRate, 50000);
    });

    test('極大匯率應正確處理', () {
      // 例如：1 英鎊 = 10 港幣
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000, // 10 英鎊
        originalCurrency: 'GBP',
        exchangeRate: 10000000, // 10.0 × 10^6
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 10000, // 100 港幣
        description: '極大匯率測試',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.exchangeRate, 10000000);
    });
  });

  group('描述文字邊界測試', () {
    test('空描述應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.description, '');
    });

    test('超長描述應正確處理', () {
      final longDescription = 'A' * 1000; // 1000 字元
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: longDescription,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.description.length, 1000);
    });

    test('特殊字元描述應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '測試 "引號" \'單引號\' <tag> & 符號',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.description.contains('"'), true);
      expect(expense.description.contains("'"), true);
      expect(expense.description.contains('<'), true);
      expect(expense.description.contains('&'), true);
    });

    test('Emoji 描述應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '午餐 🍜 咖啡 ☕',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.description.contains('🍜'), true);
      expect(expense.description.contains('☕'), true);
    });

    test('多語言描述應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '中文 English 日本語 한국어',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.description.contains('中文'), true);
      expect(expense.description.contains('English'), true);
      expect(expense.description.contains('日本語'), true);
      expect(expense.description.contains('한국어'), true);
    });
  });

  group('ID 邊界測試', () {
    test('最小 ID 應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '最小 ID',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.id, 1);
    });

    test('大 ID 應正確處理', () {
      final expense = Expense(
        id: 999999,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '大 ID',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.id, 999999);
    });
  });

  group('路徑邊界測試', () {
    test('null 圖片路徑應正確處理', () {
      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '無圖片',
        receiptImagePath: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.receiptImagePath, null);
    });

    test('長路徑應正確處理', () {
      final longPath = [
          '/storage/emulated/0/Android/data/com.example.app/files/',
          'very/long/nested/directory/structure/' * 5,
          'image.jpg',
        ].join();

      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '長路徑測試',
        receiptImagePath: longPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.receiptImagePath, longPath);
    });

    test('含空格路徑應正確處理', () {
      const pathWithSpaces = '/path/with spaces/to/image file.jpg';

      final expense = Expense(
        id: 1,
        date: DateTime.now(),
        originalAmountCents: 1000,
        originalCurrency: 'HKD',
        exchangeRate: 1000000,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 1000,
        description: '含空格路徑',
        receiptImagePath: pathWithSpaces,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.receiptImagePath, pathWithSpaces);
    });
  });

  group('幣種邊界測試', () {
    test('所有支援的幣種應正確處理', () {
      final currencies = ['HKD', 'CNY', 'USD', 'JPY', 'EUR', 'GBP', 'TWD'];

      for (final currency in currencies) {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          originalAmountCents: 1000,
          originalCurrency: currency,
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: 1000,
          description: '$currency 測試',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(expense.originalCurrency, currency);
      }
    });
  });

  group('大量資料邊界測試', () {
    // 生成測試用支出列表
    List<Expense> generateExpenses(int count) {
      final now = DateTime.now();
      return List.generate(count, (index) {
        return Expense(
          id: index + 1,
          date: now.subtract(Duration(days: index % 365)),
          originalAmountCents: (index + 1) * 100,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: (index + 1) * 100,
          description: '支出 #${index + 1}',
          createdAt: now,
          updatedAt: now,
        );
      });
    }

    test('生成 10,000 筆支出資料應正常處理', () {
      final stopwatch = Stopwatch()..start();
      final expenses = generateExpenses(10000);
      stopwatch.stop();

      expect(expenses.length, 10000);
      expect(expenses.first.id, 1);
      expect(expenses.last.id, 10000);

      // 生成時間應在合理範圍內（< 1 秒）
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('過濾大量資料應高效執行', () {
      final expenses = generateExpenses(10000);
      final stopwatch = Stopwatch()..start();

      // 過濾金額大於 5000 元的支出
      final filtered = expenses.where((e) => e.hkdAmountCents > 500000).toList();
      stopwatch.stop();

      expect(filtered.length, greaterThan(0));
      expect(filtered.length, lessThan(10000));

      // 過濾時間應在合理範圍內（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('排序大量資料應高效執行', () {
      final expenses = generateExpenses(10000);
      final stopwatch = Stopwatch()..start();

      // 按金額排序
      final sorted = List<Expense>.from(expenses)
        ..sort((a, b) => b.hkdAmountCents.compareTo(a.hkdAmountCents));
      stopwatch.stop();

      expect(sorted.first.hkdAmountCents, greaterThan(sorted.last.hkdAmountCents));

      // 排序時間應在合理範圍內（< 200ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('計算大量資料總金額應正確', () {
      final expenses = generateExpenses(10000);
      final stopwatch = Stopwatch()..start();

      // 計算總金額（以分為單位）
      final totalCents = expenses.fold<int>(0, (sum, e) => sum + e.hkdAmountCents);
      stopwatch.stop();

      // 預期總金額：sum(1 to 10000) * 100 = 50005000 * 100 = 5000500000
      expect(totalCents, 5000500000);

      // 計算時間應在合理範圍內（< 50ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });

  group('月份邊界測試', () {
    test('按月份分組大量資料應正確', () {
      final now = DateTime.now();
      final expenses = List.generate(1000, (index) {
        // 分布在過去 12 個月
        final monthOffset = index % 12;
        final date = DateTime(now.year, now.month - monthOffset, 1);
        return Expense(
          id: index + 1,
          date: date,
          originalAmountCents: 1000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: 1000,
          description: '月份測試 #${index + 1}',
          createdAt: now,
          updatedAt: now,
        );
      });

      final stopwatch = Stopwatch()..start();

      // 按月份分組
      final grouped = <String, List<Expense>>{};
      for (final expense in expenses) {
        final key = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(expense);
      }
      stopwatch.stop();

      // 應該有約 12 個月份組
      expect(grouped.keys.length, lessThanOrEqualTo(12));

      // 每組應有約 83-84 筆（1000 / 12）
      for (final group in grouped.values) {
        expect(group.length, greaterThan(0));
      }

      // 分組時間應在合理範圍內（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('單月 10,000 筆支出應正常處理', () {
      final now = DateTime.now();
      final sameMonth = DateTime(now.year, now.month, 15);

      final expenses = List.generate(10000, (index) {
        return Expense(
          id: index + 1,
          date: sameMonth,
          originalAmountCents: 100,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: 100,
          description: '同月支出 #${index + 1}',
          createdAt: now,
          updatedAt: now,
        );
      });

      // 按月份分組應只有一組
      final grouped = <String, List<Expense>>{};
      for (final expense in expenses) {
        final key = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(expense);
      }

      expect(grouped.keys.length, 1);
      expect(grouped.values.first.length, 10000);
    });
  });
}
