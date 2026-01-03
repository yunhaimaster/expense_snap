import 'dart:developer' as dev;

/// App 日誌工具
///
/// 提供統一的日誌輸出介面，方便未來替換日誌實作
class AppLogger {
  AppLogger._();

  static const String _tag = 'ExpenseSnap';

  /// Debug 等級日誌
  static void debug(String message, {String? tag}) {
    _log('DEBUG', tag ?? _tag, message);
  }

  /// Info 等級日誌
  static void info(String message, {String? tag}) {
    _log('INFO', tag ?? _tag, message);
  }

  /// Warning 等級日誌
  static void warning(String message, {String? tag, Object? error}) {
    _log('WARN', tag ?? _tag, message, error: error);
  }

  /// Error 等級日誌
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', tag ?? _tag, message, error: error, stackTrace: stackTrace);
  }

  /// 記錄網絡請求
  static void network(String method, String url, {int? statusCode, String? body}) {
    final status = statusCode != null ? ' [$statusCode]' : '';
    final message = '$method $url$status';
    _log('NETWORK', _tag, message);
    if (body != null && body.isNotEmpty) {
      _log('NETWORK', _tag, 'Response: ${_truncate(body, 500)}');
    }
  }

  /// 記錄資料庫操作
  static void database(String operation, {String? table, int? affectedRows}) {
    final tableInfo = table != null ? ' on $table' : '';
    final rowsInfo = affectedRows != null ? ' ($affectedRows rows)' : '';
    _log('DB', _tag, '$operation$tableInfo$rowsInfo');
  }

  /// 內部日誌方法
  static void _log(
    String level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [$tag] $message';

    // 使用 dart:developer log 以支援 DevTools
    dev.log(
      logMessage,
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 截斷過長的字串
  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
