import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/backup_status.dart';
import '../../data/repositories/backup_repository.dart';

/// Google 帳號認證 Provider
///
/// 管理：
/// - Google Sign-In / Sign-Out
/// - 認證狀態
/// - 備份狀態（與認證相關）
class GoogleAuthProvider extends ChangeNotifier {
  GoogleAuthProvider({
    required BackupRepository backupRepository,
  }) : _backupRepo = backupRepository;

  final BackupRepository _backupRepo;

  bool _disposed = false;
  bool _operationLock = false;

  // ============ 狀態 ============

  BackupStatus _backupStatus = BackupStatus.empty();
  String? _errorMessage;

  // ============ Getters ============

  BackupStatus get backupStatus => _backupStatus;
  String? get errorMessage => _errorMessage;

  /// 是否已連結 Google
  bool get isGoogleConnected => _backupStatus.isGoogleConnected;

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

  /// 嘗試恢復 Google 登入狀態並載入備份狀態
  Future<void> initialize() async {
    try {
      await _backupRepo.tryRestoreGoogleSession();
      await loadBackupStatus();
    } on Exception catch (e) {
      AppLogger.error('GoogleAuthProvider init failed', error: e, tag: 'Auth');
    }
  }

  /// 載入備份狀態
  Future<void> loadBackupStatus() async {
    final result = await _backupRepo.getBackupStatus();
    result.fold(
      onFailure: (error) {
        AppLogger.error('Failed to load backup status: ${error.message}');
      },
      onSuccess: (status) {
        _backupStatus = status;
        _safeNotifyListeners();
      },
    );
  }

  // ============ Google 帳號 ============

  /// 連結 Google 帳號
  Future<Result<void>> connectGoogle() async {
    if (_operationLock) {
      return Result.failure(
        const StorageException('另一個操作正在進行中', code: 'OPERATION_IN_PROGRESS'),
      );
    }
    _operationLock = true;

    try {
      final result = await _backupRepo.signInWithGoogle();

      return result.fold(
        onFailure: (error) {
          _errorMessage = error.message;
          _safeNotifyListeners();
          return Result.failure(error);
        },
        onSuccess: (email) async {
          await loadBackupStatus();
          _errorMessage = null;
          _safeNotifyListeners();
          return Result.success(null);
        },
      );
    } finally {
      _operationLock = false;
    }
  }

  /// 斷開 Google 帳號
  Future<Result<void>> disconnectGoogle() async {
    if (_operationLock) {
      return Result.failure(
        const StorageException('另一個操作正在進行中', code: 'OPERATION_IN_PROGRESS'),
      );
    }
    _operationLock = true;

    try {
      final result = await _backupRepo.signOutFromGoogle();

      return result.fold(
        onFailure: (error) {
          _errorMessage = error.message;
          _safeNotifyListeners();
          return Result.failure(error);
        },
        onSuccess: (_) async {
          await loadBackupStatus();
          _errorMessage = null;
          _safeNotifyListeners();
          return Result.success(null);
        },
      );
    } finally {
      _operationLock = false;
    }
  }
}
