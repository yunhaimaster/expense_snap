import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';
import '../local/secure_storage_helper.dart';

/// Google Drive 備份資訊
class DriveBackupInfo {
  const DriveBackupInfo({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
  });

  /// 檔案 ID
  final String id;

  /// 檔案名稱
  final String name;

  /// 建立時間
  final DateTime createdTime;

  /// 檔案大小（bytes）
  final int sizeBytes;

  /// 格式化大小
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() => 'DriveBackupInfo($name, $formattedSize, $createdTime)';
}

/// Google 帳號資訊
class GoogleAccountInfo {
  const GoogleAccountInfo({
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// 上傳進度回調
typedef UploadProgressCallback = void Function(int uploaded, int total);

/// Google Drive API 封裝
///
/// 使用 drive.file scope：僅存取 App 建立的檔案
class GoogleDriveApi {
  GoogleDriveApi({
    GoogleSignIn? googleSignIn,
    SecureStorageHelper? secureStorage,
  })  : _googleSignIn = googleSignIn ?? _createGoogleSignIn(),
        _secureStorage = secureStorage ?? SecureStorageHelper.instance;

  final GoogleSignIn _googleSignIn;
  final SecureStorageHelper _secureStorage;

  // 備份資料夾名稱
  static const String _backupFolderName = 'ExpenseTracker';

  // 備份檔案 MIME 類型
  static const String _backupMimeType = 'application/zip';

  // 大檔案閾值（5MB 以上使用 resumable upload）
  static const int _resumableUploadThreshold = 5 * 1024 * 1024;

  // 當前登入帳號
  GoogleSignInAccount? _currentAccount;

  // Drive API 客戶端
  drive.DriveApi? _driveApi;

  // HTTP 客戶端（需要手動關閉）
  http.Client? _httpClient;

  // Token 刷新鎖（防止並發刷新）
  bool _isRefreshing = false;
  Completer<Result<void>>? _refreshCompleter;

  /// 建立 GoogleSignIn 實例
  static GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: [
        // 僅存取 App 建立的檔案，不存取其他 Drive 內容
        'https://www.googleapis.com/auth/drive.file',
      ],
    );
  }

  /// 是否已登入
  bool get isSignedIn => _currentAccount != null;

  /// 當前帳號資訊
  GoogleAccountInfo? get currentAccount {
    final account = _currentAccount;
    if (account == null) return null;

    return GoogleAccountInfo(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  /// 登入 Google 帳號
  Future<Result<GoogleAccountInfo>> signIn() async {
    try {
      AppLogger.info('Starting Google Sign-In', tag: 'GoogleDrive');

      // 嘗試靜默登入（使用已儲存的憑證）
      var account = await _googleSignIn.signInSilently();

      // 靜默登入失敗，顯示登入對話框
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        AppLogger.warning('Google Sign-In cancelled', tag: 'GoogleDrive');
        return Result.failure(AuthException.cancelled());
      }

      _currentAccount = account;

      // 初始化 Drive API
      await _initDriveApi();

      AppLogger.info('Google Sign-In successful: ${account.email}', tag: 'GoogleDrive');

      return Result.success(GoogleAccountInfo(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      ));
    } catch (e) {
      AppLogger.error('Google Sign-In failed', error: e, tag: 'GoogleDrive');
      return Result.failure(AuthException('登入失敗: $e'));
    }
  }

  /// 登出
  Future<Result<void>> signOut() async {
    try {
      AppLogger.info('Signing out from Google', tag: 'GoogleDrive');

      await _googleSignIn.signOut();
      await _secureStorage.clearGoogleTokens();

      // 關閉 HTTP 客戶端
      _httpClient?.close();
      _httpClient = null;
      _currentAccount = null;
      _driveApi = null;

      AppLogger.info('Google Sign-Out successful', tag: 'GoogleDrive');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Google Sign-Out failed', error: e, tag: 'GoogleDrive');
      return Result.failure(AuthException('登出失敗: $e'));
    }
  }

  /// 斷開連接（revoke access）
  Future<Result<void>> disconnect() async {
    try {
      AppLogger.info('Disconnecting Google account', tag: 'GoogleDrive');

      await _googleSignIn.disconnect();
      await _secureStorage.clearGoogleTokens();

      // 關閉 HTTP 客戶端
      _httpClient?.close();
      _httpClient = null;
      _currentAccount = null;
      _driveApi = null;

      AppLogger.info('Google account disconnected', tag: 'GoogleDrive');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Google disconnect failed', error: e, tag: 'GoogleDrive');
      return Result.failure(AuthException('斷開連接失敗: $e'));
    }
  }

  /// 初始化 Drive API
  Future<void> _initDriveApi() async {
    final account = _currentAccount;
    if (account == null) {
      throw AuthException.notSignedIn();
    }

    final auth = await account.authentication;
    final accessToken = auth.accessToken;

    if (accessToken == null) {
      throw AuthException.tokenExpired();
    }

    // 儲存 tokens
    await _secureStorage.saveGoogleAccessToken(accessToken);

    // 關閉舊的 HTTP 客戶端（防止資源洩漏）
    _httpClient?.close();

    // 建立新的 HTTP 客戶端
    _httpClient = _GoogleAuthClient(accessToken);
    _driveApi = drive.DriveApi(_httpClient!);
  }

  /// 確保已登入並刷新 token
  ///
  /// 使用鎖機制防止並發刷新
  Future<Result<void>> _ensureAuthenticated() async {
    if (_currentAccount == null) {
      return Result.failure(AuthException.notSignedIn());
    }

    // 如果正在刷新，等待完成
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<Result<void>>();

    try {
      // 嘗試刷新 token
      final auth = await _currentAccount!.authentication;
      if (auth.accessToken == null) {
        // Token 無效，嘗試靜默重新登入
        final account = await _googleSignIn.signInSilently();
        if (account == null) {
          final failure = Result<void>.failure(AuthException.tokenExpired());
          _refreshCompleter!.complete(failure);
          return failure;
        }
        _currentAccount = account;
        await _initDriveApi();
      } else {
        // 更新 Drive API 客戶端
        await _initDriveApi();
      }

      final success = Result<void>.success(null);
      _refreshCompleter!.complete(success);
      return success;
    } catch (e) {
      AppLogger.error('Token refresh failed', error: e, tag: 'GoogleDrive');
      final failure = Result<void>.failure(AuthException.tokenExpired());
      _refreshCompleter!.complete(failure);
      return failure;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 取得或建立備份資料夾
  Future<Result<String>> _getOrCreateBackupFolder() async {
    final authResult = await _ensureAuthenticated();
    if (authResult.isFailure) {
      return Result.failure((authResult as Failure).error);
    }

    try {
      final driveApi = _driveApi!;

      // 搜尋現有資料夾
      final folderList = await driveApi.files.list(
        q: "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        final firstFolder = folderList.files!.first;
        if (firstFolder.id == null) {
          return Result.failure(const StorageException('備份資料夾 ID 無效'));
        }
        AppLogger.info('Found existing backup folder: ${firstFolder.id}', tag: 'GoogleDrive');
        return Result.success(firstFolder.id!);
      }

      // 建立新資料夾
      final folder = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(
        folder,
        $fields: 'id',
      );

      if (createdFolder.id == null) {
        return Result.failure(const StorageException('建立資料夾失敗：未取得 ID'));
      }

      AppLogger.info('Created backup folder: ${createdFolder.id}', tag: 'GoogleDrive');
      return Result.success(createdFolder.id!);
    } catch (e) {
      AppLogger.error('Failed to get/create backup folder', error: e, tag: 'GoogleDrive');
      return Result.failure(StorageException('無法建立備份資料夾: $e'));
    }
  }

  /// 上傳備份檔案
  ///
  /// 檔案大小超過 5MB 時使用 resumable upload
  Future<Result<DriveBackupInfo>> uploadBackup({
    required File file,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) async {
    final folderResult = await _getOrCreateBackupFolder();
    if (folderResult.isFailure) {
      return Result.failure((folderResult as Failure).error);
    }

    final folderId = folderResult.getOrThrow();

    try {
      final fileSize = await file.length();
      AppLogger.info(
        'Uploading backup: $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        tag: 'GoogleDrive',
      );

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = _backupMimeType;

      drive.File uploadedFile;

      if (fileSize > _resumableUploadThreshold) {
        // 使用 resumable upload
        uploadedFile = await _resumableUpload(
          driveFile: driveFile,
          file: file,
          fileSize: fileSize,
          onProgress: onProgress,
        );
      } else {
        // 使用簡單上傳
        final media = drive.Media(file.openRead(), fileSize);
        uploadedFile = await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
          $fields: 'id, name, createdTime, size',
        );
      }

      final backupInfo = DriveBackupInfo(
        id: uploadedFile.id!,
        name: uploadedFile.name!,
        createdTime: uploadedFile.createdTime ?? DateTime.now(),
        sizeBytes: int.tryParse(uploadedFile.size ?? '0') ?? fileSize,
      );

      AppLogger.info('Backup uploaded successfully: ${backupInfo.id}', tag: 'GoogleDrive');
      return Result.success(backupInfo);
    } catch (e) {
      AppLogger.error('Failed to upload backup', error: e, tag: 'GoogleDrive');
      return Result.failure(StorageException('上傳備份失敗: $e'));
    }
  }

  /// Resumable upload 實作
  Future<drive.File> _resumableUpload({
    required drive.File driveFile,
    required File file,
    required int fileSize,
    UploadProgressCallback? onProgress,
  }) async {
    // 使用 googleapis 的 resumable upload
    final media = drive.Media(
      file.openRead(),
      fileSize,
    );

    // 回報初始進度
    onProgress?.call(0, fileSize);

    final result = await _driveApi!.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, name, createdTime, size',
    );

    // 回報完成進度
    onProgress?.call(fileSize, fileSize);

    return result;
  }

  /// 列出備份檔案
  Future<Result<List<DriveBackupInfo>>> listBackups() async {
    final folderResult = await _getOrCreateBackupFolder();
    if (folderResult.isFailure) {
      return Result.failure((folderResult as Failure).error);
    }

    final folderId = folderResult.getOrThrow();

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$folderId' in parents and mimeType = '$_backupMimeType' and trashed = false",
        spaces: 'drive',
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );

      final backups = (fileList.files ?? [])
          .where((f) => f.id != null && f.name != null)
          .map((f) => DriveBackupInfo(
                id: f.id!,
                name: f.name!,
                createdTime: f.createdTime ?? DateTime.now(),
                sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
              ))
          .toList();

      AppLogger.info('Found ${backups.length} backups', tag: 'GoogleDrive');
      return Result.success(backups);
    } catch (e) {
      AppLogger.error('Failed to list backups', error: e, tag: 'GoogleDrive');
      return Result.failure(StorageException('無法列出備份: $e'));
    }
  }

  /// 下載備份檔案
  ///
  /// 回傳下載檔案的 bytes。對於大檔案，使用串流寫入暫存檔案以避免記憶體問題。
  Future<Result<Uint8List>> downloadBackup(String fileId) async {
    final authResult = await _ensureAuthenticated();
    if (authResult.isFailure) {
      return Result.failure((authResult as Failure).error);
    }

    try {
      AppLogger.info('Downloading backup: $fileId', tag: 'GoogleDrive');

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 使用暫存檔案串流寫入，避免大檔案記憶體問題
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}.tmp',
      );

      final sink = tempFile.openWrite();
      int totalBytes = 0;

      try {
        await for (final chunk in media.stream) {
          sink.add(chunk);
          totalBytes += chunk.length;
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // 讀取檔案內容
      final bytes = await tempFile.readAsBytes();

      // 清理暫存檔案
      try {
        await tempFile.delete();
      } catch (_) {
        // 忽略清理失敗
      }

      AppLogger.info(
        'Backup downloaded: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
        tag: 'GoogleDrive',
      );

      return Result.success(bytes);
    } catch (e) {
      AppLogger.error('Failed to download backup', error: e, tag: 'GoogleDrive');
      return Result.failure(StorageException('下載備份失敗: $e'));
    }
  }

  /// 刪除備份檔案
  Future<Result<void>> deleteBackup(String fileId) async {
    final authResult = await _ensureAuthenticated();
    if (authResult.isFailure) {
      return Result.failure((authResult as Failure).error);
    }

    try {
      AppLogger.info('Deleting backup: $fileId', tag: 'GoogleDrive');

      await _driveApi!.files.delete(fileId);

      AppLogger.info('Backup deleted successfully', tag: 'GoogleDrive');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Failed to delete backup', error: e, tag: 'GoogleDrive');
      return Result.failure(StorageException('刪除備份失敗: $e'));
    }
  }

  /// 嘗試恢復已登入狀態
  Future<Result<GoogleAccountInfo?>> tryRestoreSession() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentAccount = account;
        await _initDriveApi();

        AppLogger.info('Session restored: ${account.email}', tag: 'GoogleDrive');
        return Result.success(GoogleAccountInfo(
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        ));
      }

      return Result.success(null);
    } catch (e) {
      AppLogger.warning('Failed to restore session', tag: 'GoogleDrive');
      return Result.success(null); // 不視為錯誤
    }
  }
}

/// Google 認證 HTTP 客戶端
class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._accessToken);

  final String _accessToken;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
