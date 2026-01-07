import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 收據解析結果
class ReceiptParseResult {
  const ReceiptParseResult({
    this.currency,
    this.amountCents,
    this.description,
    this.confidence = 0.0,
  });

  /// 識別到的幣別代碼 (HKD/CNY/USD)
  final String? currency;

  /// 金額（分）
  final int? amountCents;

  /// 店名/描述
  final String? description;

  /// 整體信心分數 0-1
  final double confidence;

  /// 是否有識別到任何資訊
  bool get hasData => currency != null || amountCents != null || description != null;

  @override
  String toString() {
    return 'ReceiptParseResult(currency: $currency, amountCents: $amountCents, '
        'description: $description, confidence: ${confidence.toStringAsFixed(2)})';
  }
}

/// 收據解析器
///
/// 負責解析 OCR 文字，提取結構化資料
class ReceiptParser {
  ReceiptParser({required this.defaultCurrency});

  /// 用戶預設幣別（fallback）
  final String defaultCurrency;

  /// 解析 OCR 結果
  ReceiptParseResult parse(RecognizedText text) {
    if (text.blocks.isEmpty) {
      return const ReceiptParseResult();
    }

    // 提取各欄位
    final currency = CurrencyDetector.detect(text, defaultCurrency);
    final amountResult = AmountExtractor.extract(text);
    final description = DescriptionExtractor.extract(text);

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

    final avgConfidence = factors > 0 ? confidence / factors : 0.0;

    return ReceiptParseResult(
      currency: currency.code,
      amountCents: amountResult?.cents,
      description: description,
      confidence: avgConfidence,
    );
  }
}

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
  static CurrencyDetectionResult detect(RecognizedText text, String defaultCurrency) {
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

/// 金額提取結果
class AmountExtractionResult {
  const AmountExtractionResult(this.cents, {this.confidence = 0.5});

  /// 金額（分）
  final int cents;

  /// 信心分數
  final double confidence;
}

/// 金額提取器
class AmountExtractor {
  AmountExtractor._();

  /// 總計關鍵字（中英文）
  static const _totalKeywords = [
    '總計', '总计', 'Total', 'TOTAL',
    '合計', '合计', '應付', '应付',
    '實付', '实付', 'Amount', 'AMOUNT',
    '金額', '金额', '付款', '小計', '小计',
    'Grand Total', 'Subtotal', 'Sum',
  ];

  /// 金額正則：支援 123.45, 123,456.78, $123.45 等格式
  static final _amountRegex = RegExp(
    r'[\$￥¥]?\s*(\d{1,3}(?:[,，]\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
  );

  /// 電話號碼過濾（8位以上連續數字）
  static final _phoneRegex = RegExp(r'\d{8,}');

  /// 日期過濾
  static final _dateRegex = RegExp(
    r'\d{4}[-/年]\d{1,2}[-/月]\d{1,2}|'
    r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}',
  );

  /// 提取金額
  ///
  /// Hybrid 策略：關鍵字優先 + 位置判斷
  static AmountExtractionResult? extract(RecognizedText text) {
    // 1. 找關鍵字旁的金額（高信心）
    final keywordAmount = _findAmountNearKeyword(text);
    if (keywordAmount != null) {
      return keywordAmount;
    }

    // 2. Fallback: 底部區域最大金額（中等信心）
    return _findLargestAmountInBottomHalf(text);
  }

  /// 在總計關鍵字附近找金額
  static AmountExtractionResult? _findAmountNearKeyword(RecognizedText text) {
    for (final block in text.blocks) {
      for (final line in block.lines) {
        final lineText = line.text;

        // 檢查是否包含總計關鍵字
        for (final keyword in _totalKeywords) {
          if (lineText.contains(keyword)) {
            // 在同一行找金額
            final amount = _extractAmountFromText(lineText);
            if (amount != null) {
              return AmountExtractionResult(amount, confidence: 0.9);
            }
          }
        }
      }
    }
    return null;
  }

  /// 在收據底部找最大金額
  static AmountExtractionResult? _findLargestAmountInBottomHalf(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // 計算整體高度範圍
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final block in text.blocks) {
      final boundingBox = block.boundingBox;
      if (boundingBox.top < minY) minY = boundingBox.top;
      if (boundingBox.bottom > maxY) maxY = boundingBox.bottom;
    }

    final midY = (minY + maxY) / 2;
    int? largestAmount;

    // 只搜尋下半部
    for (final block in text.blocks) {
      if (block.boundingBox.top < midY) continue;

      for (final line in block.lines) {
        final amount = _extractAmountFromText(line.text);
        if (amount != null && (largestAmount == null || amount > largestAmount)) {
          largestAmount = amount;
        }
      }
    }

    if (largestAmount != null) {
      return AmountExtractionResult(largestAmount, confidence: 0.6);
    }
    return null;
  }

  /// 從文字中提取金額（轉換為分）
  static int? _extractAmountFromText(String text) {
    // 過濾電話號碼和日期
    final cleanedText = text
        .replaceAll(_phoneRegex, '')
        .replaceAll(_dateRegex, '');

    final matches = _amountRegex.allMatches(cleanedText);
    int? maxAmount;

    for (final match in matches) {
      final amountStr = match.group(1);
      if (amountStr == null) continue;

      // 移除千分位符號
      final normalized = amountStr.replaceAll(RegExp(r'[,，]'), '');
      final amount = double.tryParse(normalized);

      if (amount != null && amount > 0 && amount < 1000000) {
        // 限制合理金額範圍
        final cents = (amount * 100).round();
        if (maxAmount == null || cents > maxAmount) {
          maxAmount = cents;
        }
      }
    }

    return maxAmount;
  }
}

/// 描述提取器
class DescriptionExtractor {
  DescriptionExtractor._();

  /// 店名關鍵字
  static final _storeKeywords = RegExp(
    r'店|餐廳|餐厅|公司|商店|超市|酒樓|酒楼|'
    r'商場|商场|百貨|百货|便利店|茶餐廳|茶餐厅|'
    r'Restaurant|Store|Shop|Market|Mall|Co\.|Ltd',
    caseSensitive: false,
  );

  /// 需要過濾的內容
  static final _filterPatterns = [
    // 地址（避免誤判超市、公司等）
    RegExp(r'地址|Address|號$|号$|\d+樓|\d+楼|路$|街$|道中|道西|道東|大道', caseSensitive: false),
    // 電話
    RegExp(r'電話|电话|Tel|Phone', caseSensitive: false),
    // 日期時間
    RegExp(r'\d{4}[-/年]\d{1,2}[-/月]|\d{1,2}:\d{2}'),
    // 收據編號
    RegExp(r'單號|单号|Invoice|Receipt No', caseSensitive: false),
    // 金額相關
    RegExp(r'總計|总计|Total|Amount|小計|小计|￥|¥|\$\d', caseSensitive: false),
  ];

  /// 提取描述（店名）
  ///
  /// 策略：收據頂部文字，過濾非店名內容
  static String? extract(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // 找最上方的幾個區塊（通常是店名）
    final sortedBlocks = List<TextBlock>.from(text.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 檢查前 3 個區塊
    for (var i = 0; i < sortedBlocks.length && i < 3; i++) {
      final block = sortedBlocks[i];

      for (final line in block.lines) {
        final lineText = line.text.trim();

        // 跳過太短或太長的文字
        if (lineText.length < 2 || lineText.length > 50) continue;

        // 檢查是否需要過濾
        bool shouldFilter = false;
        for (final pattern in _filterPatterns) {
          if (pattern.hasMatch(lineText)) {
            shouldFilter = true;
            break;
          }
        }
        if (shouldFilter) continue;

        // 優先選擇包含店名關鍵字的
        if (_storeKeywords.hasMatch(lineText)) {
          return _cleanDescription(lineText);
        }

        // 若沒有關鍵字但是純文字（非數字為主），也可考慮
        if (_isLikelyStoreName(lineText)) {
          return _cleanDescription(lineText);
        }
      }
    }

    return null;
  }

  /// 判斷是否像店名
  static bool _isLikelyStoreName(String text) {
    // 數字佔比不超過 30%
    final digits = text.replaceAll(RegExp(r'[^\d]'), '').length;
    final ratio = digits / text.length;
    return ratio < 0.3;
  }

  /// 清理描述文字
  static String _cleanDescription(String text) {
    // 移除多餘空白
    var cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 限制長度
    if (cleaned.length > 30) {
      cleaned = '${cleaned.substring(0, 30)}...';
    }

    return cleaned;
  }
}
