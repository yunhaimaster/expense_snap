import 'package:intl/intl.dart';

import '../constants/currency_constants.dart';

/// 格式化工具類別
class Formatters {
  Formatters._();

  // 日期格式化器（語言無關的格式）
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormatter = DateFormat(
    'yyyy-MM-dd HH:mm:ss',
  );

  // 中文日期格式化器（使用 pattern 而非 locale，避免需要初始化 locale data）
  static final DateFormat _monthFormatterZh = DateFormat('yyyy年M月');
  static final DateFormat _displayDateFormatterZh = DateFormat('M月d日');
  static final DateFormat _displayDateTimeFormatterZh = DateFormat(
    'M月d日 HH:mm',
  );

  /// 格式化日期（ISO 8601 格式，用於儲存）
  /// 使用本地時間以確保日期查詢一致性
  static String formatDateForStorage(DateTime date) {
    return date.toIso8601String();
  }

  /// 解析儲存的日期字串
  static DateTime? parseDateFromStorage(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    return DateTime.tryParse(dateString);
  }

  /// 格式化日期（yyyy-MM-dd）
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// 格式化日期時間（yyyy-MM-dd HH:mm:ss）
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// 格式化月份
  /// 根據 locale 自動選擇格式：
  /// - 中文 (zh)：2025年1月
  /// - 日文 (ja)：2025年1月
  /// - 韓文 (ko)：2025년 1월
  /// - 西班牙文 (es)：enero de 2025
  /// - 其他語言：January 2025
  static String formatMonth(DateTime date, {String? locale}) {
    // 中文（繁體、簡體）和日文使用相同的年月格式
    if (locale != null &&
        (locale.startsWith('zh') || locale.startsWith('ja'))) {
      return _monthFormatterZh.format(date);
    }

    // 韓文格式
    if (locale == 'ko') {
      return '${date.year}년 ${date.month}월';
    }

    // 西班牙文月份名稱
    if (locale == 'es') {
      const esMonths = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${esMonths[date.month - 1]} de ${date.year}';
    }

    // 英文和其他語言
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${enMonths[date.month - 1]} ${date.year}';
  }

  /// 格式化日期用於顯示（M月d日）
  /// 自動轉換為本地時區
  /// 注意：此方法使用中文格式，用於收據詳情等固定顯示
  static String formatDisplayDate(DateTime date) {
    return _displayDateFormatterZh.format(date.toLocal());
  }

  /// 格式化日期時間用於顯示（M月d日 HH:mm）
  /// 自動轉換為本地時區
  /// 注意：此方法使用中文格式，用於收據詳情等固定顯示
  static String formatDisplayDateTime(DateTime dateTime) {
    return _displayDateTimeFormatterZh.format(dateTime.toLocal());
  }

  /// 格式化相對時間（例如：5分鐘前、2小時前）
  /// 自動轉換為本地時區進行計算
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    // 轉換為本地時間以確保正確的時間差計算
    final localDateTime = dateTime.toLocal();
    final difference = now.difference(localDateTime);

    if (difference.inSeconds < 60) {
      return '剛才';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDisplayDate(localDateTime);
    }
  }

  /// 金額：分轉元（尊重幣種小數位數）
  /// [currency] 如為 null，預設使用 2 位小數（向後相容）
  static double centsToAmount(int cents, [String? currency]) {
    if (currency != null) {
      final decimals = CurrencyConstants.getDecimalPlaces(currency);
      if (decimals == 0) {
        // JPY/KRW 等無小數幣種：cents 就是實際金額
        return cents.toDouble();
      }
    }
    return cents / 100.0;
  }

  /// 金額：元轉分（尊重幣種小數位數）
  /// [currency] 如為 null，預設使用 2 位小數（向後相容）
  static int amountToCents(double amount, [String? currency]) {
    if (currency != null) {
      final decimals = CurrencyConstants.getDecimalPlaces(currency);
      if (decimals == 0) {
        // JPY/KRW 等無小數幣種：直接取整，不乘 100
        return amount.round();
      }
    }
    return (amount * 100).round();
  }

  /// 格式化金額顯示（帶幣種符號，尊重小數位數）
  static String formatAmount(int cents, String currency) {
    final decimals = CurrencyConstants.getDecimalPlaces(currency);
    final symbol = CurrencyConstants.currencySymbols[currency] ?? currency;

    if (decimals == 0) {
      // JPY/KRW 等無小數幣種：直接用 cents 作為整數金額
      return '$symbol${_formatNumberNoDecimals(cents)}';
    }
    // 其他幣種：cents / 100 轉換為元
    final amount = centsToAmount(cents, currency);
    return '$symbol${_formatNumber(amount)}';
  }

  /// 格式化金額顯示（純數字，帶千分位）
  /// [currency] 幣種，用於決定小數位數（JPY/KRW 為 0）
  static String formatAmountNumber(int cents, [String? currency]) {
    final amount = centsToAmount(cents, currency);
    if (currency != null) {
      final decimals = CurrencyConstants.getDecimalPlaces(currency);
      if (decimals == 0) {
        return _formatNumberNoDecimals(cents);
      }
    }
    return _formatNumber(amount);
  }

  /// 格式化數字（千分位分隔，保留2位小數）
  static String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(number);
  }

  /// 格式化整數（千分位分隔，無小數）
  static String _formatNumberNoDecimals(int number) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(number);
  }

  /// 匯率：儲存值轉顯示值
  static double storedRateToDisplay(int storedRate) {
    return storedRate / CurrencyConstants.ratePrecision;
  }

  /// 匯率：顯示值轉儲存值
  static int displayRateToStored(double displayRate) {
    return (displayRate * CurrencyConstants.ratePrecision).round();
  }

  /// 格式化匯率顯示
  static String formatExchangeRate(int storedRate) {
    final rate = storedRateToDisplay(storedRate);
    return rate.toStringAsFixed(4);
  }

  /// 格式化貨幣金額（純數字，用於表單預覽）
  static String formatCurrency(double amount) {
    return _formatNumber(amount);
  }

  /// 匯率：轉換為 micros（×10⁶）
  static int rateToMicros(double rate) {
    return displayRateToStored(rate);
  }

  /// 格式化檔案大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 格式化時間戳用於檔名（yyyyMMdd_HHmmss）
  static String formatTimestampForFileName(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute$second';
  }

  /// 格式化日期時間用於顯示（yyyy年M月d日 HH:mm）
  /// 自動轉換為本地時區
  static String formatDateTimeForDisplay(DateTime dateTime) {
    // 確保轉換為本地時間顯示
    final local = dateTime.toLocal();
    return '${local.year}年${local.month}月${local.day}日 '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
