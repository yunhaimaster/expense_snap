import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/constants/expense_category.dart';
import 'category_suggester.dart';

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
/// 負責解析 OCR 文字，提取結構化資料
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

    // 提取各欄位
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

/// 金額候選
class _AmountCandidate {
  _AmountCandidate({
    required this.cents,
    required this.lineText,
    required this.lineIndex,
    required this.positionY,
    this.hasKeyword = false,
    this.keywordType = _KeywordType.none,
  });

  final int cents;
  final String lineText;
  final int lineIndex;
  final double positionY;
  final bool hasKeyword;
  final _KeywordType keywordType;

  double get score {
    double s = 0.0;

    // 關鍵字加分
    switch (keywordType) {
      case _KeywordType.total:
        s += 50.0; // 總計最高分
      case _KeywordType.subtotal:
        s += 20.0; // 小計中等分
      case _KeywordType.amount:
        s += 30.0; // 金額/應付
      case _KeywordType.none:
        s += 0.0;
    }

    return s;
  }
}

/// 關鍵字類型
enum _KeywordType { none, total, subtotal, amount }

/// 金額提取器（改進版）
///
/// 使用多階段策略提取金額：
/// 1. 識別所有金額候選
/// 2. 過濾負面關鍵字（找續、折扣等）
/// 3. 根據關鍵字、位置、上下文評分
/// 4. 選擇最佳候選
class AmountExtractor {
  AmountExtractor._();

  /// 總計關鍵字（高優先級）- 支援模糊匹配
  static const _totalKeywords = [
    // 中文
    '總計', '总计', '合計', '合计',
    '實付', '实付', '應付', '应付',
    '付款', '結帳', '结帐', '結算', '结算',
    // 英文
    'Total', 'TOTAL', 'Grand Total', 'GRAND TOTAL',
    'Amount Due', 'Balance Due', 'Net Total',
  ];

  /// 小計關鍵字（中優先級）
  static const _subtotalKeywords = [
    '小計', '小计', 'Subtotal', 'SUBTOTAL', 'Sub-total', 'Sub Total',
  ];

  /// 金額關鍵字（中優先級）
  static const _amountKeywords = [
    '金額', '金额', 'Amount', 'AMOUNT', 'Sum', 'SUM',
  ];

  /// 負面關鍵字（需要排除的行）
  /// 注意：這些關鍵字會匹配行內任何位置
  static final _negativeKeywords = RegExp(
    // 找續/找零
    r'找續|找赎|找零|Change|'
    // 折扣
    r'折扣|折讓|折让|優惠|优惠|Discount|'
    // 儲值/餘額
    r'儲值|储值|餘額|余额|餘款|余款|'
    // 押金
    r'押金|Deposit|'
    // 積分/點數
    r'積分|积分|點數|点数|Points|'
    // 小費
    r'小費|小费|Tips?|Gratuity',
    caseSensitive: false,
  );

  /// 需要完全匹配的負面關鍵字（獨立行）
  /// 這些詞彙只有在整行只有這個詞時才排除
  static const _exactMatchNegatives = [
    '稅', '税', 'Tax', 'TAX', 'VAT', 'GST',
    '服務費', '服务费', 'Service',
    '減', '减', 'Off', 'OFF',
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

  /// 時間過濾
  static final _timeRegex = RegExp(r'\d{1,2}:\d{2}(:\d{2})?');

  /// 提取金額
  static AmountExtractionResult? extract(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // 第一階段：收集所有金額候選
    final candidates = _collectCandidates(text);
    if (candidates.isEmpty) return null;

    // 第二階段：過濾負面關鍵字
    final filtered = _filterNegatives(candidates);
    if (filtered.isEmpty) {
      // 如果全部被過濾，退回到原始候選但給予低信心度
      final best = _selectBest(candidates, text);
      return best != null
          ? AmountExtractionResult(best.cents, confidence: 0.3)
          : null;
    }

    // 第三階段：選擇最佳候選
    final best = _selectBest(filtered, text);
    if (best == null) return null;

    // 計算信心度
    double confidence = 0.5;
    if (best.keywordType == _KeywordType.total) {
      confidence = 0.95;
    } else if (best.keywordType == _KeywordType.amount) {
      confidence = 0.85;
    } else if (best.keywordType == _KeywordType.subtotal) {
      // 小計只有在沒有總計時才使用
      confidence = 0.7;
    } else {
      confidence = 0.6; // fallback
    }

    return AmountExtractionResult(best.cents, confidence: confidence);
  }

  /// 收集所有金額候選
  static List<_AmountCandidate> _collectCandidates(RecognizedText text) {
    final candidates = <_AmountCandidate>[];
    int lineIndex = 0;

    for (final block in text.blocks) {
      for (final line in block.lines) {
        final lineText = line.text;
        final positionY = block.boundingBox.top;

        // 檢測關鍵字類型
        final keywordType = _detectKeywordType(lineText);

        // 提取金額
        final amounts = _extractAmountsFromText(lineText);
        for (final cents in amounts) {
          candidates.add(_AmountCandidate(
            cents: cents,
            lineText: lineText,
            lineIndex: lineIndex,
            positionY: positionY,
            hasKeyword: keywordType != _KeywordType.none,
            keywordType: keywordType,
          ));
        }

        lineIndex++;
      }
    }

    return candidates;
  }

  /// 檢測行中的關鍵字類型
  static _KeywordType _detectKeywordType(String text) {
    final normalizedText = text.toLowerCase();

    // 檢查總計關鍵字（支援模糊匹配）
    for (final keyword in _totalKeywords) {
      if (_fuzzyContains(normalizedText, keyword.toLowerCase())) {
        return _KeywordType.total;
      }
    }

    // 檢查金額關鍵字
    for (final keyword in _amountKeywords) {
      if (_fuzzyContains(normalizedText, keyword.toLowerCase())) {
        return _KeywordType.amount;
      }
    }

    // 檢查小計關鍵字
    for (final keyword in _subtotalKeywords) {
      if (_fuzzyContains(normalizedText, keyword.toLowerCase())) {
        return _KeywordType.subtotal;
      }
    }

    return _KeywordType.none;
  }

  /// 模糊匹配（處理 OCR 常見錯誤）
  static bool _fuzzyContains(String text, String keyword) {
    // 精確匹配
    if (text.contains(keyword)) return true;

    // OCR 常見錯誤替換
    final variations = _generateOcrVariations(keyword);
    for (final variation in variations) {
      if (text.contains(variation)) return true;
    }

    return false;
  }

  /// 生成 OCR 常見錯誤變體
  static List<String> _generateOcrVariations(String keyword) {
    final variations = <String>[];

    // 常見 OCR 替換
    final replacements = {
      'o': ['0', 'O'],
      'O': ['0', 'o'],
      '0': ['o', 'O'],
      'l': ['1', 'I', '|'],
      '1': ['l', 'I', '|'],
      'I': ['l', '1', '|'],
      'i': ['1', 'l'],
      's': ['5', 'S'],
      'S': ['5', 's'],
      '5': ['s', 'S'],
      'a': ['@', 'A'],
      'e': ['3'],
      'g': ['9', 'q'],
      'B': ['8', '3'],
      ' ': ['', '.', '_'], // 空格可能被誤識別或丟失
    };

    // 生成單字元替換變體
    for (var i = 0; i < keyword.length; i++) {
      final char = keyword[i];
      if (replacements.containsKey(char)) {
        for (final replacement in replacements[char]!) {
          final variation = keyword.substring(0, i) +
              replacement +
              keyword.substring(i + 1);
          variations.add(variation);
        }
      }
    }

    // 添加無空格版本
    if (keyword.contains(' ')) {
      variations.add(keyword.replaceAll(' ', ''));
      variations.add(keyword.replaceAll(' ', '.'));
    }

    return variations;
  }

  /// 過濾包含負面關鍵字的候選
  static List<_AmountCandidate> _filterNegatives(List<_AmountCandidate> candidates) {
    return candidates.where((c) {
      // 檢查部分匹配的負面關鍵字
      if (_negativeKeywords.hasMatch(c.lineText)) return false;

      // 檢查完全匹配的負面關鍵字（整行只有這個詞）
      final trimmed = c.lineText.trim();
      for (final exact in _exactMatchNegatives) {
        if (trimmed.toLowerCase() == exact.toLowerCase()) return false;
      }

      return true;
    }).toList();
  }

  /// 選擇最佳候選
  static _AmountCandidate? _selectBest(
    List<_AmountCandidate> candidates,
    RecognizedText text,
  ) {
    if (candidates.isEmpty) return null;

    // 檢查是否有「總計」關鍵字的候選
    final totalCandidates = candidates
        .where((c) => c.keywordType == _KeywordType.total)
        .toList();

    if (totalCandidates.isNotEmpty) {
      // 如果有多個總計行，選擇金額最大的（通常是最終總計）
      totalCandidates.sort((a, b) => b.cents.compareTo(a.cents));
      return totalCandidates.first;
    }

    // 檢查「金額」關鍵字的候選
    final amountCandidates = candidates
        .where((c) => c.keywordType == _KeywordType.amount)
        .toList();

    if (amountCandidates.isNotEmpty) {
      amountCandidates.sort((a, b) => b.cents.compareTo(a.cents));
      return amountCandidates.first;
    }

    // 檢查「小計」關鍵字的候選
    final subtotalCandidates = candidates
        .where((c) => c.keywordType == _KeywordType.subtotal)
        .toList();

    if (subtotalCandidates.isNotEmpty) {
      subtotalCandidates.sort((a, b) => b.cents.compareTo(a.cents));
      return subtotalCandidates.first;
    }

    // Fallback: 使用位置啟發式
    return _selectByPosition(candidates, text);
  }

  /// 根據位置選擇（fallback 策略）
  static _AmountCandidate? _selectByPosition(
    List<_AmountCandidate> candidates,
    RecognizedText text,
  ) {
    if (candidates.isEmpty) return null;

    // 計算整體高度範圍
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final block in text.blocks) {
      final boundingBox = block.boundingBox;
      if (boundingBox.top < minY) minY = boundingBox.top;
      if (boundingBox.bottom > maxY) maxY = boundingBox.bottom;
    }

    final height = maxY - minY;
    if (height <= 0) return candidates.first;

    // 策略：優先選擇下方 1/3 區域的最後一個合理金額
    final bottomThird = minY + height * 0.67;

    // 篩選下方 1/3 的候選
    var bottomCandidates = candidates
        .where((c) => c.positionY >= bottomThird)
        .toList();

    // 如果下方沒有候選，使用下半部
    if (bottomCandidates.isEmpty) {
      final midY = minY + height * 0.5;
      bottomCandidates = candidates
          .where((c) => c.positionY >= midY)
          .toList();
    }

    // 如果還是沒有，使用全部
    if (bottomCandidates.isEmpty) {
      bottomCandidates = candidates;
    }

    // 在底部候選中，選擇位置最靠後（lineIndex 最大）的
    // 如果有多個同位置的，選擇金額較大的
    bottomCandidates.sort((a, b) {
      final lineCompare = b.lineIndex.compareTo(a.lineIndex);
      if (lineCompare != 0) return lineCompare;
      return b.cents.compareTo(a.cents);
    });

    return bottomCandidates.first;
  }

  /// 從文字中提取所有金額（轉換為分）
  static List<int> _extractAmountsFromText(String text) {
    // 過濾電話號碼、日期、時間
    final cleanedText = text
        .replaceAll(_phoneRegex, ' ')
        .replaceAll(_dateRegex, ' ')
        .replaceAll(_timeRegex, ' ');

    final matches = _amountRegex.allMatches(cleanedText);
    final amounts = <int>[];

    for (final match in matches) {
      final amountStr = match.group(1);
      if (amountStr == null) continue;

      // 移除千分位符號
      final normalized = amountStr.replaceAll(RegExp(r'[,，]'), '');
      final amount = double.tryParse(normalized);

      if (amount != null && amount > 0 && amount < 1000000) {
        // 限制合理金額範圍
        final cents = (amount * 100).round();
        amounts.add(cents);
      }
    }

    return amounts;
  }
}

/// 描述提取器（改進版）
///
/// 使用多種信號識別店名：
/// 1. 文字大小（bounding box 高度）
/// 2. 位置（頂部優先）
/// 3. 關鍵字匹配
/// 4. 文字特徵（中文/英文比例）
class DescriptionExtractor {
  DescriptionExtractor._();

  /// 店名關鍵字（擴充版）
  static final _storeKeywords = RegExp(
    // 餐飲
    r'餐廳|餐厅|茶餐廳|茶餐厅|酒樓|酒楼|飯店|饭店|食堂|'
    r'咖啡|Cafe|Coffee|麵包|面包|Bakery|麥當勞|麦当劳|肯德基|星巴克|'
    r'快餐|速食|燒味|烧味|粥|麵|面|茶|'
    // 零售
    r'店|商店|超市|便利店|7-?Eleven|OK便利|惠康|百佳|AEON|'
    r'商場|商场|百貨|百货|Mall|Plaza|Center|Centre|'
    r'市場|市场|街市|'
    // 公司
    r'公司|有限|Co\.|Ltd|Corp|Inc|'
    // 服務
    r'藥房|药房|診所|诊所|醫院|医院|理髮|理发|美容|'
    r'酒店|旅館|旅馆|Hotel|Motel|'
    // 交通
    r'的士|出租車|Taxi|Uber|港鐵|地鐵|巴士|'
    // 英文
    r'Restaurant|Store|Shop|Market|Mart|Express',
    caseSensitive: false,
  );

  /// 知名品牌（直接匹配，高信心度）
  static final _knownBrands = RegExp(
    // 快餐
    r"McDonald's?|麥當勞|麦当劳|KFC|肯德基|"
    r'Starbucks|星巴克|Pacific Coffee|'
    r'大家樂|大家乐|大快活|美心|Maxim|'
    r'吉野家|Yoshinoya|譚仔|谭仔|'
    // 便利店/超市
    r'7-?Eleven|7-?11|OK便利|Circle K|'
    r'惠康|Wellcome|百佳|PARKnSHOP|AEON|'
    r'萬寧|万宁|Mannings|屈臣氏|Watsons|'
    // 連鎖
    r'IKEA|宜家|Uniqlo|優衣庫|H&M|ZARA|'
    r'Apple|蘋果|Samsung|三星',
    caseSensitive: false,
  );

  /// 商品/服務關鍵字
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
    RegExp(r'單號|单号|Invoice|Receipt|Order|訂單|编号|編號|No\.|#\d+', caseSensitive: false),
    // 金額相關
    RegExp(r'總計|总计|Total|Amount|小計|小计|合計|应付|應付|找續|找赎', caseSensitive: false),
    // 付款方式
    RegExp(r'現金|现金|Cash|信用卡|Credit|Visa|Master|八達通|支付寶|微信|Alipay|WeChat', caseSensitive: false),
    // 常見無意義內容
    RegExp(r'歡迎光臨|欢迎光临|謝謝|谢谢|Thank|Welcome|多謝|再見|再见|光臨|光临', caseSensitive: false),
    // 純數字行
    RegExp(r'^\d+$'),
    // 稅務相關
    RegExp(r'稅|税|VAT|GST', caseSensitive: false),
    // 網址
    RegExp(r'www\.|\.com|\.hk|http', caseSensitive: false),
    // 社交媒體
    RegExp(r'facebook|instagram|twitter|@', caseSensitive: false),
  ];

  /// 提取描述（店名或商品項目）
  static String? extract(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // 排序區塊（按 Y 位置）
    final sortedBlocks = List<TextBlock>.from(text.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 第一輪：找知名品牌（任何位置）
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();
        if (_knownBrands.hasMatch(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    // 計算平均行高（用於識別大文字）
    double totalHeight = 0;
    int lineCount = 0;
    for (final block in sortedBlocks) {
      totalHeight += block.boundingBox.height;
      lineCount += block.lines.length;
    }
    final avgHeight = lineCount > 0 ? totalHeight / lineCount : 50.0;

    // 第二輪：找頂部區域的大文字或店名關鍵字
    for (var i = 0; i < sortedBlocks.length && i < 5; i++) {
      final block = sortedBlocks[i];
      final blockHeight = block.boundingBox.height / block.lines.length;
      final isLargeText = blockHeight > avgHeight * 1.2;

      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        // 優先選擇大文字或包含店名關鍵字的
        if (isLargeText || _storeKeywords.hasMatch(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    // 第三輪：找頂部有意義的文字
    for (var i = 0; i < sortedBlocks.length && i < 3; i++) {
      final block = sortedBlocks[i];

      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        if (_isLikelyStoreName(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    // 第四輪：找商品/服務項目
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        if (_itemKeywords.hasMatch(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
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
  static String? _cleanDescription(String text) {
    // 移除多餘空白和特殊符號
    var cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[*#\-_=\[\]]+|[*#\-_=\[\]]+$'), '')
        .trim();

    // 移除括號內的地址/電話
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\d{6,}[^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'（[^）]*\d{6,}[^）]*）'), '');

    // 移除結尾的分店標識（保留核心名稱）
    cleaned = cleaned.replaceAll(RegExp(r'[\s\-]*分店$|[\s\-]*分行$|[\s\-]*門市$'), '');

    // 驗證清理後的結果
    if (cleaned.length < 2) return null;

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
