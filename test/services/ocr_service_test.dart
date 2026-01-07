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
      expect(ocrService.timeoutDuration, const Duration(seconds: 5));
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
