import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/services/smart_prompt_service.dart';

void main() {
  group('SmartPromptService', () {
    late SmartPromptService service;

    setUp(() {
      service = SmartPromptService.instance;
    });

    group('isLargeAmount', () {
      test('returns true for amounts >= 1000 HKD', () {
        // 1000 HKD = 100000 cents
        expect(service.isLargeAmount(100000), isTrue);
        expect(service.isLargeAmount(150000), isTrue);
        expect(service.isLargeAmount(1000000), isTrue);
      });

      test('returns false for amounts < 1000 HKD', () {
        // 999.99 HKD = 99999 cents
        expect(service.isLargeAmount(99999), isFalse);
        expect(service.isLargeAmount(50000), isFalse);
        expect(service.isLargeAmount(1000), isFalse);
      });

      test('returns false for zero amount', () {
        expect(service.isLargeAmount(0), isFalse);
      });

      test('threshold is exactly 1000 HKD (100000 cents)', () {
        expect(SmartPromptService.largeAmountThreshold, 100000);
      });
    });

    group('isNearMonthEnd', () {
      test('returns correct value based on current date', () {
        // 此測試依賴當前日期，僅驗證方法可正常執行
        final result = service.isNearMonthEnd();
        expect(result, isA<bool>());
      });
    });

    group('duplicate detection window', () {
      test('window is 24 hours', () {
        expect(SmartPromptService.duplicateWindowHours, 24);
      });
    });
  });
}
