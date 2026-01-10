import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/backup_status.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/repositories/backup_repository.dart' show BackupInfo;

/// 備份操作狀態
enum BackupOperationState {
  idle,
  preparing,
  inProgress,
  completing,
  success,
  error,
}

/// 設定 Provider
///
/// 管理：
/// - 使用者設定（姓名）
/// - Google 帳號連接狀態
/// - 備份/還原操作
/// - 本地儲存使用量
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required DatabaseHelper databaseHelper,
    required BackupRepository backupRepository,
  })  : _db = databaseHelper,
        _backupRepo = backupRepository;

  final DatabaseHelper _db;
  final BackupRepository _backupRepo;

  // 操作鎖（防止並發操作）
  bool _operationLock = false;

  // 是否已 dispose
  bool _disposed = false;

  // ============ 狀態 ============

  bool _isLoading = true;
  String _userName = AppConstants.defaultUserName;
  BackupStatus _backupStatus = BackupStatus.empty();
  BackupOperationState _operationState = BackupOperationState.idle;
  double _operationProgress = 0.0;
  String _operationMessage = '';
  String? _errorMessage;
  int _localStorageUsageKb = 0;
  List<BackupInfo> _cloudBackups = [];

  // ============ Getters ============

  bool get isLoading => _isLoading;
  String get userName => _userName;
  BackupStatus get backupStatus => _backupStatus;
  BackupOperationState get operationState => _operationState;
  double get operationProgress => _operationProgress;
  String get operationMessage => _operationMessage;
  String? get errorMessage => _errorMessage;
  int get localStorageUsageKb => _localStorageUsageKb;

  /// 是否已連結 Google
  bool get isGoogleConnected => _backupStatus.isGoogleConnected;

  /// 雲端備份列表（不可變）
  List<BackupInfo> get cloudBackups => List.unmodifiable(_cloudBackups);

  /// 是否正在執行操作
  bool get isOperationInProgress =>
      _operationState == BackupOperationState.preparing ||
      _operationState == BackupOperationState.inProgress ||
      _operationState == BackupOperationState.completing;

  /// 格式化的本地儲存使用量
  String get formattedStorageUsage {
    if (_localStorageUsageKb < 1024) {
      return '$_localStorageUsageKb KB';
    }
    return '${(_localStorageUsageKb / 1024).toStringAsFixed(1)} MB';
  }

  // ============ 生命週期 ============

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// 安全的 notifyListeners（防止 dispose 後呼叫）
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============ 初始化 ============

  /// 載入所有設定
  Future<void> loadSettings() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      // 載入使用者名稱
      final name = await _db.getSetting('user_name');
      _userName = name ?? AppConstants.defaultUserName;

      // 嘗試恢復 Google 登入狀態
      await _backupRepo.tryRestoreGoogleSession();

      // 載入備份狀態
      await _loadBackupStatus();

      // 計算儲存使用量
      await _calculateStorageUsage();

      _isLoading = false;
      _errorMessage = null;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.error('loadSettings failed', error: e, tag: 'Settings');
      _errorMessage = '載入設定失敗: $e';
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// 載入備份狀態
  Future<void> _loadBackupStatus() async {
    final result = await _backupRepo.getBackupStatus();
    result.fold(
      onFailure: (error) {
        AppLogger.error('Failed to load backup status: ${error.message}');
      },
      onSuccess: (status) {
        _backupStatus = status;
      },
    );
  }

  /// 計算儲存使用量
  Future<void> _calculateStorageUsage() async {
    _localStorageUsageKb = await _backupRepo.calculateLocalStorageUsageKb();
  }

  // ============ 使用者設定 ============

  /// 更新使用者名稱
  Future<bool> updateUserName(String newName) async {
    if (newName.isEmpty) return false;

    try {
      await _db.setSetting('user_name', newName);
      _userName = newName;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('updateUserName failed', error: e, tag: 'Settings');
      return false;
    }
  }

  // ============ Google 帳號 ============

  /// 連結 Google 帳號
  Future<Result<void>> connectGoogle() async {
    // 防止並發操作
    if (_operationLock) {
      return Result.failure(
        const StorageException('另一個操作正在進行中', code: 'OPERATION_IN_PROGRESS'),
      );
    }
    _operationLock = true;

    try {
      _setOperationState(BackupOperationState.preparing, 0.0, '連接 Google 帳號...');

      final result = await _backupRepo.signInWithGoogle();

      return result.fold(
        onFailure: (error) {
          _setError(error.message);
          return Result.failure(error);
        },
        onSuccess: (email) async {
          await _loadBackupStatus();
          _setOperationState(BackupOperationState.success, 1.0, '已連接 $email');
          return Result.success(null);
        },
      );
    } finally {
      _operationLock = false;
    }
  }

  /// 斷開 Google 帳號
  Future<Result<void>> disconnectGoogle() async {
    // 防止並發操作
    if (_operationLock) {
      return Result.failure(
        const StorageException('另一個操作正在進行中', code: 'OPERATION_IN_PROGRESS'),
      );
    }
    _operationLock = true;

    try {
      _setOperationState(BackupOperationState.preparing, 0.0, '斷開連接...');

      final result = await _backupRepo.signOutFromGoogle();

      return result.fold(
        onFailure: (error) {
          _setError(error.message);
          return Result.failure(error);
        },
        onSuccess: (_) async {
          await _loadBackupStatus();
          _cloudBackups = [];
          _setOperationState(BackupOperationState.success, 1.0, '已斷開連接');
          return Result.success(null);
        },
      );
    } finally {
      _operationLock = false;
    }
  }

  // ============ 備份操作 ============

  /// 執行備份到 Google Drive
  Future<Result<void>> backupToGoogleDrive() async {
    if (!isGoogleConnected) {
      return Result.failure(
        const AuthException('請先連結 Google 帳號', code: 'NOT_CONNECTED'),
      );
    }

    // 防止並發操作
    if (_operationLock) {
      return Result.failure(
        const StorageException('另一個操作正在進行中', code: 'OPERATION_IN_PROGRESS'),
      );
    }
    _operationLock = true;

    try {
      _setOperationState(BackupOperationState.preparing, 0.0, '準備備份...');

      // 1. 建立本地備份
      final localResult = await _backupRepo.createLocalBackup(
        onProgress: (progress, message) {
          _setOperationState(
            BackupOperationState.inProgress,
            progress * 0.5, // 本地備份佔 50%
            message,
          );
        },
      );

      if (localResult.isFailure) {
        final error = localResult.errorOrNull!;
        _setError(error.message);
        return Result.failure(error);
      }

      final localPath = localResult.getOrThrow();

      // 2. 上傳到 Google Drive
      final uploadResult = await _backupRepo.uploadBackupToGoogleDrive(
        localPath,
        onProgress: (progress, message) {
          _setOperationState(
            BackupOperationState.inProgress,
            0.5 + progress * 0.5, // 上傳佔 50%
            message,
          );
        },
      );

      if (uploadResult.isFailure) {
        _setError(uploadResult.errorOrNull?.message ?? '上傳失敗');
        return uploadResult;
      }

      // 更新狀態
      await _loadBackupStatus();
      await _calculateStorageUsage();

      _setOperationState(BackupOperationState.success, 1.0, '備份完成');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Backup to Google Drive failed', error: e, tag: 'Settings');
      _setError('備份失敗: $e');
      return Result.failure(StorageException('備份失敗: $e'));
    } finally {
      _operationLock = false;
    }
  }

  /// 從 Google Drive 還原
  Future<Result<void>> restoreFromGoogleDrive(String fileId) async {
    // 驗證 fileId
    if (fileId.isEmpty) {
      return Result.failure(
        const StorageException('無效的備份檔案 ID', code: 'INVALID_FILE_ID'),
      );
    }

    // 檢查 Google 連接狀態
    if (!isGoogleConnected) {
      return Result.failure(
        const AuthException('請先連結 Google 帳號', code: 'NOT_CONNECTED'),
      );
    }

    // 防止並發操作
    if (_operationLock) {
      return Result.failure(
        const StorageException('另一個操作正在進行中', code: 'OPERATION_IN_PROGRESS'),
      );
    }
    _operationLock = true;

    try {
      _setOperationState(BackupOperationState.preparing, 0.0, '準備還原...');

      // 1. 下載備份
      final downloadResult = await _backupRepo.downloadBackupFromGoogleDrive(
        fileId,
        onProgress: (progress, message) {
          _setOperationState(
            BackupOperationState.inProgress,
            progress * 0.3, // 下載佔 30%
            message,
          );
        },
      );

      if (downloadResult.isFailure) {
        final error = downloadResult.errorOrNull!;
        _setError(error.message);
        return Result.failure(error);
      }

      final zipPath = downloadResult.getOrThrow();

      // 2. 還原
      final restoreResult = await _backupRepo.restoreFromBackup(
        zipPath,
        onProgress: (progress, message) {
          _setOperationState(
            BackupOperationState.inProgress,
            0.3 + progress * 0.7, // 還原佔 70%
            message,
          );
        },
      );

      if (restoreResult.isFailure) {
        _setError(restoreResult.errorOrNull?.message ?? '還原失敗');
        return restoreResult;
      }

      // 更新狀態
      await _loadBackupStatus();
      await _calculateStorageUsage();

      _setOperationState(BackupOperationState.success, 1.0, '還原完成');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Restore from Google Drive failed', error: e, tag: 'Settings');
      _setError('還原失敗: $e');
      return Result.failure(StorageException('還原失敗: $e'));
    } finally {
      _operationLock = false;
    }
  }

  /// 載入雲端備份列表
  Future<Result<List<BackupInfo>>> loadCloudBackups() async {
    if (!isGoogleConnected) {
      return Result.success([]);
    }

    final result = await _backupRepo.listGoogleDriveBackups();

    return result.fold(
      onFailure: (error) {
        AppLogger.error('Failed to load cloud backups: ${error.message}');
        return Result.failure(error);
      },
      onSuccess: (backups) {
        _cloudBackups = backups;
        _safeNotifyListeners();
        return Result.success(backups);
      },
    );
  }

  // ============ 清理 ============

  /// 清理暫存檔案
  Future<Result<int>> cleanupTempFiles() async {
    try {
      final result = await _backupRepo.cleanupBackupTempFiles();

      if (result.isSuccess) {
        await _calculateStorageUsage();
        _safeNotifyListeners();
      }

      return result;
    } catch (e) {
      AppLogger.error('Cleanup temp files failed', error: e, tag: 'Settings');
      return Result.failure(StorageException('清理失敗: $e'));
    }
  }

  // ============ 輔助方法 ============

  /// 設定操作狀態
  void _setOperationState(
    BackupOperationState state,
    double progress,
    String message,
  ) {
    _operationState = state;
    _operationProgress = progress;
    _operationMessage = message;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// 設定錯誤
  void _setError(String message) {
    _operationState = BackupOperationState.error;
    _errorMessage = message;
    _safeNotifyListeners();
  }

  /// 重置操作狀態
  void resetOperationState() {
    _operationState = BackupOperationState.idle;
    _operationProgress = 0.0;
    _operationMessage = '';
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// 刷新所有資料
  Future<void> refresh() async {
    await _loadBackupStatus();
    await _calculateStorageUsage();
    if (isGoogleConnected) {
      await loadCloudBackups();
    }
    _safeNotifyListeners();
  }
}
