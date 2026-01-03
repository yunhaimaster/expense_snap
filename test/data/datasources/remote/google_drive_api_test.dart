import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/data/datasources/remote/google_drive_api.dart';

/// Google Drive API 測試
///
/// 注意：這些測試主要測試資料結構和工廠方法
/// 實際的 API 呼叫需要整合測試
void main() {
  group('DriveBackupInfo', () {
    test('應正確格式化小於 1KB 的檔案大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 500,
      );

      expect(info.formattedSize, '500 B');
    });

    test('應正確格式化 KB 級別的檔案大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 2048,
      );

      expect(info.formattedSize, '2.0 KB');
    });

    test('應正確格式化 MB 級別的檔案大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 5 * 1024 * 1024,
      );

      expect(info.formattedSize, '5.0 MB');
    });

    test('toString 應包含名稱和大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 1024 * 1024,
      );

      final str = info.toString();
      expect(str, contains('backup.zip'));
      expect(str, contains('1.0 MB'));
    });
  });

  group('GoogleAccountInfo', () {
    test('應正確建立帳號資訊', () {
      const info = GoogleAccountInfo(
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );

      expect(info.email, 'test@example.com');
      expect(info.displayName, 'Test User');
      expect(info.photoUrl, 'https://example.com/photo.jpg');
    });

    test('photoUrl 可為 null', () {
      const info = GoogleAccountInfo(
        email: 'test@example.com',
        displayName: null,
        photoUrl: null,
      );

      expect(info.email, 'test@example.com');
      expect(info.displayName, isNull);
      expect(info.photoUrl, isNull);
    });
  });

  group('GoogleDriveApi', () {
    test('isSignedIn 預設為 false', () {
      final api = GoogleDriveApi();
      expect(api.isSignedIn, false);
    });

    test('currentAccount 在未登入時為 null', () {
      final api = GoogleDriveApi();
      expect(api.currentAccount, isNull);
    });
  });
}
