import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/services/ocr_service.dart';
import 'package:expense_snap/core/errors/app_exception.dart';

void main() {
  group('OcrService', () {
    late OcrService ocrService;

    setUp(() {
      ocrService = OcrService();
    });

    tearDown(() async {
      await ocrService.dispose();
    });

    test('creates service successfully', () {
      expect(ocrService, isNotNull);
    });

    test('creates service with custom timeout', () {
      final customService = OcrService(
        timeoutDuration: const Duration(seconds: 10),
      );
      expect(customService.timeoutDuration, const Duration(seconds: 10));
      customService.dispose();
    });

    test('default timeout is 5 seconds', () {
      // 優化後預設 5 秒
      expect(ocrService.timeoutDuration, const Duration(seconds: 5));
    });

    test('default rate limit is 2 seconds', () {
      expect(ocrService.rateLimitDuration, const Duration(seconds: 2));
    });

    test('creates service with custom rate limit', () {
      final customService = OcrService(
        rateLimitDuration: const Duration(seconds: 5),
      );
      expect(customService.rateLimitDuration, const Duration(seconds: 5));
      customService.dispose();
    });

    test('dispose completes without error', () async {
      await expectLater(ocrService.dispose(), completes);
    });

    test('recognizeText returns failure for non-existent file', () async {
      final result = await ocrService.recognizeText('/non/existent/path.jpg');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<StorageException>());
      expect(result.errorOrNull?.code, 'FILE_NOT_FOUND');
    });

    test('recognizeText returns failure for empty path', () async {
      final result = await ocrService.recognizeText('');

      expect(result.isFailure, isTrue);
    });
  });

  group('OcrService rate limiting', () {
    test('first request has no rate limit', () {
      final service = OcrService();
      final remaining = service.getRateLimitRemaining();
      expect(remaining, isNull);
      service.dispose();
    });

    test('second request within rate limit returns remaining time', () async {
      final service = OcrService(
        rateLimitDuration: const Duration(seconds: 2),
      );

      // 第一次請求（會失敗因為檔案不存在，但會記錄時間）
      await service.recognizeText('/fake/path.jpg');

      // 立即檢查速率限制
      final remaining = service.getRateLimitRemaining();
      expect(remaining, isNotNull);
      expect(remaining!.inMilliseconds, greaterThan(0));
      expect(remaining.inMilliseconds, lessThanOrEqualTo(2000));

      await service.dispose();
    });

    test('rate limit expires after duration', () async {
      // 使用非常短的速率限制來測試
      final service = OcrService(
        rateLimitDuration: const Duration(milliseconds: 50),
      );

      // 第一次請求
      await service.recognizeText('/fake/path.jpg');

      // 等待速率限制過期
      await Future.delayed(const Duration(milliseconds: 60));

      // 應該沒有剩餘時間
      final remaining = service.getRateLimitRemaining();
      expect(remaining, isNull);

      await service.dispose();
    });

    test('rate limited request returns RateLimited error', () async {
      final service = OcrService(
        rateLimitDuration: const Duration(seconds: 2),
      );

      // 第一次請求
      await service.recognizeText('/fake/path1.jpg');

      // 第二次請求應該被速率限制
      final result = await service.recognizeText('/fake/path2.jpg');

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<OcrException>());
      expect(result.errorOrNull?.code, 'RATE_LIMITED');

      await service.dispose();
    });

    test('dispose clears rate limit state', () async {
      final service = OcrService();

      // 第一次請求
      await service.recognizeText('/fake/path.jpg');

      // 應該有速率限制
      expect(service.getRateLimitRemaining(), isNotNull);

      // dispose
      await service.dispose();

      // 重新創建服務
      final newService = OcrService();

      // 應該沒有速率限制（新實例）
      expect(newService.getRateLimitRemaining(), isNull);

      await newService.dispose();
    });
  });

  group('OcrException', () {
    test('timeout factory creates correct exception', () {
      final exception = OcrException.timeout();

      expect(exception.message, '文字識別超時');
      expect(exception.code, 'OCR_TIMEOUT');
    });

    test('noTextFound factory creates correct exception', () {
      final exception = OcrException.noTextFound();

      expect(exception.message, '無法識別文字');
      expect(exception.code, 'NO_TEXT_FOUND');
    });

    test('rateLimited factory creates correct exception', () {
      final exception =
          OcrException.rateLimited(const Duration(milliseconds: 1500));

      expect(exception.message, '請稍候 1.5 秒後再試');
      expect(exception.code, 'RATE_LIMITED');
    });

    test('rateLimited with whole seconds', () {
      final exception =
          OcrException.rateLimited(const Duration(seconds: 2));

      expect(exception.message, '請稍候 2.0 秒後再試');
      expect(exception.code, 'RATE_LIMITED');
    });

    test('custom message and code', () {
      const exception = OcrException('Custom error', code: 'CUSTOM_CODE');

      expect(exception.message, 'Custom error');
      expect(exception.code, 'CUSTOM_CODE');
    });

    test('toString includes message', () {
      const exception = OcrException('Test error');

      expect(exception.toString(), contains('Test error'));
    });
  });
}
