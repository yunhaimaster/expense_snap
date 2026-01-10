import 'dart:convert';
import 'dart:developer' as dev;

/// 日誌等級
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 結構化日誌條目
class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.error,
    this.stackTrace,
    this.fields,
  });

  /// 日誌等級
  final LogLevel level;

  /// 日誌訊息
  final String message;

  /// 時間戳記
  final DateTime timestamp;

  /// 標籤（用於分類）
  final String? tag;

  /// 錯誤物件
  final Object? error;

  /// 堆疊追蹤
  final StackTrace? stackTrace;

  /// 額外欄位（結構化資料）
  final Map<String, dynamic>? fields;

  /// 轉換為結構化 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name.toUpperCase(),
      if (tag != null) 'tag': tag,
      'message': message,
      if (fields != null && fields!.isNotEmpty) 'fields': fields,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }

  /// 格式化為可讀的日誌字串
  String format() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}]');
    buffer.write(' [${level.name.toUpperCase()}]');
    if (tag != null) {
      buffer.write(' [$tag]');
    }
    buffer.write(' $message');
    if (fields != null && fields!.isNotEmpty) {
      try {
        buffer.write(' ${jsonEncode(fields)}');
      } catch (_) {
        // 如果 fields 包含無法序列化的物件，使用 toString 替代
        buffer.write(' {fields: [non-serializable]}');
      }
    }
    return buffer.toString();
  }

  @override
  String toString() => format();
}

/// App 日誌工具
///
/// 提供統一的結構化日誌輸出介面
class AppLogger {
  AppLogger._();

  static const String _defaultTag = 'ExpenseSnap';

  /// Debug 等級日誌
  static void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? fields,
  }) {
    _logEntry(LogEntry(
      level: LogLevel.debug,
      message: message,
      timestamp: DateTime.now(),
      tag: tag ?? _defaultTag,
      fields: fields,
    ));
  }

  /// Info 等級日誌
  static void info(
    String message, {
    String? tag,
    Map<String, dynamic>? fields,
  }) {
    _logEntry(LogEntry(
      level: LogLevel.info,
      message: message,
      timestamp: DateTime.now(),
      tag: tag ?? _defaultTag,
      fields: fields,
    ));
  }

  /// Warning 等級日誌
  static void warning(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? fields,
  }) {
    _logEntry(LogEntry(
      level: LogLevel.warning,
      message: message,
      timestamp: DateTime.now(),
      tag: tag ?? _defaultTag,
      error: error,
      fields: fields,
    ));
  }

  /// Error 等級日誌
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? fields,
  }) {
    _logEntry(LogEntry(
      level: LogLevel.error,
      message: message,
      timestamp: DateTime.now(),
      tag: tag ?? _defaultTag,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ));
  }

  /// 記錄網絡請求
  static void network(
    String method,
    String url, {
    int? statusCode,
    String? body,
    Duration? duration,
  }) {
    final fields = <String, dynamic>{
      'method': method,
      'url': url,
    };
    if (statusCode != null) fields['statusCode'] = statusCode;
    if (duration != null) fields['durationMs'] = duration.inMilliseconds;

    info(
      'HTTP $method $url${statusCode != null ? ' [$statusCode]' : ''}',
      tag: 'Network',
      fields: fields,
    );

    if (body != null && body.isNotEmpty) {
      debug(
        'Response: ${_truncate(body, 500)}',
        tag: 'Network',
      );
    }
  }

  /// 記錄資料庫操作
  static void database(
    String operation, {
    String? table,
    int? affectedRows,
    Duration? duration,
  }) {
    final fields = <String, dynamic>{
      'operation': operation,
    };
    if (table != null) fields['table'] = table;
    if (affectedRows != null) fields['affectedRows'] = affectedRows;
    if (duration != null) fields['durationMs'] = duration.inMilliseconds;

    final tableInfo = table != null ? ' on $table' : '';
    final rowsInfo = affectedRows != null ? ' ($affectedRows rows)' : '';

    debug(
      '$operation$tableInfo$rowsInfo',
      tag: 'Database',
      fields: fields,
    );
  }

  /// 記錄效能指標
  static void performance(
    String operation, {
    required Duration duration,
    Map<String, dynamic>? metrics,
  }) {
    final fields = <String, dynamic>{
      'operation': operation,
      'durationMs': duration.inMilliseconds,
      ...?metrics,
    };

    debug(
      '$operation completed in ${duration.inMilliseconds}ms',
      tag: 'Performance',
      fields: fields,
    );
  }

  /// 內部日誌輸出方法
  static void _logEntry(LogEntry entry) {
    // 格式化輸出
    final formattedMessage = entry.format();

    // 使用 dart:developer log 以支援 DevTools
    dev.log(
      formattedMessage,
      name: entry.tag ?? _defaultTag,
      error: entry.error,
      stackTrace: entry.stackTrace,
    );
  }

  /// 截斷過長的字串
  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
