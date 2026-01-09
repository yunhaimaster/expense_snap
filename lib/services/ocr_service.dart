import 'dart:async';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';
import '../core/utils/app_logger.dart';

/// OCR 文字識別服務
///
/// 使用 Google ML Kit Text Recognition 進行離線文字識別
/// 使用中文模型（bundled，離線可用），可識別中英文混合收據
class OcrService {
  OcrService({this.timeoutDuration = const Duration(seconds: 10)});

  /// OCR 處理超時時間（預設 10 秒，中文模型較慢）
  final Duration timeoutDuration;

  /// 延遲初始化的 TextRecognizer
  TextRecognizer? _textRecognizer;

  /// 初始化 Completer（用於處理並發初始化請求）
  Completer<TextRecognizer?>? _initCompleter;

  /// 使用的腳本類型（用於日誌）
  String _scriptType = 'unknown';

  /// 取得或初始化 TextRecognizer
  ///
  /// 使用中文腳本（bundled 模型，離線可用）
  /// 可識別中文、數字、金額、日期
  /// 使用 Completer 確保並發安全，避免重複初始化
  Future<TextRecognizer?> _getRecognizer() async {
    // 已初始化完成，直接返回
    if (_textRecognizer != null) return _textRecognizer;

    // 正在初始化中，等待完成
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // 開始初始化
    _initCompleter = Completer<TextRecognizer?>();

    try {
      AppLogger.info('Initializing Chinese text recognizer...');
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
      _scriptType = 'chinese';
      AppLogger.info('Chinese text recognizer initialized');
      _initCompleter!.complete(_textRecognizer);
      return _textRecognizer;
    } catch (e) {
      AppLogger.error('Failed to init Chinese recognizer: $e');
      _initCompleter!.complete(null);
      return null;
    }
  }

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

      // 取得或初始化 recognizer
      final recognizer = await _getRecognizer();
      if (recognizer == null) {
        return Result.failure(
          const OcrException('無法初始化文字識別器', code: 'RECOGNIZER_INIT_FAILED'),
        );
      }

      AppLogger.info('Starting OCR ($_scriptType) for: $imagePath');
      final stopwatch = Stopwatch()..start();

      // 建立輸入圖片
      final inputImage = InputImage.fromFilePath(imagePath);

      // 執行文字識別（含超時處理）
      final RecognizedText recognizedText;
      try {
        recognizedText = await recognizer
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
  /// 注意：不應在 OCR 操作進行中呼叫此方法
  Future<void> dispose() async {
    try {
      await _textRecognizer?.close();
      _textRecognizer = null;
      _initCompleter = null;
      _scriptType = 'unknown';
      AppLogger.info('OcrService disposed');
    } catch (e) {
      AppLogger.warning('Failed to dispose OcrService: $e');
    }
  }
}
