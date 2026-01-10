import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/path_validator.dart';

/// 圖片處理服務
///
/// 負責：
/// - 從相機/相簿獲取圖片
/// - 壓縮圖片至指定尺寸
/// - 移除 EXIF metadata（保護隱私）
/// - 生成縮圖
/// - 管理圖片儲存路徑
class ImageService {
  ImageService({
    ImagePicker? picker,
    this.processingTimeout = AppConstants.imageProcessingTimeout,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const _uuid = Uuid();

  /// 圖片處理超時時間
  final Duration processingTimeout;

  /// 從相機拍照
  Future<Result<String>> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        // 使用者取消
        return Result.failure(
          const StorageException('使用者取消拍照', code: 'CANCELLED'),
        );
      }

      return Result.success(image.path);
    } catch (e) {
      AppLogger.error('pickFromCamera failed', error: e);
      return Result.failure(
        StorageException('無法開啟相機: $e', code: 'CAMERA_ERROR'),
      );
    }
  }

  /// 從相簿選擇
  Future<Result<String>> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        // 使用者取消
        return Result.failure(
          const StorageException('使用者取消選擇', code: 'CANCELLED'),
        );
      }

      return Result.success(image.path);
    } catch (e) {
      AppLogger.error('pickFromGallery failed', error: e);
      return Result.failure(
        StorageException('無法開啟相簿: $e', code: 'GALLERY_ERROR'),
      );
    }
  }

  /// 處理收據圖片
  ///
  /// 步驟：
  /// 1. 讀取原圖
  /// 2. 移除 EXIF metadata
  /// 3. 壓縮至 1920x1080
  /// 4. 生成 200x200 縮圖
  /// 5. 儲存至 app 私有目錄
  ///
  /// 回傳：包含原圖和縮圖路徑的結果
  Future<Result<ProcessedImagePaths>> processReceiptImage({
    required String sourcePath,
    required DateTime expenseDate,
  }) async {
    try {
      // 驗證來源檔案
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return Result.failure(StorageException.fileNotFound(sourcePath));
      }

      // 生成檔名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4().substring(0, AppConstants.shortUuidLength);
      final monthFolder = _formatMonthFolder(expenseDate);

      final fullFileName = '${timestamp}_$uniqueId${AppConstants.fullImageSuffix}';
      final thumbFileName = '${timestamp}_$uniqueId${AppConstants.thumbnailSuffix}';

      // 建立目標路徑
      final fullPath = PathValidator.buildSafeImagePath(
        subFolder: monthFolder,
        fileName: fullFileName,
      );
      final thumbPath = PathValidator.buildSafeImagePath(
        subFolder: monthFolder,
        fileName: thumbFileName,
      );

      // 確保目錄存在
      final directory = Directory(
        '${PathValidator.appDocDir.path}/${AppConstants.receiptFolderName}/$monthFolder',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 處理圖片
      // 優先在 isolate 中執行避免阻塞 UI，失敗時回退到主線程
      final params = _ProcessImageParams(
        sourcePath: sourcePath,
        fullPath: fullPath,
        thumbPath: thumbPath,
        maxWidth: AppConstants.imageMaxWidth,
        maxHeight: AppConstants.imageMaxHeight,
        quality: AppConstants.imageQuality,
        thumbnailSize: AppConstants.thumbnailSize,
      );

      _ProcessImageResult result;
      try {
        result = await compute(_processImageIsolate, params)
            .timeout(processingTimeout);

        // 若 isolate 內部因 UnimplementedError 失敗，回退到主線程重試
        if (!result.success && result.error?.contains('UnimplementedError') == true) {
          AppLogger.warning('Isolate image processing not supported, retrying on main thread');
          result = await _processImageMainThread(params)
              .timeout(processingTimeout);
        }
      } on TimeoutException {
        // 超時不回退到主線程，直接返回超時錯誤
        AppLogger.warning('Image processing timeout after ${processingTimeout.inSeconds}s');
        return Result.failure(ImageException.processingTimeout());
      } catch (e) {
        // Isolate 執行本身失敗，回退到主線程（含超時）
        AppLogger.warning('Isolate image processing failed, falling back to main thread: $e');
        try {
          result = await _processImageMainThread(params)
              .timeout(processingTimeout);
        } on TimeoutException {
          AppLogger.warning('Main thread image processing timeout after ${processingTimeout.inSeconds}s');
          return Result.failure(ImageException.processingTimeout());
        }
      }

      if (!result.success) {
        return Result.failure(ImageException(result.error ?? '圖片處理失敗'));
      }

      AppLogger.info(
        'Image processed: full=${result.fullSize}KB, thumb=${result.thumbSize}KB',
      );

      return Result.success(ProcessedImagePaths(
        fullPath: fullPath,
        thumbnailPath: thumbPath,
      ));
    } catch (e) {
      AppLogger.error('processReceiptImage failed', error: e);
      return Result.failure(
        ImageException('圖片處理失敗: $e', code: 'PROCESS_FAILED'),
      );
    }
  }

  /// 刪除圖片檔案
  Future<Result<void>> deleteImages({
    required String? fullPath,
    required String? thumbnailPath,
  }) async {
    try {
      if (fullPath != null && fullPath.isNotEmpty) {
        await _deleteFileIfExists(fullPath);
      }
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        await _deleteFileIfExists(thumbnailPath);
      }
      return Result.success(null);
    } catch (e) {
      AppLogger.error('deleteImages failed', error: e);
      return Result.failure(
        StorageException('刪除圖片失敗: $e', code: 'DELETE_FAILED'),
      );
    }
  }

  /// 驗證圖片是否存在
  Future<bool> imageExists(String? path) async {
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }

  /// 取得圖片檔案大小（KB）
  Future<int> getImageSizeKb(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.length();
        return (bytes / 1024).round();
      }
      return 0;
    } catch (e) {
      AppLogger.warning('getImageSizeKb failed for path: $path', error: e);
      return 0;
    }
  }

  /// 格式化月份資料夾名稱
  String _formatMonthFolder(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  /// 清理匯出臨時檔案
  ///
  /// 刪除暫存目錄中超過 24 小時的檔案
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = Directory('${PathValidator.appDocDir.path}/export_temp');
      if (!await tempDir.exists()) return;

      final now = DateTime.now();
      final files = await tempDir.list().toList();

      for (final entity in files) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);

            // 刪除超過 24 小時的臨時檔案
            if (age.inHours >= 24) {
              await entity.delete();
              AppLogger.debug('Deleted temp file: ${entity.path}');
            }
          } catch (e) {
            AppLogger.warning('Failed to delete temp file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to cleanup temp files: $e');
    }
  }

  /// 刪除檔案（如果存在）
  Future<void> _deleteFileIfExists(String path) async {
    // 驗證路徑安全性
    if (!PathValidator.isPathSafe(path)) {
      AppLogger.warning('Attempted to delete unsafe path: $path');
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      AppLogger.debug('Deleted file: $path');
    }
  }
}

/// 處理後的圖片路徑
class ProcessedImagePaths {
  const ProcessedImagePaths({
    required this.fullPath,
    required this.thumbnailPath,
  });

  final String fullPath;
  final String thumbnailPath;
}

// ============ Isolate 處理相關 ============

/// 圖片處理參數
class _ProcessImageParams {
  const _ProcessImageParams({
    required this.sourcePath,
    required this.fullPath,
    required this.thumbPath,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.thumbnailSize,
  });

  final String sourcePath;
  final String fullPath;
  final String thumbPath;
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int thumbnailSize;
}

/// 圖片處理結果
class _ProcessImageResult {
  const _ProcessImageResult({
    required this.success,
    this.error,
    this.fullSize,
    this.thumbSize,
  });

  final bool success;
  final String? error;
  final int? fullSize;
  final int? thumbSize;
}

/// 共用圖片處理邏輯（供 isolate 和主線程使用）
///
/// 步驟：
/// 1. 讀取原圖
/// 2. 壓縮原圖並移除 EXIF（保護隱私）
/// 3. 儲存壓縮後的原圖
/// 4. 生成縮圖
/// 5. 儲存縮圖
Future<_ProcessImageResult> _processImageCore(_ProcessImageParams params) async {
  try {
    // 讀取原圖
    final sourceBytes = await File(params.sourcePath).readAsBytes();

    // 壓縮原圖（flutter_image_compress 會自動處理 EXIF）
    final compressedBytes = await FlutterImageCompress.compressWithList(
      sourceBytes,
      minWidth: params.maxWidth,
      minHeight: params.maxHeight,
      quality: params.quality,
      format: CompressFormat.jpeg,
      // 自動旋轉但不保留 EXIF（移除 GPS 等隱私資訊）
      autoCorrectionAngle: true,
      keepExif: false,
    );

    if (compressedBytes.isEmpty) {
      return const _ProcessImageResult(
        success: false,
        error: '圖片壓縮失敗',
      );
    }

    // 儲存壓縮後的原圖
    await File(params.fullPath).writeAsBytes(compressedBytes);

    // 生成縮圖
    final thumbnailBytes = await FlutterImageCompress.compressWithList(
      compressedBytes,
      minWidth: params.thumbnailSize,
      minHeight: params.thumbnailSize,
      quality: 80,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (thumbnailBytes.isEmpty) {
      return const _ProcessImageResult(
        success: false,
        error: '縮圖生成失敗',
      );
    }

    // 儲存縮圖
    await File(params.thumbPath).writeAsBytes(thumbnailBytes);

    return _ProcessImageResult(
      success: true,
      fullSize: (compressedBytes.length / 1024).round(),
      thumbSize: (thumbnailBytes.length / 1024).round(),
    );
  } catch (e) {
    return _ProcessImageResult(
      success: false,
      error: e.toString(),
    );
  }
}

/// 在 isolate 中處理圖片
Future<_ProcessImageResult> _processImageIsolate(_ProcessImageParams params) async {
  return _processImageCore(params);
}

/// 主線程版本的圖片處理（備援方案）
///
/// 當 isolate 不支援時使用此方法
Future<_ProcessImageResult> _processImageMainThread(_ProcessImageParams params) async {
  return _processImageCore(params);
}
