import 'package:expense_snap/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters', () {
    group('Amount conversion', () {
      test('should convert cents to amount', () {
        expect(Formatters.centsToAmount(10050), equals(100.50));
        expect(Formatters.centsToAmount(1), equals(0.01));
        expect(Formatters.centsToAmount(0), equals(0.0));
      });

      test('should convert amount to cents', () {
        expect(Formatters.amountToCents(100.50), equals(10050));
        expect(Formatters.amountToCents(0.01), equals(1));
        expect(Formatters.amountToCents(0), equals(0));
      });

      test('should handle rounding correctly', () {
        expect(Formatters.amountToCents(100.505), equals(10051)); // round up
        expect(Formatters.amountToCents(100.504), equals(10050)); // round down
      });
    });

    group('formatAmount', () {
      test('should format HKD correctly', () {
        expect(Formatters.formatAmount(250000, 'HKD'), equals('HK\$2,500.00'));
      });

      test('should format CNY correctly', () {
        expect(Formatters.formatAmount(10050, 'CNY'), equals('¥100.50'));
      });

      test('should format USD correctly', () {
        expect(Formatters.formatAmount(5000, 'USD'), equals('\$50.00'));
      });

      test('should format unknown currency with code', () {
        expect(Formatters.formatAmount(10000, 'EUR'), equals('EUR100.00'));
      });
    });

    group('formatAmountNumber', () {
      test('should format with thousand separator', () {
        expect(Formatters.formatAmountNumber(123456789), equals('1,234,567.89'));
      });

      test('should format small amount', () {
        expect(Formatters.formatAmountNumber(50), equals('0.50'));
      });
    });

    group('Exchange rate conversion', () {
      test('should convert stored rate to display', () {
        expect(Formatters.storedRateToDisplay(7800000), equals(7.8));
        expect(Formatters.storedRateToDisplay(1089000), equals(1.089));
      });

      test('should convert display rate to stored', () {
        expect(Formatters.displayRateToStored(7.8), equals(7800000));
        expect(Formatters.displayRateToStored(1.089), equals(1089000));
      });

      test('should format exchange rate', () {
        expect(Formatters.formatExchangeRate(7800000), equals('7.8000'));
        expect(Formatters.formatExchangeRate(1089000), equals('1.0890'));
      });
    });

    group('Date formatting', () {
      test('should format date for storage', () {
        final date = DateTime.utc(2025, 1, 15, 10, 30, 0);
        final formatted = Formatters.formatDateForStorage(date);

        expect(formatted, contains('2025-01-15'));
      });

      test('should parse date from storage', () {
        final parsed = Formatters.parseDateFromStorage('2025-01-15T10:30:00.000Z');

        expect(parsed, isNotNull);
        expect(parsed!.year, equals(2025));
        expect(parsed.month, equals(1));
        expect(parsed.day, equals(15));
      });

      test('should return null for invalid date string', () {
        final parsed = Formatters.parseDateFromStorage('invalid');
        expect(parsed, isNull);
      });

      test('should return null for null input', () {
        final parsed = Formatters.parseDateFromStorage(null);
        expect(parsed, isNull);
      });

      test('should format date as yyyy-MM-dd', () {
        final date = DateTime(2025, 1, 15);
        expect(Formatters.formatDate(date), equals('2025-01-15'));
      });

      test('should format month correctly', () {
        final date = DateTime(2025, 1, 15);
        expect(Formatters.formatMonth(date), equals('2025年1月'));
      });

      test('should format display date', () {
        final date = DateTime(2025, 1, 15);
        expect(Formatters.formatDisplayDate(date), equals('1月15日'));
      });
    });

    group('formatRelativeTime', () {
      test('should format just now', () {
        final now = DateTime.now();
        expect(Formatters.formatRelativeTime(now), equals('剛才'));
      });

      test('should format minutes ago', () {
        final time = DateTime.now().subtract(const Duration(minutes: 5));
        expect(Formatters.formatRelativeTime(time), equals('5分鐘前'));
      });

      test('should format hours ago', () {
        final time = DateTime.now().subtract(const Duration(hours: 3));
        expect(Formatters.formatRelativeTime(time), equals('3小時前'));
      });

      test('should format days ago', () {
        final time = DateTime.now().subtract(const Duration(days: 2));
        expect(Formatters.formatRelativeTime(time), equals('2天前'));
      });

      test('should format old dates as display date', () {
        final time = DateTime.now().subtract(const Duration(days: 10));
        final result = Formatters.formatRelativeTime(time);
        expect(result, contains('月'));
        expect(result, contains('日'));
      });
    });

    group('formatFileSize', () {
      test('should format bytes', () {
        expect(Formatters.formatFileSize(500), equals('500 B'));
      });

      test('should format kilobytes', () {
        expect(Formatters.formatFileSize(1536), equals('1.5 KB'));
      });

      test('should format megabytes', () {
        expect(Formatters.formatFileSize(5242880), equals('5.0 MB'));
      });

      test('should format gigabytes', () {
        expect(Formatters.formatFileSize(1073741824), equals('1.0 GB'));
      });
    });
  });
}
