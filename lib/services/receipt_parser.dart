import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 收據解析結果
class ReceiptParseResult {
  const ReceiptParseResult({
    this.currency,
    this.amountCents,
    this.description,
    this.date,
    this.confidence = 0.0,
  });

  /// 識別到的幣別代碼 (HKD/CNY/USD)
  final String? currency;

  /// 金額（分）
  final int? amountCents;

  /// 店名/描述
  final String? description;

  /// 識別到的日期
  final DateTime? date;

  /// 整體信心分數 0-1
  final double confidence;

  /// 是否有識別到任何資訊
  bool get hasData =>
      currency != null || amountCents != null || description != null || date != null;

  @override
  String toString() {
    return 'ReceiptParseResult(currency: $currency, amountCents: $amountCents, '
        'description: $description, date: $date, confidence: ${confidence.toStringAsFixed(2)})';
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
    final date = DateExtractor.extract(text);

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

  /// 店名關鍵字（擴充版）
  static final _storeKeywords = RegExp(
    // 餐飲
    r'餐廳|餐厅|茶餐廳|茶餐厅|酒樓|酒楼|飯店|饭店|食堂|'
    r'咖啡|Cafe|Coffee|麵包|面包|Bakery|麥當勞|麦当劳|肯德基|星巴克|'
    // 零售
    r'店|商店|超市|便利店|7-?Eleven|OK便利|惠康|百佳|AEON|'
    r'商場|商场|百貨|百货|Mall|Plaza|Center|Centre|'
    // 公司
    r'公司|有限|Co\.|Ltd|Corp|Inc|'
    // 服務
    r'藥房|药房|診所|诊所|醫院|医院|理髮|理发|美容|'
    // 交通
    r'的士|出租車|Taxi|Uber|港鐵|地鐵|巴士|'
    // 英文
    r'Restaurant|Store|Shop|Market|Hotel|Motel',
    caseSensitive: false,
  );

  /// 商品/服務關鍵字（用於提取項目描述）
  static final _itemKeywords = RegExp(
    r'午餐|晚餐|早餐|套餐|飲料|飲品|咖啡|奶茶|'
    r'車費|車票|機票|住宿|酒店|'
    r'文具|辦公|電腦|手機|'
    r'Lunch|Dinner|Breakfast|Meal|Coffee|Tea',
    caseSensitive: false,
  );

  /// 需要過濾的內容
  static final _filterPatterns = [
    // 地址
    RegExp(r'地址|Address|號$|号$|\d+樓|\d+楼|路$|街$|道$|大道|大廈|大厦', caseSensitive: false),
    // 電話
    RegExp(r'電話|电话|Tel|Phone|Fax|\d{8,}', caseSensitive: false),
    // 日期時間
    RegExp(r'\d{4}[-/年]\d{1,2}[-/月]|\d{1,2}:\d{2}'),
    // 收據編號
    RegExp(r'單號|单号|Invoice|Receipt|Order|訂單|编号|編號', caseSensitive: false),
    // 金額相關
    RegExp(r'總計|总计|Total|Amount|小計|小计|合計|应付|應付|找續|找赎', caseSensitive: false),
    // 付款方式
    RegExp(r'現金|现金|Cash|信用卡|Credit|Visa|Master|八達通|支付寶|微信', caseSensitive: false),
    // 常見無意義內容
    RegExp(r'歡迎光臨|欢迎光临|謝謝|谢谢|Thank|Welcome|多謝|再見', caseSensitive: false),
    // 純數字行
    RegExp(r'^\d+$'),
    // 稅務相關
    RegExp(r'稅|税|VAT|GST', caseSensitive: false),
  ];

  /// 提取描述（店名或商品項目）
  ///
  /// 策略：
  /// 1. 優先找收據頂部的店名
  /// 2. 若找不到店名，嘗試找商品項目
  static String? extract(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // 找最上方的幾個區塊（通常是店名）
    final sortedBlocks = List<TextBlock>.from(text.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 第一輪：找店名（頂部，含關鍵字）
    for (var i = 0; i < sortedBlocks.length && i < 4; i++) {
      final block = sortedBlocks[i];

      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        // 優先選擇包含店名關鍵字的
        if (_storeKeywords.hasMatch(lineText)) {
          return _cleanDescription(lineText);
        }
      }
    }

    // 第二輪：找有意義的文字（頂部，非數字為主）
    for (var i = 0; i < sortedBlocks.length && i < 3; i++) {
      final block = sortedBlocks[i];

      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        if (_isLikelyStoreName(lineText)) {
          return _cleanDescription(lineText);
        }
      }
    }

    // 第三輪：找商品/服務項目（中間區域）
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        if (_itemKeywords.hasMatch(lineText)) {
          return _cleanDescription(lineText);
        }
      }
    }

    return null;
  }

  /// 檢查是否為有效候選
  static bool _isValidCandidate(String text) {
    return text.length >= 2 && text.length <= 50;
  }

  /// 檢查是否需要過濾
  static bool _shouldFilter(String text) {
    for (final pattern in _filterPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// 判斷是否像店名
  static bool _isLikelyStoreName(String text) {
    // 數字佔比不超過 25%
    final digits = text.replaceAll(RegExp(r'[^\d]'), '').length;
    final ratio = digits / text.length;

    // 至少包含 2 個中文字或 4 個英文字母
    final hasChineseChars = RegExp(r'[\u4e00-\u9fa5]{2,}').hasMatch(text);
    final hasEnglishWords = RegExp(r'[a-zA-Z]{4,}').hasMatch(text);

    return ratio < 0.25 && (hasChineseChars || hasEnglishWords);
  }

  /// 清理描述文字
  static String _cleanDescription(String text) {
    // 移除多餘空白和特殊符號
    var cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[*#\-_=]+|[*#\-_=]+$'), '')
        .trim();

    // 移除括號內的地址/電話
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\d{6,}[^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'（[^）]*\d{6,}[^）]*）'), '');

    // 限制長度
    if (cleaned.length > 30) {
      cleaned = '${cleaned.substring(0, 27)}...';
    }

    return cleaned.trim();
  }
}

/// 日期格式順序
enum _DateOrder { ymd, dmy, mdy }

/// 日期模式配置
class _DatePattern {
  const _DatePattern(this.pattern, this.order, {this.twoDigitYear = false});
  final RegExp pattern;
  final _DateOrder order;
  final bool twoDigitYear;
}

/// 日期提取器
class DateExtractor {
  DateExtractor._();

  /// 日期格式正則（使用結構化配置，避免字串比對）
  /// 支援：2024-01-15, 2024/01/15, 2024年1月15日, 15/01/2024
  static final _datePatterns = [
    // yyyy-MM-dd 或 yyyy/MM/dd（ISO 格式，最常見）
    _DatePattern(
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'),
      _DateOrder.ymd,
    ),
    // yyyy年M月d日（中文格式）
    _DatePattern(
      RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日?'),
      _DateOrder.ymd,
    ),
    // dd/MM/yyyy 或 dd-MM-yyyy（歐洲/亞洲格式，日在前）
    _DatePattern(
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})'),
      _DateOrder.dmy,
    ),
    // MM/dd/yy（美式兩位年份）
    _DatePattern(
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2})(?!\d)'),
      _DateOrder.mdy,
      twoDigitYear: true,
    ),
  ];

  /// 提取日期
  ///
  /// 搜尋收據中的日期，返回最可能的日期
  /// 注意：對於 dd/MM/yyyy 與 MM/dd/yyyy 的歧義，預設採用 dd/MM/yyyy（亞洲慣例）
  static DateTime? extract(RecognizedText text) {
    final fullText = text.text;
    final now = DateTime.now();

    // 嘗試各種日期格式（按優先順序）
    for (final config in _datePatterns) {
      final matches = config.pattern.allMatches(fullText);

      for (final match in matches) {
        final date = _parseMatch(match, config);
        if (date != null && _isReasonableDate(date, now)) {
          return date;
        }
      }
    }

    return null;
  }

  /// 解析匹配結果為日期
  static DateTime? _parseMatch(RegExpMatch match, _DatePattern config) {
    try {
      int year, month, day;

      // 根據配置的順序解析
      switch (config.order) {
        case _DateOrder.ymd:
          year = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          day = int.parse(match.group(3)!);
        case _DateOrder.dmy:
          day = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          year = int.parse(match.group(3)!);
        case _DateOrder.mdy:
          month = int.parse(match.group(1)!);
          day = int.parse(match.group(2)!);
          year = int.parse(match.group(3)!);
      }

      // 兩位年份轉換（00-99 → 2000-2099 或 1900-1999）
      if (config.twoDigitYear && year < 100) {
        // 假設 00-50 為 2000-2050，51-99 為 1951-1999
        year += year <= 50 ? 2000 : 1900;
      }

      // 基本範圍驗證
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      // 建構日期並驗證（DateTime 會自動正規化無效日期如 Feb 30 → Mar 2）
      final date = DateTime(year, month, day);

      // 驗證日期未被正規化（表示輸入的日/月有效）
      if (date.year != year || date.month != month || date.day != day) {
        return null; // 無效日期如 Feb 30
      }

      return date;
    } catch (e) {
      return null;
    }
  }

  /// 檢查日期是否合理（不超過今天，不早於一年前）
  static bool _isReasonableDate(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final oneYearAgo = today.subtract(const Duration(days: 365));
    return !date.isAfter(today) && date.isAfter(oneYearAgo);
  }
}
