import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/domain/repositories/backup_repository.dart';

/// 備份 Repository 測試
///
/// 注意：完整的備份/還原測試需要整合測試環境
/// 這裡測試資料結構和輔助方法
void main() {
  group('BackupInfo', () {
    test('應正確建立備份資訊', () {
      final info = BackupInfo(
        fileId: 'file_123',
        fileName: 'backup_20250103_120000.zip',
        createdAt: DateTime(2025, 1, 3, 12, 0, 0),
        sizeBytes: 1024 * 1024 * 2, // 2MB
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

      // 不同的備份資訊
      expect(info1.fileId, isNot(info2.fileId));
      expect(info1.createdAt.isBefore(info2.createdAt), true);
    });
  });

  group('Backup Path Validation', () {
    // 測試路徑安全性驗證邏輯
    test('目錄遍歷路徑應被識別為不安全', () {
      final unsafePaths = [
        '../etc/passwd',
        'receipts/../../../etc/passwd',
        '..\\windows\\system32',
        '/absolute/path.jpg',
        '\\absolute\\path.jpg',
      ];

      for (final path in unsafePaths) {
        expect(_isPathSafeForRestore(path), false, reason: 'Path should be unsafe: $path');
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
        expect(_isPathSafeForRestore(path), true, reason: 'Path should be safe: $path');
      }
    });

    test('不支援的檔案類型應被拒絕', () {
      final invalidPaths = [
        'receipts/2025-01/script.exe',
        'receipts/2025-01/virus.bat',
        'receipts/2025-01/data.txt',
        'other_folder/image.jpg', // 不在 receipts 資料夾內
      ];

      for (final path in invalidPaths) {
        expect(_isPathSafeForRestore(path), false, reason: 'Path should be invalid: $path');
      }
    });
  });
}

/// 模擬備份還原時的路徑驗證邏輯
/// 與 BackupRepository._isPathSafeForRestore 相同
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
