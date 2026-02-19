import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
    '小計',
    '小计',
    'Subtotal',
    'SUBTOTAL',
    'Sub-total',
    'Sub Total',
  ];

  /// 金額關鍵字（中優先級）
  static const _amountKeywords = [
    '金額',
    '金额',
    'Amount',
    'AMOUNT',
    'Sum',
    'SUM',
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
    '稅',
    '税',
    'Tax',
    'TAX',
    'VAT',
    'GST',
    '服務費',
    '服务费',
    'Service',
    '減',
    '减',
    'Off',
    'OFF',
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
          candidates.add(
            _AmountCandidate(
              cents: cents,
              lineText: lineText,
              lineIndex: lineIndex,
              positionY: positionY,
              hasKeyword: keywordType != _KeywordType.none,
              keywordType: keywordType,
            ),
          );
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
          final variation =
              keyword.substring(0, i) + replacement + keyword.substring(i + 1);
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
  static List<_AmountCandidate> _filterNegatives(
    List<_AmountCandidate> candidates,
  ) {
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
      bottomCandidates = candidates.where((c) => c.positionY >= midY).toList();
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
