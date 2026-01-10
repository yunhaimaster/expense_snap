import 'package:expense_snap/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogLevel', () {
    test('應有 4 個等級', () {
      expect(LogLevel.values.length, equals(4));
    });

    test('等級順序正確', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
    });
  });

  group('LogEntry', () {
    test('建構函式應正確設定必要欄位', () {
      final timestamp = DateTime.now();
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'Test message',
        timestamp: timestamp,
      );

      expect(entry.level, equals(LogLevel.info));
      expect(entry.message, equals('Test message'));
      expect(entry.timestamp, equals(timestamp));
      expect(entry.tag, isNull);
      expect(entry.error, isNull);
      expect(entry.stackTrace, isNull);
      expect(entry.fields, isNull);
    });

    test('建構函式應正確設定選用欄位', () {
      final timestamp = DateTime.now();
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      final fields = {'key': 'value', 'count': 42};

      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Error occurred',
        timestamp: timestamp,
        tag: 'TestTag',
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      );

      expect(entry.tag, equals('TestTag'));
      expect(entry.error, equals(error));
      expect(entry.stackTrace, equals(stackTrace));
      expect(entry.fields, equals(fields));
    });

    group('toJson', () {
      test('應包含必要欄位', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test message',
          timestamp: timestamp,
        );

        final json = entry.toJson();

        expect(json['timestamp'], equals('2024-01-15T10:30:00.000'));
        expect(json['level'], equals('INFO'));
        expect(json['message'], equals('Test message'));
        expect(json.containsKey('tag'), isFalse);
        expect(json.containsKey('fields'), isFalse);
        expect(json.containsKey('error'), isFalse);
        expect(json.containsKey('stackTrace'), isFalse);
      });

      test('應包含選用欄位（若有設定）', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error message',
          timestamp: timestamp,
          tag: 'ErrorTag',
          error: Exception('Test error'),
          fields: {'userId': 123},
        );

        final json = entry.toJson();

        expect(json['tag'], equals('ErrorTag'));
        expect(json['fields'], equals({'userId': 123}));
        expect(json['error'], contains('Test error'));
      });

      test('空 fields 不應包含在 JSON 中', () {
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: DateTime.now(),
          fields: {},
        );

        final json = entry.toJson();
        expect(json.containsKey('fields'), isFalse);
      });
    });

    group('format', () {
      test('基本格式應正確', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test message',
          timestamp: timestamp,
        );

        final formatted = entry.format();

        expect(formatted, contains('[2024-01-15T10:30:00.000]'));
        expect(formatted, contains('[INFO]'));
        expect(formatted, contains('Test message'));
      });

      test('應包含 tag（若有設定）', () {
        final entry = LogEntry(
          level: LogLevel.warning,
          message: 'Warning',
          timestamp: DateTime.now(),
          tag: 'CustomTag',
        );

        final formatted = entry.format();

        expect(formatted, contains('[CustomTag]'));
      });

      test('應包含 fields JSON（若有設定）', () {
        final entry = LogEntry(
          level: LogLevel.debug,
          message: 'Debug',
          timestamp: DateTime.now(),
          fields: {'count': 10},
        );

        final formatted = entry.format();

        expect(formatted, contains('{"count":10}'));
      });

      test('非序列化 fields 應安全處理', () {
        // 包含無法 JSON 序列化的物件（如帶有循環引用的物件）
        final nonSerializable = <String, dynamic>{};
        nonSerializable['self'] = nonSerializable; // 循環引用

        final entry = LogEntry(
          level: LogLevel.warning,
          message: 'Non-serializable test',
          timestamp: DateTime.now(),
          fields: nonSerializable,
        );

        // 應該不拋出異常，而是安全處理
        expect(entry.format, returnsNormally);
        final formatted = entry.format();
        expect(formatted, contains('non-serializable'));
      });
    });

    test('toString 應返回 format 結果', () {
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'Test',
        timestamp: DateTime.now(),
      );

      expect(entry.toString(), equals(entry.format()));
    });
  });

  group('AppLogger', () {
    // 由於 AppLogger 使用 dart:developer，我們主要測試它不會拋出異常

    test('debug 應正常執行', () {
      expect(
        () => AppLogger.debug('Debug message'),
        returnsNormally,
      );
    });

    test('debug 應支援 fields', () {
      expect(
        () => AppLogger.debug(
          'Debug with fields',
          fields: {'key': 'value'},
        ),
        returnsNormally,
      );
    });

    test('info 應正常執行', () {
      expect(
        () => AppLogger.info('Info message'),
        returnsNormally,
      );
    });

    test('info 應支援 tag', () {
      expect(
        () => AppLogger.info('Info with tag', tag: 'CustomTag'),
        returnsNormally,
      );
    });

    test('warning 應正常執行', () {
      expect(
        () => AppLogger.warning('Warning message'),
        returnsNormally,
      );
    });

    test('warning 應支援 error', () {
      expect(
        () => AppLogger.warning(
          'Warning with error',
          error: Exception('Test'),
        ),
        returnsNormally,
      );
    });

    test('error 應正常執行', () {
      expect(
        () => AppLogger.error('Error message'),
        returnsNormally,
      );
    });

    test('error 應支援 error 和 stackTrace', () {
      expect(
        () => AppLogger.error(
          'Error with details',
          error: Exception('Test'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('network 應正常執行', () {
      expect(
        () => AppLogger.network('GET', 'https://example.com'),
        returnsNormally,
      );
    });

    test('network 應支援完整參數', () {
      expect(
        () => AppLogger.network(
          'POST',
          'https://api.example.com/data',
          statusCode: 200,
          body: '{"result": "ok"}',
          duration: const Duration(milliseconds: 150),
        ),
        returnsNormally,
      );
    });

    test('database 應正常執行', () {
      expect(
        () => AppLogger.database('SELECT'),
        returnsNormally,
      );
    });

    test('database 應支援完整參數', () {
      expect(
        () => AppLogger.database(
          'INSERT',
          table: 'expenses',
          affectedRows: 1,
          duration: const Duration(milliseconds: 5),
        ),
        returnsNormally,
      );
    });

    test('performance 應正常執行', () {
      expect(
        () => AppLogger.performance(
          'Image compression',
          duration: const Duration(milliseconds: 250),
        ),
        returnsNormally,
      );
    });

    test('performance 應支援 metrics', () {
      expect(
        () => AppLogger.performance(
          'Batch export',
          duration: const Duration(seconds: 2),
          metrics: {
            'itemCount': 100,
            'fileSize': 1024000,
          },
        ),
        returnsNormally,
      );
    });
  });
}
