import 'package:intl/intl.dart';

import '../constants/currency_constants.dart';

/// 格式化工具類別
class Formatters {
  Formatters._();

  // 日期格式化器
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _monthFormatter = DateFormat('yyyy年M月');
  static final DateFormat _displayDateFormatter = DateFormat('M月d日');
  static final DateFormat _displayDateTimeFormatter = DateFormat('M月d日 HH:mm');

  /// 格式化日期（ISO 8601 格式，用於儲存）
  static String formatDateForStorage(DateTime date) {
    return date.toUtc().toIso8601String();
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

  /// 格式化月份（yyyy年M月）
  static String formatMonth(DateTime date) {
    return _monthFormatter.format(date);
  }

  /// 格式化日期用於顯示（M月d日）
  static String formatDisplayDate(DateTime date) {
    return _displayDateFormatter.format(date);
  }

  /// 格式化日期時間用於顯示（M月d日 HH:mm）
  static String formatDisplayDateTime(DateTime dateTime) {
    return _displayDateTimeFormatter.format(dateTime);
  }

  /// 格式化相對時間（例如：5分鐘前、2小時前）
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '剛才';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDisplayDate(dateTime);
    }
  }

  /// 金額：分轉元
  static double centsToAmount(int cents) {
    return cents / 100.0;
  }

  /// 金額：元轉分
  static int amountToCents(double amount) {
    return (amount * 100).round();
  }

  /// 格式化金額顯示（帶幣種符號）
  static String formatAmount(int cents, String currency) {
    final amount = centsToAmount(cents);
    final symbol = CurrencyConstants.currencySymbols[currency] ?? currency;
    return '$symbol${_formatNumber(amount)}';
  }

  /// 格式化金額顯示（純數字，帶千分位）
  static String formatAmountNumber(int cents) {
    final amount = centsToAmount(cents);
    return _formatNumber(amount);
  }

  /// 格式化數字（千分位分隔，保留2位小數）
  static String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00');
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
}
