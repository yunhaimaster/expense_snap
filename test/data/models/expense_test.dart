import 'package:expense_snap/core/constants/currency_constants.dart';
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
        hkdAmountCents: 10944, // 109.44 (100.50 * 1.089)
        description: '午餐',
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
        expect(expense.hkdAmount, closeTo(109.44, 0.01));
      });

      test('should format original amount with currency symbol', () {
        expect(expense.formattedOriginalAmount, equals('¥100.50'));
      });

      test('should format HKD amount correctly', () {
        expect(expense.formattedHkdAmount, equals('HK\$109.44'));
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
          hkdAmountCents: 5000,
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
        expect(map['is_deleted'], equals(0));
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
        expect(parsed.hasReceipt, isFalse);
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
    });
  });

  group('MonthSummary', () {
    test('should format month correctly', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 15,
        totalHkdAmountCents: 250000,
      );

      expect(summary.formattedMonth, equals('2025年1月'));
    });

    test('should format total amount correctly', () {
      const summary = MonthSummary(
        year: 2025,
        month: 1,
        totalCount: 15,
        totalHkdAmountCents: 250000,
      );

      expect(summary.formattedTotalAmount, equals('HK\$2,500.00'));
    });

    test('should create empty summary', () {
      final empty = MonthSummary.empty(2025, 3);

      expect(empty.year, equals(2025));
      expect(empty.month, equals(3));
      expect(empty.totalCount, equals(0));
      expect(empty.totalHkdAmountCents, equals(0));
    });
  });
}
