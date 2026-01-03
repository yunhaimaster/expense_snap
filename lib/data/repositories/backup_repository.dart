import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/path_validator.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/remote/google_drive_api.dart';
import '../models/backup_status.dart';

/// 備份進度回調
typedef BackupProgressCallback = void Function(double progress, String message);

/// 備份 Repository 實作
///
/// 負責：
/// - 建立本地備份（DB + 圖片 → ZIP）
/// - 上傳/下載備份至 Google Drive
/// - 還原備份（含路徑驗證）
/// - 備份狀態追蹤
class BackupRepository implements IBackupRepository {
  BackupRepository({
    required DatabaseHelper databaseHelper,
    GoogleDriveApi? googleDriveApi,
  })  : _db = databaseHelper,
        _driveApi = googleDriveApi ?? GoogleDriveApi();

  final DatabaseHelper _db;
  final GoogleDriveApi _driveApi;

  // 備份檔案名稱格式
  static const String _dbFileName = 'expenses.db';
  static const String _receiptFolderName = 'receipts';

  /// 暫存目錄路徑
  Future<Directory> get _backupTempDir async {
    final dir = await getTemporaryDirectory();
    final backupDir = Directory('${dir.path}/backup');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  @override
  Future<Result<String>> createLocalBackup({
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '準備備份...');

      final archive = Archive();
      final tempDir = await _backupTempDir;

      // 1. 複製資料庫檔案
      onProgress?.call(0.1, '備份資料庫...');
      final dbPath = await _db.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return Result.failure(
          StorageException.fileNotFound('資料庫檔案不存在'),
        );
      }

      // 關閉連線並確保 WAL 寫入
      // 使用 try-finally 確保資料庫一定會重新開啟
      try {
        await _db.close();

        // 讀取資料庫（包含 WAL 內容）
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile(_dbFileName, dbBytes.length, dbBytes));
      } finally {
        // 確保資料庫重新開啟
        await _db.database;
      }

      onProgress?.call(0.3, '備份收據圖片...');

      // 2. 收集所有收據圖片
      final receiptsDir = Directory(
        '${PathValidator.appDocDir.path}/${AppConstants.receiptFolderName}',
      );

      if (await receiptsDir.exists()) {
        final imageFiles = await _collectImageFiles(receiptsDir);
        final totalImages = imageFiles.length;

        for (int i = 0; i < imageFiles.length; i++) {
          final imageFile = imageFiles[i];
          final relativePath = path.relative(
            imageFile.path,
            from: PathValidator.appDocDir.path,
          );

          final imageBytes = await imageFile.readAsBytes();
          archive.addFile(ArchiveFile(
            relativePath,
            imageBytes.length,
            imageBytes,
          ));

          // 更新進度（0.3 ~ 0.8）
          final progress = 0.3 + (0.5 * (i + 1) / totalImages);
          onProgress?.call(progress, '備份收據 ${i + 1}/$totalImages...');
        }
      }

      // 3. 壓縮 ZIP
      onProgress?.call(0.85, '壓縮備份檔案...');

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) {
        return Result.failure(ExportException.zipFailed('無法壓縮備份檔案'));
      }

      // 4. 儲存 ZIP
      final timestamp = Formatters.formatTimestampForFileName(DateTime.now());
      final fileName = 'backup_$timestamp.zip';
      final filePath = '${tempDir.path}/$fileName';

      await File(filePath).writeAsBytes(zipBytes);

      final fileSize = await File(filePath).length();
      AppLogger.info(
        'Backup created: $filePath (${Formatters.formatFileSize(fileSize)})',
        tag: 'Backup',
      );

      onProgress?.call(1.0, '備份完成');

      return Result.success(filePath);
    } catch (e) {
      // 清理可能產生的部分檔案
      try {
        final tempDir = await _backupTempDir;
        await for (final entity in tempDir.list()) {
          if (entity is File && path.basename(entity.path).startsWith('backup_')) {
            await entity.delete();
          }
        }
      } catch (_) {
        // 忽略清理失敗
      }

      AppLogger.error('createLocalBackup failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('建立備份失敗: $e'));
    }
  }

  /// 收集目錄下所有圖片檔案
  Future<List<File>> _collectImageFiles(Directory directory) async {
    final files = <File>[];

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
          files.add(entity);
        }
      }
    }

    return files;
  }

  @override
  Future<Result<void>> uploadBackupToGoogleDrive(
    String localZipPath, {
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '準備上傳...');

      final file = File(localZipPath);
      if (!await file.exists()) {
        return Result.failure(StorageException.fileNotFound(localZipPath));
      }

      final fileName = path.basename(localZipPath);
      final fileSize = await file.length();

      onProgress?.call(0.1, '上傳中...');

      final result = await _driveApi.uploadBackup(
        file: file,
        fileName: fileName,
        onProgress: (uploaded, total) {
          final progress = 0.1 + (0.8 * uploaded / total);
          onProgress?.call(progress, '上傳中 ${(progress * 100).toInt()}%...');
        },
      );

      if (result.isFailure) {
        return Result.failure((result as Failure).error);
      }

      final backupInfo = result.getOrThrow();

      // 更新備份狀態
      onProgress?.call(0.95, '更新備份記錄...');

      await _updateBackupStatus(
        lastBackupAt: DateTime.now(),
        sizeKb: (fileSize / 1024).round(),
      );

      onProgress?.call(1.0, '上傳完成');

      AppLogger.info(
        'Backup uploaded to Drive: ${backupInfo.id}',
        tag: 'Backup',
      );

      return Result.success(null);
    } catch (e) {
      AppLogger.error('uploadBackupToGoogleDrive failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('上傳備份失敗: $e'));
    }
  }

  @override
  Future<Result<List<BackupInfo>>> listGoogleDriveBackups() async {
    try {
      final result = await _driveApi.listBackups();

      if (result.isFailure) {
        return Result.failure((result as Failure).error);
      }

      final driveBackups = result.getOrThrow();
      final backups = driveBackups
          .map((b) => BackupInfo(
                fileId: b.id,
                fileName: b.name,
                createdAt: b.createdTime,
                sizeBytes: b.sizeBytes,
              ))
          .toList();

      return Result.success(backups);
    } catch (e) {
      AppLogger.error('listGoogleDriveBackups failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('無法列出備份: $e'));
    }
  }

  @override
  Future<Result<String>> downloadBackupFromGoogleDrive(
    String fileId, {
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '準備下載...');

      final result = await _driveApi.downloadBackup(fileId);

      if (result.isFailure) {
        return Result.failure((result as Failure).error);
      }

      onProgress?.call(0.7, '儲存檔案...');

      final bytes = result.getOrThrow();
      final tempDir = await _backupTempDir;
      final fileName = 'restore_${DateTime.now().millisecondsSinceEpoch}.zip';
      final filePath = '${tempDir.path}/$fileName';

      await File(filePath).writeAsBytes(bytes);

      onProgress?.call(1.0, '下載完成');

      AppLogger.info('Backup downloaded: $filePath', tag: 'Backup');
      return Result.success(filePath);
    } catch (e) {
      AppLogger.error('downloadBackupFromGoogleDrive failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('下載備份失敗: $e'));
    }
  }

  @override
  Future<Result<void>> restoreFromBackup(
    String zipPath, {
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '驗證備份檔案...');

      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        return Result.failure(StorageException.fileNotFound(zipPath));
      }

      // 讀取 ZIP
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 驗證備份完整性
      final validationResult = _validateBackupArchive(archive);
      if (validationResult.isFailure) {
        return validationResult;
      }

      onProgress?.call(0.1, '準備還原...');

      // 關閉資料庫
      await _db.close();

      // 還原資料庫
      onProgress?.call(0.2, '還原資料庫...');
      final dbRestoreResult = await _restoreDatabase(archive);
      if (dbRestoreResult.isFailure) {
        // 重新開啟資料庫
        await _db.database;
        return dbRestoreResult;
      }

      // 還原收據圖片
      onProgress?.call(0.4, '還原收據圖片...');
      final imageRestoreResult = await _restoreReceipts(archive, onProgress);
      if (imageRestoreResult.isFailure) {
        // 重新開啟資料庫
        await _db.database;
        return imageRestoreResult;
      }

      // 重新開啟資料庫
      await _db.database;

      onProgress?.call(1.0, '還原完成');

      AppLogger.info('Backup restored successfully', tag: 'Backup');
      return Result.success(null);
    } catch (e) {
      // 確保資料庫重新開啟
      try {
        await _db.database;
      } catch (_) {}

      AppLogger.error('restoreFromBackup failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('還原備份失敗: $e'));
    }
  }

  /// 驗證備份檔案完整性
  Result<void> _validateBackupArchive(Archive archive) {
    // 檢查是否包含資料庫
    final hasDb = archive.any((file) => file.name == _dbFileName);
    if (!hasDb) {
      return Result.failure(
        const StorageException('備份檔案不完整：缺少資料庫', code: 'INVALID_BACKUP'),
      );
    }

    // 驗證所有路徑安全性
    for (final file in archive) {
      if (!_isPathSafeForRestore(file.name)) {
        AppLogger.warning('Unsafe path in backup: ${file.name}', tag: 'Backup');
        return Result.failure(
          StorageException.unsafePath(file.name),
        );
      }
    }

    return Result.success(null);
  }

  /// 驗證路徑是否安全用於還原
  ///
  /// 防止目錄遍歷攻擊，包含 URL 編碼繞過
  bool _isPathSafeForRestore(String filePath) {
    // 解碼 URL 編碼字元（防止 %2e%2e 繞過）
    String decodedPath;
    try {
      decodedPath = Uri.decodeComponent(filePath);
    } catch (_) {
      // 解碼失敗視為不安全
      return false;
    }

    // 如果解碼後與原始路徑不同，拒絕（防止編碼攻擊）
    if (decodedPath != filePath) {
      AppLogger.warning(
        'Rejected URL-encoded path: $filePath',
        tag: 'Backup',
      );
      return false;
    }

    // 正規化路徑並檢查目錄遍歷
    final normalized = path.normalize(filePath);
    if (normalized.contains('..')) return false;

    // 禁止絕對路徑
    if (filePath.startsWith('/') || filePath.startsWith('\\')) return false;

    // 禁止控制字元（ASCII 0-31 和 127）
    if (filePath.codeUnits.any((c) => c < 32 || c == 127)) return false;

    // 只允許特定檔案類型
    if (filePath == _dbFileName) return true;

    if (filePath.startsWith('$_receiptFolderName/')) {
      final ext = path.extension(filePath).toLowerCase();
      // 禁止雙重副檔名（如 image.jpg.exe）
      final baseName = path.basenameWithoutExtension(filePath);
      if (baseName.contains('.')) {
        AppLogger.warning(
          'Rejected double extension: $filePath',
          tag: 'Backup',
        );
        return false;
      }
      return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
    }

    return false;
  }

  /// 還原資料庫
  Future<Result<void>> _restoreDatabase(Archive archive) async {
    try {
      final dbEntry = archive.firstWhere((file) => file.name == _dbFileName);
      final dbPath = await _db.getDatabasePath();

      // 備份現有資料庫（以防還原失敗）
      final existingDb = File(dbPath);
      final backupPath = '$dbPath.bak';

      if (await existingDb.exists()) {
        await existingDb.copy(backupPath);
      }

      try {
        // 寫入新資料庫
        await File(dbPath).writeAsBytes(dbEntry.content as Uint8List);

        // 刪除備份
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }

        return Result.success(null);
      } catch (e) {
        // 還原失敗，恢復備份
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.copy(dbPath);
          await backupFile.delete();
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.error('restoreDatabase failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('還原資料庫失敗: $e'));
    }
  }

  /// 還原收據圖片
  Future<Result<void>> _restoreReceipts(
    Archive archive,
    BackupProgressCallback? onProgress,
  ) async {
    try {
      final receiptFiles = archive
          .where((file) => file.name.startsWith('$_receiptFolderName/'))
          .toList();

      if (receiptFiles.isEmpty) {
        return Result.success(null);
      }

      final baseDir = PathValidator.appDocDir.path;
      final totalFiles = receiptFiles.length;

      for (int i = 0; i < receiptFiles.length; i++) {
        final file = receiptFiles[i];
        final targetPath = '$baseDir/${file.name}';

        // 再次驗證路徑安全性
        if (!_isPathSafeForRestore(file.name)) {
          AppLogger.warning('Skipping unsafe path: ${file.name}', tag: 'Backup');
          continue;
        }

        // 確保目錄存在
        final targetDir = Directory(path.dirname(targetPath));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        // 寫入檔案
        await File(targetPath).writeAsBytes(file.content as Uint8List);

        // 更新進度（0.4 ~ 0.95）
        final progress = 0.4 + (0.55 * (i + 1) / totalFiles);
        onProgress?.call(progress, '還原收據 ${i + 1}/$totalFiles...');
      }

      return Result.success(null);
    } catch (e) {
      AppLogger.error('restoreReceipts failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('還原收據圖片失敗: $e'));
    }
  }

  @override
  Future<Result<BackupStatus>> getBackupStatus() async {
    try {
      final statusMap = await _db.getBackupStatus();

      if (statusMap == null) {
        return Result.success(BackupStatus.empty());
      }

      // 取得 Google 帳號資訊
      final accountInfo = _driveApi.currentAccount;
      final email = accountInfo?.email ?? statusMap['google_email'] as String?;

      final status = BackupStatus.fromMap({
        ...statusMap,
        'google_email': email,
      });

      return Result.success(status);
    } catch (e) {
      AppLogger.error('getBackupStatus failed', error: e, tag: 'Backup');
      return Result.failure(DatabaseException.queryFailed(e.toString()));
    }
  }

  /// 更新備份狀態
  Future<void> _updateBackupStatus({
    required DateTime lastBackupAt,
    required int sizeKb,
  }) async {
    // 取得支出總數
    final now = DateTime.now();
    final summary = await _db.getMonthSummary(now.year, now.month);
    final count = summary['total_count'] as int? ?? 0;

    final accountInfo = _driveApi.currentAccount;

    await _db.updateBackupStatus({
      'last_backup_at': Formatters.formatDateForStorage(lastBackupAt),
      'last_backup_count': count,
      'last_backup_size_kb': sizeKb,
      'google_email': accountInfo?.email,
    });
  }

  @override
  Future<Result<String>> signInWithGoogle() async {
    final result = await _driveApi.signIn();

    if (result.isFailure) {
      return Result.failure((result as Failure).error);
    }

    final accountInfo = result.getOrThrow();

    // 儲存 email 到備份狀態
    await _db.updateBackupStatus({
      'google_email': accountInfo.email,
    });

    return Result.success(accountInfo.email);
  }

  @override
  Future<Result<void>> signOutFromGoogle() async {
    final result = await _driveApi.signOut();

    if (result.isFailure) {
      return result;
    }

    // 清除備份狀態中的 email
    await _db.updateBackupStatus({
      'google_email': null,
    });

    return Result.success(null);
  }

  @override
  Future<bool> isGoogleSignedIn() async {
    return _driveApi.isSignedIn;
  }

  /// 嘗試恢復 Google 登入狀態
  Future<Result<String?>> tryRestoreGoogleSession() async {
    final result = await _driveApi.tryRestoreSession();

    if (result.isFailure) {
      return Result.failure((result as Failure).error);
    }

    final accountInfo = result.getOrNull();
    return Result.success(accountInfo?.email);
  }

  /// 清理備份暫存檔案
  Future<Result<int>> cleanupBackupTempFiles() async {
    try {
      final tempDir = await _backupTempDir;
      if (!await tempDir.exists()) {
        return Result.success(0);
      }

      int deletedCount = 0;
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          await entity.delete();
          deletedCount++;
        }
      }

      AppLogger.info('Cleaned up $deletedCount backup temp files', tag: 'Backup');
      return Result.success(deletedCount);
    } catch (e) {
      AppLogger.error('cleanupBackupTempFiles failed', error: e, tag: 'Backup');
      return Result.failure(StorageException('清理備份暫存失敗: $e'));
    }
  }

  /// 計算本地儲存使用量（KB）
  Future<int> calculateLocalStorageUsageKb() async {
    int totalBytes = 0;

    try {
      // 資料庫大小
      final dbPath = await _db.getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        totalBytes += await dbFile.length();
      }

      // 收據圖片大小
      final receiptsDir = Directory(
        '${PathValidator.appDocDir.path}/${AppConstants.receiptFolderName}',
      );

      if (await receiptsDir.exists()) {
        await for (final entity in receiptsDir.list(recursive: true)) {
          if (entity is File) {
            totalBytes += await entity.length();
          }
        }
      }

      return (totalBytes / 1024).round();
    } catch (e) {
      AppLogger.error('calculateLocalStorageUsageKb failed', error: e, tag: 'Backup');
      return 0;
    }
  }
}
