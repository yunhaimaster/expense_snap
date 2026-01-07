import 'dart:async';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';
import '../core/utils/app_logger.dart';

/// OCR 文字識別服務
///
/// 使用 Google ML Kit Text Recognition 進行離線文字識別
/// 支援繁/簡體中文 + 英文
class OcrService {
  OcrService({this.timeoutDuration = const Duration(seconds: 5)})
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  final TextRecognizer _textRecognizer;

  /// OCR 處理超時時間（預設 5 秒）
  final Duration timeoutDuration;

  /// 從圖片路徑執行 OCR
  ///
  /// [imagePath] - 圖片檔案路徑
  /// 返回識別結果，包含文字區塊和位置資訊
  Future<Result<RecognizedText>> recognizeText(String imagePath) async {
    try {
      // 驗證檔案存在
      final file = File(imagePath);
      if (!await file.exists()) {
        return Result.failure(StorageException.fileNotFound(imagePath));
      }

      AppLogger.info('Starting OCR for: $imagePath');
      final stopwatch = Stopwatch()..start();

      // 建立輸入圖片
      final inputImage = InputImage.fromFilePath(imagePath);

      // 執行文字識別（含超時處理）
      final RecognizedText recognizedText;
      try {
        recognizedText = await _textRecognizer
            .processImage(inputImage)
            .timeout(timeoutDuration);
      } on TimeoutException {
        stopwatch.stop();
        AppLogger.warning('OCR timeout after ${stopwatch.elapsedMilliseconds}ms');
        return Result.failure(OcrException.timeout());
      }

      stopwatch.stop();
      AppLogger.info(
        'OCR completed in ${stopwatch.elapsedMilliseconds}ms, '
        'found ${recognizedText.blocks.length} blocks, '
        '${recognizedText.text.length} chars',
      );

      return Result.success(recognizedText);
    } catch (e, stackTrace) {
      AppLogger.error('OCR failed', error: e, stackTrace: stackTrace);
      return Result.failure(
        OcrException('文字識別失敗: $e', code: 'OCR_FAILED'),
      );
    }
  }

  /// 釋放資源
  ///
  /// 應在不再需要 OCR 服務時呼叫
  Future<void> dispose() async {
    try {
      await _textRecognizer.close();
      AppLogger.info('OcrService disposed');
    } catch (e) {
      AppLogger.warning('Failed to dispose OcrService: $e');
    }
  }
}
