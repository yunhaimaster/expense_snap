import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/constants/expense_category.dart';
import 'category_suggester.dart';
import 'extractors/amount_extractor.dart';
import 'extractors/currency_extractor.dart';
import 'extractors/date_extractor.dart';
import 'extractors/description_extractor.dart';

// 重新匯出提取器類別，維持向後相容
export 'extractors/amount_extractor.dart'
    show AmountExtractionResult, AmountExtractor;
export 'extractors/currency_extractor.dart'
    show CurrencyDetectionResult, CurrencyDetector;
export 'extractors/date_extractor.dart' show DateExtractor;
export 'extractors/description_extractor.dart' show DescriptionExtractor;

/// 收據解析結果
class ReceiptParseResult {
  const ReceiptParseResult({
    this.currency,
    this.amountCents,
    this.description,
    this.date,
    this.suggestedCategory,
    this.confidence = 0.0,
    this.debugInfo,
  });

  /// 識別到的幣別代碼 (HKD/CNY/USD)
  final String? currency;

  /// 金額（分）
  final int? amountCents;

  /// 店名/描述
  final String? description;

  /// 識別到的日期
  final DateTime? date;

  /// 根據描述建議的分類
  final ExpenseCategory? suggestedCategory;

  /// 整體信心分數 0-1
  final double confidence;

  /// 除錯資訊（開發用）
  final String? debugInfo;

  /// 是否有識別到任何資訊
  bool get hasData =>
      currency != null ||
      amountCents != null ||
      description != null ||
      date != null ||
      suggestedCategory != null;

  @override
  String toString() {
    return 'ReceiptParseResult(currency: $currency, amountCents: $amountCents, '
        'description: $description, date: $date, suggestedCategory: $suggestedCategory, '
        'confidence: ${confidence.toStringAsFixed(2)})';
  }
}

/// 收據解析器
///
/// 負責解析 OCR 文字，提取結構化資料。
/// 委派各項提取工作給專用的提取器。
class ReceiptParser {
  ReceiptParser({
    required this.defaultCurrency,
    CategorySuggester? categorySuggester,
  }) : _categorySuggester = categorySuggester ?? CategorySuggester();

  /// 用戶預設幣別（fallback）
  final String defaultCurrency;

  /// 分類建議服務
  final CategorySuggester _categorySuggester;

  /// 解析 OCR 結果
  ReceiptParseResult parse(RecognizedText text) {
    if (text.blocks.isEmpty) {
      return const ReceiptParseResult();
    }

    // 委派各項提取工作給專用提取器
    final currency = CurrencyDetector.detect(text, defaultCurrency);
    final amountResult = AmountExtractor.extract(text);
    final description = DescriptionExtractor.extract(text);
    final date = DateExtractor.extract(text);

    // 根據描述建議分類
    final suggestedCategory = _categorySuggester.suggestFromText(description);

    // 計算整體信心分數
    double confidence = 0.0;
    int factors = 0;

    if (amountResult != null) {
      confidence += amountResult.confidence;
      factors++;
    }
    if (currency.isExplicit) {
      confidence += 0.9;
      factors++;
    }
    if (description != null) {
      confidence += 0.7;
      factors++;
    }
    if (date != null) {
      confidence += 0.8;
      factors++;
    }

    final avgConfidence = factors > 0 ? confidence / factors : 0.0;

    return ReceiptParseResult(
      currency: currency.code,
      amountCents: amountResult?.cents,
      description: description,
      date: date,
      suggestedCategory: suggestedCategory,
      confidence: avgConfidence,
    );
  }
}
