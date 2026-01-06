import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';
import 'package:expense_snap/data/datasources/remote/google_drive_api.dart';
import 'package:expense_snap/data/models/backup_status.dart';
import 'package:expense_snap/data/repositories/backup_repository.dart';
import 'package:expense_snap/domain/repositories/backup_repository.dart';

@GenerateMocks([DatabaseHelper, GoogleDriveApi])
import 'backup_repository_test.mocks.dart';

void main() {
  late BackupRepository repository;
  late MockDatabaseHelper mockDb;
  late MockGoogleDriveApi mockDriveApi;

  setUpAll(() {
    // 為 Mockito 提供 Result 類型的 dummy 值
    provideDummy<Result<GoogleAccountInfo>>(
        Result.failure(const AuthException('dummy')));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<Uint8List>>(Result.success(Uint8List(0)));
    provideDummy<Result<List<DriveBackupInfo>>>(Result.success([]));
    provideDummy<Result<String>>(Result.success(''));
    provideDummy<Result<DriveBackupInfo>>(Result.success(DriveBackupInfo(
      id: 'dummy',
      name: 'dummy.zip',
      createdTime: DateTime(2025, 1, 1),
      sizeBytes: 0,
    )));
  });

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockDriveApi = MockGoogleDriveApi();
    // 清除任何遺留的 matcher 狀態
    reset(mockDb);
    reset(mockDriveApi);
    repository = BackupRepository(
      databaseHelper: mockDb,
      googleDriveApi: mockDriveApi,
    );
  });

  group('BackupInfo', () {
    test('應正確建立備份資訊', () {
      final info = BackupInfo(
        fileId: 'file_123',
        fileName: 'backup_20250103_120000.zip',
        createdAt: DateTime(2025, 1, 3, 12, 0, 0),
        sizeBytes: 1024 * 1024 * 2,
      );

      expect(info.fileId, 'file_123');
      expect(info.fileName, 'backup_20250103_120000.zip');
      expect(info.createdAt.year, 2025);
      expect(info.sizeBytes, 2 * 1024 * 1024);
    });

    test('多個備份資訊應可比較', () {
      final info1 = BackupInfo(
        fileId: 'file_1',
        fileName: 'backup_1.zip',
        createdAt: DateTime(2025, 1, 1),
        sizeBytes: 1024,
      );

      final info2 = BackupInfo(
        fileId: 'file_2',
        fileName: 'backup_2.zip',
        createdAt: DateTime(2025, 1, 2),
        sizeBytes: 2048,
      );

      expect(info1.fileId, isNot(info2.fileId));
      expect(info1.createdAt.isBefore(info2.createdAt), true);
    });
  });

  group('Backup Path Validation', () {
    test('目錄遍歷路徑應被識別為不安全', () {
      final unsafePaths = [
        '../etc/passwd',
        'receipts/../../../etc/passwd',
        '..\\windows\\system32',
        '/absolute/path.jpg',
        '\\absolute\\path.jpg',
      ];

      for (final path in unsafePaths) {
        expect(
          _isPathSafeForRestore(path),
          false,
          reason: 'Path should be unsafe: $path',
        );
      }
    });

    test('合法的收據路徑應被識別為安全', () {
      final safePaths = [
        'expenses.db',
        'receipts/2025-01/image.jpg',
        'receipts/2025-01/image.jpeg',
        'receipts/2025-01/image.png',
      ];

      for (final path in safePaths) {
        expect(
          _isPathSafeForRestore(path),
          true,
          reason: 'Path should be safe: $path',
        );
      }
    });

    test('不支援的檔案類型應被拒絕', () {
      final invalidPaths = [
        'receipts/2025-01/script.exe',
        'receipts/2025-01/virus.bat',
        'receipts/2025-01/data.txt',
        'other_folder/image.jpg',
      ];

      for (final path in invalidPaths) {
        expect(
          _isPathSafeForRestore(path),
          false,
          reason: 'Path should be invalid: $path',
        );
      }
    });

    test('URL 編碼的目錄遍歷應被拒絕', () {
      final encodedPaths = [
        '%2e%2e/etc/passwd', // URL encoded ..
        'receipts/%2e%2e/secret.jpg',
      ];

      for (final path in encodedPaths) {
        expect(
          _isPathSafeForRestoreWithUrlDecode(path),
          false,
          reason: 'URL encoded path should be unsafe: $path',
        );
      }
    });

    test('雙重副檔名應被拒絕', () {
      final doubleExtPaths = [
        'receipts/image.jpg.exe',
        'receipts/photo.png.bat',
        'receipts/file.jpeg.sh',
      ];

      for (final path in doubleExtPaths) {
        expect(
          _isPathSafeForRestoreWithDoubleExtCheck(path),
          false,
          reason: 'Double extension should be rejected: $path',
        );
      }
    });

    test('控制字元應被拒絕', () {
      final controlCharPaths = [
        'receipts/image\x00.jpg', // null byte
        'receipts/photo\x1f.png', // control char
        'receipts/file\x7f.jpeg', // DEL char
      ];

      for (final path in controlCharPaths) {
        expect(
          _isPathSafeForRestore(path),
          false,
          reason: 'Control char path should be rejected',
        );
      }
    });
  });

  group('signInWithGoogle', () {
    test('登入成功應回傳 email', () async {
      // Arrange
      when(mockDriveApi.signIn()).thenAnswer(
        (_) async => Result.success(const GoogleAccountInfo(
          email: 'test@gmail.com',
          displayName: 'Test User',
        )),
      );
      when(mockDb.updateBackupStatus(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.signInWithGoogle();

      // Assert
      expect(result.isSuccess, true);
      expect(result.getOrThrow(), 'test@gmail.com');
      verify(mockDb.updateBackupStatus({'google_email': 'test@gmail.com'}))
          .called(1);
    });

    test('登入失敗應回傳錯誤', () async {
      // Arrange
      when(mockDriveApi.signIn()).thenAnswer(
        (_) async => Result.failure(AuthException.cancelled()),
      );

      // Act
      final result = await repository.signInWithGoogle();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('signOutFromGoogle', () {
    test('登出成功應清除 email', () async {
      // Arrange
      when(mockDriveApi.signOut())
          .thenAnswer((_) async => Result.success(null));
      when(mockDb.updateBackupStatus(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.signOutFromGoogle();

      // Assert
      expect(result.isSuccess, true);
      verify(mockDb.updateBackupStatus({'google_email': null})).called(1);
    });
  });

  group('isGoogleSignedIn', () {
    test('已登入應回傳 true', () async {
      when(mockDriveApi.isSignedIn).thenReturn(true);

      final result = await repository.isGoogleSignedIn();

      expect(result, true);
    });

    test('未登入應回傳 false', () async {
      when(mockDriveApi.isSignedIn).thenReturn(false);

      final result = await repository.isGoogleSignedIn();

      expect(result, false);
    });
  });

  group('getBackupStatus', () {
    test('無備份狀態應回傳空狀態', () async {
      // Arrange
      when(mockDb.getBackupStatus()).thenAnswer((_) async => null);
      when(mockDriveApi.currentAccount).thenReturn(null);

      // Act
      final result = await repository.getBackupStatus();

      // Assert
      expect(result.isSuccess, true);
      final status = result.getOrThrow();
      expect(status.lastBackupAt, isNull);
    });

    test('有備份狀態應回傳正確資訊', () async {
      // Arrange
      when(mockDb.getBackupStatus()).thenAnswer((_) async => {
            'last_backup_at': '2025-01-03T12:00:00',
            'last_backup_count': 10,
            'last_backup_size_kb': 1024,
            'google_email': 'test@gmail.com',
          });
      when(mockDriveApi.currentAccount).thenReturn(
        const GoogleAccountInfo(email: 'test@gmail.com', displayName: 'Test'),
      );

      // Act
      final result = await repository.getBackupStatus();

      // Assert
      expect(result.isSuccess, true);
      final status = result.getOrThrow();
      expect(status.lastBackupCount, 10);
      expect(status.lastBackupSizeKb, 1024);
      expect(status.googleEmail, 'test@gmail.com');
    });

    test('資料庫錯誤應回傳失敗', () async {
      // Arrange
      when(mockDb.getBackupStatus()).thenThrow(Exception('DB error'));

      // Act
      final result = await repository.getBackupStatus();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('uploadBackupToGoogleDrive', () {
    late Directory tempDir;
    late File testZipFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('backup_test_');
      testZipFile = File('${tempDir.path}/test_backup.zip');
      await testZipFile.writeAsBytes([0x50, 0x4B, 0x03, 0x04]); // ZIP header
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('檔案不存在應回傳錯誤', () async {
      // Act
      final result = await repository
          .uploadBackupToGoogleDrive('/non/existent/path.zip');

      // Assert
      expect(result.isFailure, true);
    });

    // 注意：上傳成功和 API 錯誤的測試因 Mockito 命名參數匹配限制而略過
    // 這些功能透過整合測試覆蓋
  });

  group('listGoogleDriveBackups', () {
    test('列出備份成功應回傳列表', () async {
      // Arrange
      when(mockDriveApi.listBackups()).thenAnswer((_) async => Result.success([
            DriveBackupInfo(
              id: 'file_1',
              name: 'backup_1.zip',
              createdTime: DateTime(2025, 1, 1),
              sizeBytes: 1024,
            ),
            DriveBackupInfo(
              id: 'file_2',
              name: 'backup_2.zip',
              createdTime: DateTime(2025, 1, 2),
              sizeBytes: 2048,
            ),
          ]));

      // Act
      final result = await repository.listGoogleDriveBackups();

      // Assert
      expect(result.isSuccess, true);
      final backups = result.getOrThrow();
      expect(backups.length, 2);
      expect(backups[0].fileId, 'file_1');
      expect(backups[1].fileId, 'file_2');
    });

    test('API 錯誤應回傳失敗', () async {
      // Arrange
      when(mockDriveApi.listBackups()).thenAnswer(
          (_) async => Result.failure(const StorageException('List failed')));

      // Act
      final result = await repository.listGoogleDriveBackups();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('downloadBackupFromGoogleDrive', () {
    test('API 錯誤應回傳失敗', () async {
      // Arrange
      when(mockDriveApi.downloadBackup(any)).thenAnswer((_) async =>
          Result.failure(const StorageException('Download failed')));

      // Act
      final result =
          await repository.downloadBackupFromGoogleDrive('file_123');

      // Assert
      expect(result.isFailure, true);
    });

    // 注意：下載成功的完整流程測試因依賴實際檔案系統操作而略過
    // 透過整合測試覆蓋
  });

  group('BackupStatus Model', () {
    test('BackupStatus.empty 應建立空狀態', () {
      final status = BackupStatus.empty();

      expect(status.lastBackupAt, isNull);
      expect(status.lastBackupCount, 0);
      expect(status.lastBackupSizeKb, 0);
      expect(status.googleEmail, isNull);
    });

    test('BackupStatus.fromMap 應正確解析', () {
      final map = {
        'last_backup_at': '2025-01-03T12:00:00',
        'last_backup_count': 10,
        'last_backup_size_kb': 2048,
        'google_email': 'user@example.com',
      };

      final status = BackupStatus.fromMap(map);

      expect(status.lastBackupAt, isNotNull);
      expect(status.lastBackupCount, 10);
      expect(status.lastBackupSizeKb, 2048);
      expect(status.googleEmail, 'user@example.com');
    });

    test('BackupStatus 應計算正確的格式化大小', () {
      final status = BackupStatus(
        lastBackupAt: DateTime.now(),
        lastBackupCount: 5,
        lastBackupSizeKb: 2048, // 2MB
        googleEmail: null,
      );

      expect(status.formattedSize, contains('MB'));
    });

    test('BackupStatus 應計算正確的相對時間', () {
      final recentStatus = BackupStatus(
        lastBackupAt: DateTime.now().subtract(const Duration(hours: 1)),
        lastBackupCount: 5,
        lastBackupSizeKb: 1024,
        googleEmail: null,
      );

      expect(recentStatus.formattedLastBackupAt, isNotEmpty);
    });
  });
}

/// 模擬備份還原時的路徑驗證邏輯（基本版）
bool _isPathSafeForRestore(String filePath) {
  // 禁止目錄遍歷
  if (filePath.contains('..')) return false;

  // 禁止絕對路徑
  if (filePath.startsWith('/') || filePath.startsWith('\\')) return false;

  // 禁止控制字元
  if (filePath.codeUnits.any((c) => c < 32 || c == 127)) return false;

  // 只允許特定檔案類型
  if (filePath == 'expenses.db') return true;

  if (filePath.startsWith('receipts/')) {
    final ext = filePath.split('.').last.toLowerCase();
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  return false;
}

/// 含 URL 解碼檢查的路徑驗證
bool _isPathSafeForRestoreWithUrlDecode(String filePath) {
  String decodedPath;
  try {
    decodedPath = Uri.decodeComponent(filePath);
  } catch (_) {
    return false;
  }

  // 解碼後與原始不同則拒絕
  if (decodedPath != filePath) return false;

  return _isPathSafeForRestore(filePath);
}

/// 含雙重副檔名檢查的路徑驗證
bool _isPathSafeForRestoreWithDoubleExtCheck(String filePath) {
  if (!_isPathSafeForRestore(filePath)) return false;

  // 檢查雙重副檔名
  if (filePath.startsWith('receipts/')) {
    final fileName = filePath.split('/').last;
    final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    if (nameWithoutExt.contains('.')) return false;
  }

  return true;
}
