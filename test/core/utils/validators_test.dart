import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    group('validateAmount', () {
      test('should accept valid amount', () {
        final result = Validators.validateAmount('100.50');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(10050)); // 分
      });

      test('should accept amount with commas', () {
        final result = Validators.validateAmount('1,234.56');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(123456));
      });

      test('should accept integer amount', () {
        final result = Validators.validateAmount('100');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(10000));
      });

      test('should reject null', () {
        final result = Validators.validateAmount(null);

        expect(result.isFailure, isTrue);
        expect((result as Failure).error, isA<ValidationException>());
      });

      test('should reject empty string', () {
        final result = Validators.validateAmount('');

        expect(result.isFailure, isTrue);
      });

      test('should reject non-numeric string', () {
        final result = Validators.validateAmount('abc');

        expect(result.isFailure, isTrue);
      });

      test('should reject amount below minimum', () {
        final result = Validators.validateAmount('0.001');

        expect(result.isFailure, isTrue);
      });

      test('should reject amount above maximum', () {
        final result = Validators.validateAmount('99999999.99');

        expect(result.isFailure, isTrue);
      });

      test('should reject too many decimal places', () {
        final result = Validators.validateAmount('100.123');

        expect(result.isFailure, isTrue);
      });
    });

    group('validateDescription', () {
      test('should accept valid description', () {
        final result = Validators.validateDescription('午餐 - 茶餐廳');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('午餐 - 茶餐廳'));
      });

      test('should trim whitespace', () {
        final result = Validators.validateDescription('  午餐  ');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('午餐'));
      });

      test('should reject null', () {
        final result = Validators.validateDescription(null);

        expect(result.isFailure, isTrue);
      });

      test('should reject empty string', () {
        final result = Validators.validateDescription('');

        expect(result.isFailure, isTrue);
      });

      test('should reject whitespace only', () {
        final result = Validators.validateDescription('   ');

        expect(result.isFailure, isTrue);
      });

      test('should reject description over 500 characters', () {
        final longDescription = 'a' * 501;
        final result = Validators.validateDescription(longDescription);

        expect(result.isFailure, isTrue);
      });

      test('should accept description at 500 characters', () {
        final exactDescription = 'a' * 500;
        final result = Validators.validateDescription(exactDescription);

        expect(result.isSuccess, isTrue);
      });
    });

    group('validateExchangeRate', () {
      test('should accept valid rate', () {
        final result = Validators.validateExchangeRate('7.8');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(7800000)); // ×10⁶
      });

      test('should accept rate with 4 decimal places', () {
        final result = Validators.validateExchangeRate('1.0890');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(1089000));
      });

      test('should reject null', () {
        final result = Validators.validateExchangeRate(null);

        expect(result.isFailure, isTrue);
      });

      test('should reject rate below minimum', () {
        final result = Validators.validateExchangeRate('0.00001');

        expect(result.isFailure, isTrue);
      });

      test('should reject rate above maximum', () {
        final result = Validators.validateExchangeRate('10000');

        expect(result.isFailure, isTrue);
      });

      test('should reject too many decimal places', () {
        final result = Validators.validateExchangeRate('1.12345');

        expect(result.isFailure, isTrue);
      });
    });

    group('validateDate', () {
      test('should accept today', () {
        final today = DateTime.now();
        final result = Validators.validateDate(today);

        expect(result.isSuccess, isTrue);
      });

      test('should accept past date', () {
        final past = DateTime.now().subtract(const Duration(days: 30));
        final result = Validators.validateDate(past);

        expect(result.isSuccess, isTrue);
      });

      test('should reject future date', () {
        final future = DateTime.now().add(const Duration(days: 1));
        final result = Validators.validateDate(future);

        expect(result.isFailure, isTrue);
      });

      test('should reject null', () {
        final result = Validators.validateDate(null);

        expect(result.isFailure, isTrue);
      });
    });

    group('validateUserName', () {
      test('should accept valid name', () {
        final result = Validators.validateUserName('張三');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('張三'));
      });

      test('should trim whitespace', () {
        final result = Validators.validateUserName('  張三  ');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('張三'));
      });

      test('should reject null', () {
        final result = Validators.validateUserName(null);

        expect(result.isFailure, isTrue);
      });

      test('should reject name over 50 characters', () {
        final longName = 'a' * 51;
        final result = Validators.validateUserName(longName);

        expect(result.isFailure, isTrue);
      });
    });

    group('validateCurrency', () {
      test('should accept supported currency', () {
        final result = Validators.validateCurrency(
          'HKD',
          supportedCurrencies: CurrencyConstants.supportedCurrencies,
        );

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('HKD'));
      });

      test('should reject unsupported currency', () {
        final result = Validators.validateCurrency(
          'EUR',
          supportedCurrencies: CurrencyConstants.supportedCurrencies,
        );

        expect(result.isFailure, isTrue);
      });

      test('should reject null', () {
        final result = Validators.validateCurrency(
          null,
          supportedCurrencies: CurrencyConstants.supportedCurrencies,
        );

        expect(result.isFailure, isTrue);
      });
    });
  });
}
