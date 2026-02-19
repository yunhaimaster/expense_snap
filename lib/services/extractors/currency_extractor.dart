import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 幣別偵測結果
class CurrencyDetectionResult {
  const CurrencyDetectionResult(this.code, {this.isExplicit = false});

  /// 幣別代碼
  final String code;

  /// 是否為明確識別（非 fallback）
  final bool isExplicit;
}

/// 幣別偵測器
class CurrencyDetector {
  CurrencyDetector._();

  /// 幣別模式：明確代碼/文字
  static const _explicitPatterns = {
    'HKD': [r'HKD', r'港幣', r'港元', r'HK\$'],
    'CNY': [r'CNY', r'RMB', r'人民幣', r'人民币'],
    'USD': [r'USD', r'美元', r'美金', r'US\$'],
  };

  /// 符號對應（需結合上下文判斷）
  static const _symbolPatterns = {
    r'¥|￥': 'CNY',
    r'元': 'CNY', // 「元」通常指人民幣
  };

  /// 偵測幣別
  ///
  /// 優先級：明確代碼/文字 > 符號 > 用戶預設
  static CurrencyDetectionResult detect(
    RecognizedText text,
    String defaultCurrency,
  ) {
    final fullText = text.text;

    // 1. 搜尋明確幣別代碼/文字
    for (final entry in _explicitPatterns.entries) {
      final currency = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(fullText)) {
          return CurrencyDetectionResult(currency, isExplicit: true);
        }
      }
    }

    // 2. 搜尋幣別符號
    for (final entry in _symbolPatterns.entries) {
      final pattern = entry.key;
      final currency = entry.value;

      final regex = RegExp(pattern);
      if (regex.hasMatch(fullText)) {
        return CurrencyDetectionResult(currency, isExplicit: true);
      }
    }

    // 3. $ 符號需要上下文判斷（可能是 HKD 或 USD）
    if (RegExp(r'\$').hasMatch(fullText)) {
      // 若文字包含香港相關詞彙，判斷為 HKD
      if (RegExp(r'香港|Hong Kong|HK', caseSensitive: false).hasMatch(fullText)) {
        return const CurrencyDetectionResult('HKD', isExplicit: true);
      }
      // 否則使用預設幣別（若預設是 HKD 或 USD）
      if (defaultCurrency == 'HKD' || defaultCurrency == 'USD') {
        return CurrencyDetectionResult(defaultCurrency, isExplicit: false);
      }
    }

    // 4. 使用用戶設定的預設幣別
    return CurrencyDetectionResult(defaultCurrency, isExplicit: false);
  }
}
