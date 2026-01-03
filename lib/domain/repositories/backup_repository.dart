import '../../core/errors/result.dart';
import '../../data/models/backup_status.dart';

/// 備份 Repository 抽象介面
abstract class IBackupRepository {
  /// 建立本地備份 ZIP
  Future<Result<String>> createLocalBackup();

  /// 上傳備份到 Google Drive
  Future<Result<void>> uploadBackupToGoogleDrive(String localZipPath);

  /// 取得 Google Drive 備份列表
  Future<Result<List<BackupInfo>>> listGoogleDriveBackups();

  /// 從 Google Drive 下載備份
  Future<Result<String>> downloadBackupFromGoogleDrive(String fileId);

  /// 從備份還原
  Future<Result<void>> restoreFromBackup(String zipPath);

  /// 取得備份狀態
  Future<Result<BackupStatus>> getBackupStatus();

  /// 登入 Google
  Future<Result<String>> signInWithGoogle();

  /// 登出 Google
  Future<Result<void>> signOutFromGoogle();

  /// 檢查是否已登入 Google
  Future<bool> isGoogleSignedIn();
}

/// 備份檔案資訊
class BackupInfo {
  const BackupInfo({
    required this.fileId,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String fileId;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
}
