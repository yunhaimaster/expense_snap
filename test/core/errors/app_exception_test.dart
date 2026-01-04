import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/core/errors/app_exception.dart';

void main() {
  group('NetworkException', () {
    test('建構函式應正確設定屬性', () {
      const exception = NetworkException('測試訊息', code: 'TEST', statusCode: 500);

      expect(exception.message, '測試訊息');
      expect(exception.code, 'TEST');
      expect(exception.statusCode, 500);
    });

    test('noConnection 應建立正確的例外', () {
      final exception = NetworkException.noConnection();

      expect(exception.message, contains('無網絡連線'));
      expect(exception.code, 'NO_CONNECTION');
    });

    test('timeout 應建立正確的例外', () {
      final exception = NetworkException.timeout();

      expect(exception.message, contains('逾時'));
      expect(exception.code, 'TIMEOUT');
    });

    test('serverError 應建立正確的例外', () {
      final exception = NetworkException.serverError(statusCode: 503);

      expect(exception.message, contains('伺服器錯誤'));
      expect(exception.code, 'SERVER_ERROR');
      expect(exception.statusCode, 503);
    });

    test('toString 應包含訊息和代碼', () {
      final exception = NetworkException.noConnection();

      expect(exception.toString(), contains('無網絡連線'));
      expect(exception.toString(), contains('NO_CONNECTION'));
    });
  });

  group('StorageException', () {
    test('insufficientSpace 應建立正確的例外', () {
      final exception = StorageException.insufficientSpace();

      expect(exception.message, contains('儲存空間不足'));
      expect(exception.code, 'INSUFFICIENT_SPACE');
    });

    test('fileNotFound 應包含檔案路徑', () {
      final exception = StorageException.fileNotFound('/path/to/file.txt');

      expect(exception.message, contains('/path/to/file.txt'));
      expect(exception.code, 'FILE_NOT_FOUND');
    });

    test('writeError 應包含檔案路徑', () {
      final exception = StorageException.writeError('/path/to/file.txt');

      expect(exception.message, contains('/path/to/file.txt'));
      expect(exception.code, 'WRITE_ERROR');
    });

    test('readError 應包含檔案路徑', () {
      final exception = StorageException.readError('/path/to/file.txt');

      expect(exception.message, contains('/path/to/file.txt'));
      expect(exception.code, 'READ_ERROR');
    });

    test('unsafePath 應包含路徑', () {
      final exception = StorageException.unsafePath('../etc/passwd');

      expect(exception.message, contains('../etc/passwd'));
      expect(exception.code, 'UNSAFE_PATH');
    });
  });

  group('DatabaseException', () {
    test('locked 應建立正確的例外', () {
      final exception = DatabaseException.locked();

      expect(exception.message, contains('鎖定'));
      expect(exception.code, 'DB_LOCKED');
    });

    test('corrupted 應建立正確的例外', () {
      final exception = DatabaseException.corrupted();

      expect(exception.message, contains('損壞'));
      expect(exception.code, 'DB_CORRUPTED');
    });

    test('queryFailed 應包含原因', () {
      final exception = DatabaseException.queryFailed('syntax error');

      expect(exception.message, contains('syntax error'));
      expect(exception.code, 'QUERY_FAILED');
    });

    test('insertFailed 應包含原因', () {
      final exception = DatabaseException.insertFailed('unique constraint');

      expect(exception.message, contains('unique constraint'));
      expect(exception.code, 'INSERT_FAILED');
    });

    test('updateFailed 應包含原因', () {
      final exception = DatabaseException.updateFailed('row not found');

      expect(exception.message, contains('row not found'));
      expect(exception.code, 'UPDATE_FAILED');
    });

    test('deleteFailed 應包含原因', () {
      final exception = DatabaseException.deleteFailed('foreign key');

      expect(exception.message, contains('foreign key'));
      expect(exception.code, 'DELETE_FAILED');
    });
  });

  group('ValidationException', () {
    test('建構函式應正確設定 field 屬性', () {
      const exception = ValidationException('測試', code: 'TEST', field: 'amount');

      expect(exception.field, 'amount');
    });

    test('required 應包含欄位名稱', () {
      final exception = ValidationException.required('金額');

      expect(exception.message, contains('金額'));
      expect(exception.code, 'REQUIRED');
      expect(exception.field, '金額');
    });

    test('outOfRange 應包含範圍資訊', () {
      final exception = ValidationException.outOfRange('金額', 0, 1000000);

      expect(exception.message, contains('金額'));
      expect(exception.message, contains('0'));
      expect(exception.message, contains('1000000'));
      expect(exception.code, 'OUT_OF_RANGE');
    });

    test('lengthExceeded 應包含長度限制', () {
      final exception = ValidationException.lengthExceeded('描述', 500);

      expect(exception.message, contains('描述'));
      expect(exception.message, contains('500'));
      expect(exception.code, 'LENGTH_EXCEEDED');
    });

    test('invalidFormat 應包含欄位名稱', () {
      final exception = ValidationException.invalidFormat('電子郵件');

      expect(exception.message, contains('電子郵件'));
      expect(exception.code, 'INVALID_FORMAT');
    });

    test('invalidDate 應包含欄位名稱', () {
      final exception = ValidationException.invalidDate('日期');

      expect(exception.message, contains('日期'));
      expect(exception.code, 'INVALID_DATE');
    });
  });

  group('AuthException', () {
    test('notSignedIn 應建立正確的例外', () {
      final exception = AuthException.notSignedIn();

      expect(exception.message, contains('登入'));
      expect(exception.code, 'NOT_SIGNED_IN');
    });

    test('cancelled 應建立正確的例外', () {
      final exception = AuthException.cancelled();

      expect(exception.message, contains('取消'));
      expect(exception.code, 'CANCELLED');
    });

    test('tokenExpired 應建立正確的例外', () {
      final exception = AuthException.tokenExpired();

      expect(exception.message, contains('過期'));
      expect(exception.code, 'TOKEN_EXPIRED');
    });

    test('insufficientPermission 應建立正確的例外', () {
      final exception = AuthException.insufficientPermission();

      expect(exception.message, contains('權限'));
      expect(exception.code, 'INSUFFICIENT_PERMISSION');
    });
  });

  group('ImageException', () {
    test('compressionFailed 應建立正確的例外', () {
      final exception = ImageException.compressionFailed();

      expect(exception.message, contains('壓縮'));
      expect(exception.code, 'COMPRESSION_FAILED');
    });

    test('thumbnailFailed 應建立正確的例外', () {
      final exception = ImageException.thumbnailFailed();

      expect(exception.message, contains('縮圖'));
      expect(exception.code, 'THUMBNAIL_FAILED');
    });

    test('unsupportedFormat 應建立正確的例外', () {
      final exception = ImageException.unsupportedFormat();

      expect(exception.message, contains('格式'));
      expect(exception.code, 'UNSUPPORTED_FORMAT');
    });

    test('corrupted 應建立正確的例外', () {
      final exception = ImageException.corrupted();

      expect(exception.message, contains('損壞'));
      expect(exception.code, 'CORRUPTED');
    });
  });

  group('AppException toString', () {
    test('有 code 時應包含 code', () {
      const exception = NetworkException('測試', code: 'TEST_CODE');

      expect(exception.toString(), contains('TEST_CODE'));
    });

    test('無 code 時不應有括號', () {
      const exception = NetworkException('測試');

      expect(exception.toString(), equals('AppException: 測試'));
    });
  });
}
