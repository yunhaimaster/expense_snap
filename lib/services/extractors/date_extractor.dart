import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
    } on Object catch (_) {
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
