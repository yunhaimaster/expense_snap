import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/repositories/backup_repository.dart' show BackupInfo;
import 'google_auth_provider.dart';

/// 備份操作狀態
enum BackupOperationState {
  idle,
  preparing,
  inProgress,
  completing,
  success,
  error,
}

/// 備份 Provider
///
/// 管理：
/// - 備份/還原操作
/// - 備份進度狀態
/// - 雲端備份列表
/// - 本地儲存使用量
class BackupProvider extends ChangeNotifier {
  BackupProvider({
    required BackupRepository backupRepository,
    required GoogleAuthProvider googleAuthProvider,
  }) : _backupRepo = backupRepository,
       _authProvider = googleAuthProvider;

  final BackupRepository _backupRepo;
  final GoogleAuthProvider _authProvider;

  bool _disposed = false;
  bool _operationLock = false;

  // ============ 狀態 ============

  BackupOperationState _operationState = BackupOperationState.idle;
  double _operationProgress = 0.0;
  String _operationMessage = '';
  String? _errorMessage;
  int _localStorageUsageKb = 0;
  List<BackupInfo> _cloudBackups = [];

  // ============ Getters ============

  BackupOperationState get operationState => _operationState;
  double get operationProgress => _operationProgress;
  String get operationMessage => _operationMessage;
  String? get errorMessage => _errorMessage;
  int get localStorageUsageKb => _localStorageUsageKb;

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

  /// 計算儲存使用量
  Future<void> calculateStorageUsage() async {
    _localStorageUsageKb = await _backupRepo.calculateLocalStorageUsageKb();
    _safeNotifyListeners();
  }

  // ============ 備份操作 ============

  /// 執行備份到 Google Drive
  Future<Result<void>> backupToGoogleDrive() async {
    if (!_authProvider.isGoogleConnected) {
      return Result.failure(
        const AuthException('請先連結 Google 帳號', code: 'NOT_CONNECTED'),
      );
    }

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
            progress * 0.5,
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
            0.5 + progress * 0.5,
            message,
          );
        },
      );

      if (uploadResult.isFailure) {
        _setError(uploadResult.errorOrNull?.message ?? '上傳失敗');
        return uploadResult;
      }

      // 更新狀態
      await _authProvider.loadBackupStatus();
      await calculateStorageUsage();

      _setOperationState(BackupOperationState.success, 1.0, '備份完成');
      return Result.success(null);
    } on Object catch (e) {
      AppLogger.error(
        'Backup to Google Drive failed',
        error: e,
        tag: 'Backup',
      );
      _setError('備份失敗: $e');
      return Result.failure(StorageException('備份失敗: $e'));
    } finally {
      _operationLock = false;
    }
  }

  /// 從 Google Drive 還原
  Future<Result<void>> restoreFromGoogleDrive(String fileId) async {
    if (fileId.isEmpty) {
      return Result.failure(
        const StorageException('無效的備份檔案 ID', code: 'INVALID_FILE_ID'),
      );
    }

    if (!_authProvider.isGoogleConnected) {
      return Result.failure(
        const AuthException('請先連結 Google 帳號', code: 'NOT_CONNECTED'),
      );
    }

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
            progress * 0.3,
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
            0.3 + progress * 0.7,
            message,
          );
        },
      );

      if (restoreResult.isFailure) {
        _setError(restoreResult.errorOrNull?.message ?? '還原失敗');
        return restoreResult;
      }

      // 更新狀態
      await _authProvider.loadBackupStatus();
      await calculateStorageUsage();

      _setOperationState(BackupOperationState.success, 1.0, '還原完成');
      return Result.success(null);
    } on Object catch (e) {
      AppLogger.error(
        'Restore from Google Drive failed',
        error: e,
        tag: 'Backup',
      );
      _setError('還原失敗: $e');
      return Result.failure(StorageException('還原失敗: $e'));
    } finally {
      _operationLock = false;
    }
  }

  /// 載入雲端備份列表
  Future<Result<List<BackupInfo>>> loadCloudBackups() async {
    if (!_authProvider.isGoogleConnected) {
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
        await calculateStorageUsage();
      }

      return result;
    } on Object catch (e) {
      AppLogger.error('Cleanup temp files failed', error: e, tag: 'Backup');
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
    await _authProvider.loadBackupStatus();
    await calculateStorageUsage();
    if (_authProvider.isGoogleConnected) {
      await loadCloudBackups();
    }
    _safeNotifyListeners();
  }
}
