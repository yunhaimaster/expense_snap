import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/constants/expense_category.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense', () {
    late Expense expense;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 1, 15);
      expense = Expense(
        id: 1,
        date: testDate,
        originalAmountCents: 10050, // 100.50
        originalCurrency: 'CNY',
        exchangeRate: 1089000, // 1.089
        exchangeRateSource: ExchangeRateSource.auto,
        convertedAmountCents: 10944, // 109.44 (100.50 * 1.089)
        targetCurrency: 'HKD',
        description: '午餐',
        category: ExpenseCategory.meals,
        receiptImagePath: '/path/to/image.jpg',
        thumbnailPath: '/path/to/thumb.jpg',
        isDeleted: false,
        deletedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('Amount conversion', () {
      test('should convert cents to amount correctly', () {
        expect(expense.originalAmount, equals(100.50));
      });

      test('should convert hkd cents to amount correctly', () {
        expect(expense.convertedAmount, closeTo(109.44, 0.01));
      });

      test('should format original amount with currency symbol', () {
        expect(expense.formattedOriginalAmount, equals('¥100.50'));
      });

      test('should format HKD amount correctly', () {
        expect(expense.formattedConvertedAmount, equals('HK\$109.44'));
      });

      // JPY/KRW 無小數幣種測試
      test('should handle JPY expense correctly (no decimals)', () {
        final jpyExpense = Expense(
          id: 100,
          date: testDate,
          originalAmountCents: 1000, // ¥1,000（無小數）
          originalCurrency: 'JPY',
          exchangeRate: 52000, // 0.052 HKD per JPY
          exchangeRateSource: ExchangeRateSource.defaultRate,
          convertedAmountCents: 52, // 1000 * 0.052 = 52 cents HKD
          targetCurrency: 'HKD',
          description: 'JPY test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // JPY cents 即為實際金額
        expect(jpyExpense.originalAmount, equals(1000.0));
        expect(jpyExpense.formattedOriginalAmount, equals('¥1,000'));
      });

      test('should handle KRW expense correctly (no decimals)', () {
        final krwExpense = Expense(
          id: 101,
          date: testDate,
          originalAmountCents: 50000, // ₩50,000
          originalCurrency: 'KRW',
          exchangeRate: 5700, // 0.0057 HKD per KRW
          exchangeRateSource: ExchangeRateSource.defaultRate,
          convertedAmountCents: 285, // 50000 * 0.0057 = 285 cents HKD
          targetCurrency: 'HKD',
          description: 'KRW test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // KRW cents 即為實際金額
        expect(krwExpense.originalAmount, equals(50000.0));
        expect(krwExpense.formattedOriginalAmount, equals('₩50,000'));
      });
    });

    group('Exchange rate', () {
      test('should format exchange rate correctly', () {
        expect(expense.formattedExchangeRate, equals('1.0890'));
      });
    });

    group('Receipt', () {
      test('should detect when receipt exists', () {
        expect(expense.hasReceipt, isTrue);
      });

      test('should detect when receipt does not exist', () {
        // 建立沒有收據的支出
        final noReceipt = Expense(
          id: 2,
          date: testDate,
          originalAmountCents: 5000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 5000,
          targetCurrency: 'HKD',
          description: '無收據',
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(noReceipt.hasReceipt, isFalse);
      });

      test('should detect empty receipt path', () {
        final emptyReceipt = expense.copyWith(receiptImagePath: '');
        expect(emptyReceipt.hasReceipt, isFalse);
      });
    });

    group('Soft delete', () {
      test('should calculate days until permanent delete', () {
        final deletedAt = DateTime.now().subtract(const Duration(days: 10));
        final deleted = expense.copyWith(
          isDeleted: true,
          deletedAt: deletedAt,
        );

        // 30 - 10 = 20 days remaining
        expect(deleted.daysUntilPermanentDelete, closeTo(20, 1));
      });

      test('should return null for non-deleted expense', () {
        expect(expense.daysUntilPermanentDelete, isNull);
      });
    });

    group('Category', () {
      test('should store category correctly', () {
        expect(expense.category, equals(ExpenseCategory.meals));
      });

      test('should allow null category', () {
        final noCategory = Expense(
          id: 3,
          date: testDate,
          originalAmountCents: 5000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 5000,
          targetCurrency: 'HKD',
          description: '無分類支出',
          category: null,
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(noCategory.category, isNull);
      });

      test('should update category via copyWith', () {
        final updated = expense.copyWith(category: ExpenseCategory.transport);
        expect(updated.category, equals(ExpenseCategory.transport));
      });

      test('should clear category via copyWith with clearCategory flag', () {
        final cleared = expense.copyWith(clearCategory: true);
        expect(cleared.category, isNull);
      });

      test('clearCategory should take precedence over category parameter', () {
        final cleared = expense.copyWith(
          category: ExpenseCategory.entertainment,
          clearCategory: true,
        );
        expect(cleared.category, isNull);
      });
    });

    group('Serialization', () {
      test('should convert to map correctly', () {
        final map = expense.toMap();

        expect(map['id'], equals(1));
        expect(map['original_amount'], equals(10050));
        expect(map['original_currency'], equals('CNY'));
        expect(map['exchange_rate'], equals(1089000));
        expect(map['exchange_rate_source'], equals('auto'));
        expect(map['hkd_amount'], equals(10944));
        expect(map['description'], equals('午餐'));
        expect(map['category'], equals('meals'));
        expect(map['is_deleted'], equals(0));
      });

      test('should serialize null category correctly', () {
        final noCategory = expense.copyWith(clearCategory: true);
        final map = noCategory.toMap();
        expect(map['category'], isNull);
      });

      test('should parse from map correctly', () {
        final map = {
          'id': 2,
          'date': '2025-01-20T00:00:00.000Z',
          'original_amount': 5000,
          'original_currency': 'USD',
          'exchange_rate': 7800000,
          'exchange_rate_source': 'offline',
          'hkd_amount': 39000,
          'description': '訂閱服務',
          'category': 'communication',
          'receipt_image_path': null,
          'thumbnail_path': null,
          'is_deleted': 0,
          'deleted_at': null,
          'created_at': '2025-01-20T10:00:00.000Z',
          'updated_at': '2025-01-20T10:00:00.000Z',
        };

        final parsed = Expense.fromMap(map);

        expect(parsed.id, equals(2));
        expect(parsed.originalAmountCents, equals(5000));
        expect(parsed.originalCurrency, equals('USD'));
        expect(parsed.exchangeRateSource, equals(ExchangeRateSource.offline));
        expect(parsed.description, equals('訂閱服務'));
        expect(parsed.category, equals(ExpenseCategory.communication));
        expect(parsed.hasReceipt, isFalse);
      });

      test('should parse null category from map', () {
        final map = {
          'id': 3,
          'date': '2025-01-20T00:00:00.000Z',
          'original_amount': 5000,
          'original_currency': 'HKD',
          'exchange_rate': 1000000,
          'exchange_rate_source': 'auto',
          'hkd_amount': 5000,
          'description': '無分類',
          'category': null,
          'receipt_image_path': null,
          'thumbnail_path': null,
          'is_deleted': 0,
          'deleted_at': null,
          'created_at': '2025-01-20T10:00:00.000Z',
          'updated_at': '2025-01-20T10:00:00.000Z',
        };

        final parsed = Expense.fromMap(map);
        expect(parsed.category, isNull);
      });

      test('should handle is_deleted flag in serialization', () {
        final deleted = expense.copyWith(isDeleted: true);
        final map = deleted.toMap();

        expect(map['is_deleted'], equals(1));
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final updated = expense.copyWith(
          description: '晚餐',
          originalAmountCents: 20000,
        );

        expect(updated.description, equals('晚餐'));
        expect(updated.originalAmountCents, equals(20000));
        // 其他值不變
        expect(updated.id, equals(expense.id));
        expect(updated.originalCurrency, equals(expense.originalCurrency));
      });

      test('should preserve original values when not specified', () {
        final copied = expense.copyWith();

        expect(copied.id, equals(expense.id));
        expect(copied.description, equals(expense.description));
        expect(copied.originalAmountCents, equals(expense.originalAmountCents));
        expect(copied.category, equals(expense.category));
      });
    });

    group('equality', () {
      test('should be equal when id matches', () {
        final expense1 = expense;
        final expense2 = expense.copyWith(description: '不同描述');

        expect(expense1, equals(expense2));
      });

      test('should have same hashCode when id matches', () {
        final expense1 = expense;
        final expense2 = expense.copyWith(description: '不同描述');

        expect(expense1.hashCode, equals(expense2.hashCode));
      });

      test('should include category in equality when no id', () {
        final now = DateTime.now();
        final expense1 = Expense(
          id: null,
          date: testDate,
          originalAmountCents: 5000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 5000,
          targetCurrency: 'HKD',
          description: '測試',
          category: ExpenseCategory.meals,
          createdAt: now,
          updatedAt: now,
        );
        final expense2 = Expense(
          id: null,
          date: testDate,
          originalAmountCents: 5000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 5000,
          targetCurrency: 'HKD',
          description: '測試',
          category: ExpenseCategory.transport,
          createdAt: now,
          updatedAt: now,
        );

        // 分類不同，應不相等
        expect(expense1, isNot(equals(expense2)));
      });
    });
  });

  group('MonthSummary', () {
    test('should format month correctly in Chinese', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 15,
        totalConvertedAmountCents: 250000,
        dominantCurrency: 'HKD',
      );

      // 中文格式
      expect(summary.formattedMonth(locale: 'zh'), equals('2025年1月'));
    });

    test('should format month correctly in English', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 15,
        totalConvertedAmountCents: 250000,
        dominantCurrency: 'HKD',
      );

      // 英文格式
      expect(summary.formattedMonth(locale: 'en'), equals('January 2025'));
    });

    test('should format total amount correctly', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 15,
        totalConvertedAmountCents: 250000,
        dominantCurrency: 'HKD',
      );

      expect(summary.formattedTotalAmount, equals('HK\$2,500.00'));
    });

    test('should format amount with dominant currency', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 5,
        totalConvertedAmountCents: 10000,
        dominantCurrency: 'USD',
      );

      expect(summary.formattedTotalAmount, equals('\$100.00'));
    });

    test('should show ≈ prefix for mixed currencies', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 10,
        totalConvertedAmountCents: 50000,
        dominantCurrency: 'HKD',
        hasMixedCurrencies: true,
      );

      expect(summary.formattedTotalAmount, equals('≈ HK\$500.00'));
    });

    test('should handle JPY without decimals', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 3,
        totalConvertedAmountCents: 10000, // 10000 yen (no cents for JPY)
        dominantCurrency: 'JPY',
      );

      expect(summary.formattedTotalAmount, equals('¥10,000'));
    });

    test('should create empty summary', () {
      final empty = MonthSummary.empty(2025, 3);

      expect(empty.year, equals(2025));
      expect(empty.month, equals(3));
      expect(empty.totalCount, equals(0));
      expect(empty.totalConvertedAmountCents, equals(0));
      expect(empty.dominantCurrency, equals('HKD'));
      expect(empty.hasMixedCurrencies, isFalse);
    });
  });
}
