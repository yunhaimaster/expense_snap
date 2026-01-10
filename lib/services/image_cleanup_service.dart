import 'dart:io';

import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/path_validator.dart';
import '../data/datasources/local/database_helper.dart';

/// 孤立圖片清理服務
///
/// 負責清理檔案系統中未被資料庫引用的圖片檔案
/// 主要用於清理：
/// - 支出刪除後未清理的圖片
/// - 圖片處理過程中產生的暫存檔案
/// - 任何其他孤立的圖片檔案
class ImageCleanupService {
  ImageCleanupService(this._db);

  final DatabaseHelper _db;

  /// receipts 資料夾名稱
  static const _receiptsFolderName = 'receipts';

  /// 上次清理時間的 SharedPreferences key
  static const lastCleanupKey = 'last_image_cleanup';

  /// 清理間隔（24 小時）
  static const cleanupInterval = Duration(hours: 24);

  /// 執行孤立圖片清理
  ///
  /// 返回清理結果，包含刪除的檔案數量和釋放的空間
  Future<Result<CleanupResult>> cleanupOrphanedImages() async {
    try {
      AppLogger.info('開始孤立圖片清理', tag: 'ImageCleanup');

      // 1. 取得 app 文件目錄
      final appDocDir = PathValidator.appDocDir;
      final receiptsDir = Directory('${appDocDir.path}/$_receiptsFolderName');
      if (!await receiptsDir.exists()) {
        AppLogger.info('receipts 目錄不存在，無需清理', tag: 'ImageCleanup');
        return Result.success(CleanupResult.empty());
      }

      // 2. 掃描檔案系統中的所有圖片
      final filesInSystem = await _scanReceiptsDirectory(receiptsDir);
      AppLogger.info(
        '檔案系統中找到 ${filesInSystem.length} 個圖片檔案',
        tag: 'ImageCleanup',
      );

      // 3. 取得資料庫中所有圖片路徑
      final pathsInDb = await _getAllImagePathsFromDb();
      AppLogger.info(
        '資料庫中引用 ${pathsInDb.length} 個圖片路徑',
        tag: 'ImageCleanup',
      );

      // 4. 找出孤立檔案（在檔案系統但不在資料庫中）
      final orphanedFiles = filesInSystem
          .where((file) => !pathsInDb.contains(file.path))
          .toList();

      if (orphanedFiles.isEmpty) {
        AppLogger.info('無孤立檔案需要清理', tag: 'ImageCleanup');
        return Result.success(CleanupResult.empty());
      }

      AppLogger.info(
        '發現 ${orphanedFiles.length} 個孤立檔案',
        tag: 'ImageCleanup',
      );

      // 5. 刪除孤立檔案
      var deletedCount = 0;
      var freedBytes = 0;

      for (final file in orphanedFiles) {
        try {
          final fileSize = await file.length();
          await file.delete();
          deletedCount++;
          freedBytes += fileSize;
          AppLogger.debug(
            '已刪除孤立檔案: ${file.path} (${_formatBytes(fileSize)})',
            tag: 'ImageCleanup',
          );
        } catch (e) {
          AppLogger.warning(
            '刪除檔案失敗: ${file.path} - $e',
            tag: 'ImageCleanup',
          );
        }
      }

      // 6. 清理空的子目錄
      await _cleanupEmptyDirectories(receiptsDir);

      final result = CleanupResult(
        deletedCount: deletedCount,
        freedBytes: freedBytes,
      );

      AppLogger.info(
        '清理完成：刪除 $deletedCount 個檔案，釋放 ${_formatBytes(freedBytes)}',
        tag: 'ImageCleanup',
      );

      return Result.success(result);
    } catch (e, stack) {
      AppLogger.error(
        '孤立圖片清理失敗',
        tag: 'ImageCleanup',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        StorageException('孤立圖片清理失敗: $e', code: 'CLEANUP_ERROR'),
      );
    }
  }

  /// 掃描 receipts 目錄中的所有圖片檔案
  Future<List<File>> _scanReceiptsDirectory(Directory dir) async {
    final files = <File>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final ext = entity.path.toLowerCase();
        if (ext.endsWith('.jpg') ||
            ext.endsWith('.jpeg') ||
            ext.endsWith('.png')) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// 從資料庫取得所有圖片路徑
  Future<Set<String>> _getAllImagePathsFromDb() async {
    final db = await _db.database;
    final paths = <String>{};

    // 查詢所有支出的圖片路徑（包含已刪除的）
    final result = await db.query(
      'expenses',
      columns: ['receipt_image_path', 'thumbnail_path'],
    );

    for (final row in result) {
      final fullPath = row['receipt_image_path'] as String?;
      final thumbPath = row['thumbnail_path'] as String?;

      if (fullPath != null && fullPath.isNotEmpty) {
        paths.add(fullPath);
      }
      if (thumbPath != null && thumbPath.isNotEmpty) {
        paths.add(thumbPath);
      }
    }

    return paths;
  }

  /// 清理空的子目錄
  Future<void> _cleanupEmptyDirectories(Directory dir) async {
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        // 遞迴清理子目錄
        await _cleanupEmptyDirectories(entity);

        // 檢查目錄是否為空
        final contents = await entity.list().toList();
        if (contents.isEmpty) {
          try {
            await entity.delete();
            AppLogger.debug(
              '已刪除空目錄: ${entity.path}',
              tag: 'ImageCleanup',
            );
          } catch (e) {
            AppLogger.warning(
              '刪除空目錄失敗: ${entity.path} - $e',
              tag: 'ImageCleanup',
            );
          }
        }
      }
    }
  }

  /// 格式化位元組大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 清理結果
class CleanupResult {
  const CleanupResult({
    required this.deletedCount,
    required this.freedBytes,
  });

  factory CleanupResult.empty() => const CleanupResult(
        deletedCount: 0,
        freedBytes: 0,
      );

  /// 刪除的檔案數量
  final int deletedCount;

  /// 釋放的空間（位元組）
  final int freedBytes;

  /// 是否有清理任何檔案
  bool get hasCleanup => deletedCount > 0;

  @override
  String toString() =>
      'CleanupResult(deletedCount: $deletedCount, freedBytes: $freedBytes)';
}
