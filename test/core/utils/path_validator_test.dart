import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:expense_snap/core/utils/path_validator.dart';
import 'package:expense_snap/core/errors/app_exception.dart';

/// Mock PathProvider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/mock/app/documents';

  @override
  Future<String?> getTemporaryPath() async => '/mock/temp';

  @override
  Future<String?> getApplicationSupportPath() async => '/mock/support';

  @override
  Future<String?> getLibraryPath() async => '/mock/library';

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => null;

  @override
  Future<String?> getDownloadsPath() async => '/mock/downloads';
}

void main() {
  late MockPathProviderPlatform mockPathProvider;

  setUp(() async {
    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;
    await PathValidator.initialize();
  });

  group('PathValidator.isPathSafe', () {
    group('基本路徑遍歷攻擊', () {
      test('應拒絕 .. 目錄遍歷', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/../../../etc/passwd'), isFalse);
      });

      test('應拒絕相對路徑遍歷', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/receipts/../../etc/passwd'), isFalse);
      });

      test('應拒絕連續 .. 遍歷', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/receipts/../..'), isFalse);
      });
    });

    group('URL 編碼繞過攻擊', () {
      test('應拒絕 %2e%2e 編碼的 ..', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/%2e%2e/etc/passwd'), isFalse);
      });

      test('應拒絕 %2E%2E 大寫編碼的 ..', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/%2E%2E/etc/passwd'), isFalse);
      });

      test('應拒絕 %2f 編碼的斜線', () {
        expect(PathValidator.isPathSafe('/mock/app/documents%2f..%2f..%2fetc%2fpasswd'), isFalse);
      });

      test('應拒絕混合編碼攻擊', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/%2e%2e%2f%2e%2e%2fetc%2fpasswd'), isFalse);
      });
    });

    group('特殊字元攻擊', () {
      test('應拒絕 null byte 注入', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/receipts/image.jpg\x00.txt'), isFalse);
      });

      test('應拒絕控制字元', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/receipts/\x01image.jpg'), isFalse);
        expect(PathValidator.isPathSafe('/mock/app/documents/receipts/\x7Fimage.jpg'), isFalse);
      });

      test('應拒絕 home 目錄符號', () {
        expect(PathValidator.isPathSafe('~/../../etc/passwd'), isFalse);
        expect(PathValidator.isPathSafe('/mock/app/documents/~/.bashrc'), isFalse);
      });

      test('應拒絕雙斜線', () {
        expect(PathValidator.isPathSafe('/mock/app/documents//receipts/image.jpg'), isFalse);
      });

      test('應拒絕 Windows 反斜線', () {
        expect(PathValidator.isPathSafe('/mock/app/documents\\..\\..\\windows\\system32'), isFalse);
      });
    });

    group('合法路徑', () {
      test('應接受 app 文件目錄下的正常路徑', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/receipts/2025-01/image.jpg'), isTrue);
      });

      test('應接受 app 文件目錄下的子目錄', () {
        expect(PathValidator.isPathSafe('/mock/app/documents/export/data.xlsx'), isTrue);
      });
    });

    group('目錄外路徑', () {
      test('應拒絕 app 目錄外的路徑', () {
        expect(PathValidator.isPathSafe('/etc/passwd'), isFalse);
        expect(PathValidator.isPathSafe('/var/log/system.log'), isFalse);
        expect(PathValidator.isPathSafe('/other/path/file.txt'), isFalse);
      });
    });
  });

  group('PathValidator.validatePath', () {
    test('不安全路徑應拋出 StorageException', () {
      expect(
        () => PathValidator.validatePath('/mock/app/documents/../../../etc/passwd'),
        throwsA(isA<StorageException>()),
      );
    });

    test('安全路徑不應拋出異常', () {
      expect(
        () => PathValidator.validatePath('/mock/app/documents/receipts/image.jpg'),
        returnsNormally,
      );
    });
  });

  group('PathValidator.buildSafeImagePath', () {
    test('應建立有效的圖片路徑', () {
      final path = PathValidator.buildSafeImagePath(
        subFolder: '2025-01',
        fileName: '1704278400000_abc12345_full.jpg',
      );

      expect(path, '/mock/app/documents/receipts/2025-01/1704278400000_abc12345_full.jpg');
    });

    test('應拒絕無效的月份格式', () {
      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-1',  // 缺少前導零
          fileName: 'image.jpg',
        ),
        throwsA(isA<StorageException>()),
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-13',  // 無效月份
          fileName: 'image.jpg',
        ),
        throwsA(isA<StorageException>()),
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '../2025-01',  // 目錄遍歷
          fileName: 'image.jpg',
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('應拒絕無效的檔案名稱', () {
      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-01',
          fileName: '../image.jpg',  // 目錄遍歷
        ),
        throwsA(isA<StorageException>()),
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-01',
          fileName: '.hidden',  // 隱藏檔案
        ),
        throwsA(isA<StorageException>()),
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-01',
          fileName: 'image..jpg',  // 連續的點
        ),
        throwsA(isA<StorageException>()),
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-01',
          fileName: 'image with spaces.jpg',  // 包含空格
        ),
        throwsA(isA<StorageException>()),
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-01',
          fileName: 'image<script>.jpg',  // 包含特殊字元
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('應接受合法的檔案名稱', () {
      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-01',
          fileName: '1704278400000_abc12345_full.jpg',
        ),
        returnsNormally,
      );

      expect(
        () => PathValidator.buildSafeImagePath(
          subFolder: '2025-12',
          fileName: 'image_123-test.jpeg',
        ),
        returnsNormally,
      );
    });
  });

  group('PathValidator.extractRelativePath', () {
    test('應從完整路徑提取相對路徑', () {
      final relative = PathValidator.extractRelativePath(
        '/mock/app/documents/receipts/2025-01/image.jpg',
      );

      expect(relative, '/receipts/2025-01/image.jpg');
    });

    test('非 app 目錄路徑應返回 null', () {
      final relative = PathValidator.extractRelativePath('/etc/passwd');
      expect(relative, isNull);
    });
  });
}
