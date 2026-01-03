import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/validation_rules.dart';
import '../errors/app_exception.dart';

/// 路徑驗證工具（防止目錄遍歷攻擊）
class PathValidator {
  PathValidator._();

  /// 應用程式文件目錄（快取）
  static Directory? _appDocDir;

  /// 初始化（在 app 啟動時呼叫）
  static Future<void> initialize() async {
    _appDocDir = await getApplicationDocumentsDirectory();
  }

  /// 取得應用程式文件目錄
  static Directory get appDocDir {
    if (_appDocDir == null) {
      throw StateError('PathValidator 尚未初始化，請先呼叫 initialize()');
    }
    return _appDocDir!;
  }

  /// 驗證路徑是否安全（不包含目錄遍歷攻擊）
  static bool isPathSafe(String path) {
    // 先將路徑轉為小寫進行 case-insensitive 檢查
    final lowerPath = path.toLowerCase();

    // 檢查禁止的模式（包含 URL 編碼繞過攻擊）
    for (final pattern in ValidationRules.forbiddenPathPatterns) {
      if (lowerPath.contains(pattern.toLowerCase())) {
        return false;
      }
    }

    // 檢查是否包含控制字元
    if (path.codeUnits.any((c) => c < 32 || c == 127)) {
      return false;
    }

    // 正規化路徑後檢查是否仍在 app 目錄下
    final normalizedPath = _normalizePath(path);
    final appPath = appDocDir.path;

    return normalizedPath.startsWith(appPath);
  }

  /// 驗證路徑，不安全時拋出異常
  static void validatePath(String path) {
    if (!isPathSafe(path)) {
      throw StorageException.unsafePath(path);
    }
  }

  /// 建立安全的圖片路徑
  ///
  /// [subFolder] - 子目錄（例如：2025-01）
  /// [fileName] - 檔案名稱（例如：1704278400000_abc123_full.jpg）
  static String buildSafeImagePath({
    required String subFolder,
    required String fileName,
  }) {
    // 驗證子目錄名稱格式（只允許 yyyy-MM）
    if (!_isValidMonthFolder(subFolder)) {
      throw StorageException.unsafePath('Invalid subfolder: $subFolder');
    }

    // 驗證檔案名稱（只允許字母、數字、底線、點）
    if (!_isValidFileName(fileName)) {
      throw StorageException.unsafePath('Invalid filename: $fileName');
    }

    return '${appDocDir.path}/receipts/$subFolder/$fileName';
  }

  /// 驗證月份目錄格式
  static bool _isValidMonthFolder(String folder) {
    // 格式：yyyy-MM
    final regex = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    return regex.hasMatch(folder);
  }

  /// 驗證檔案名稱
  static bool _isValidFileName(String fileName) {
    // 使用嚴格的 ASCII 字元限制
    if (!ValidationRules.safeFileNamePattern.hasMatch(fileName)) {
      return false;
    }

    // 禁止連續的點（..）
    if (fileName.contains('..')) {
      return false;
    }

    // 禁止以點開頭（隱藏檔案）
    if (fileName.startsWith('.')) {
      return false;
    }

    // 檔名長度限制
    if (fileName.length > 255) {
      return false;
    }

    return true;
  }

  /// 正規化路徑（解析 .. 和 .）
  static String _normalizePath(String path) {
    final segments = path.split(Platform.pathSeparator);
    final normalized = <String>[];

    for (final segment in segments) {
      if (segment == '..') {
        if (normalized.isNotEmpty) {
          normalized.removeLast();
        }
      } else if (segment != '.' && segment.isNotEmpty) {
        normalized.add(segment);
      }
    }

    final result = normalized.join(Platform.pathSeparator);
    return path.startsWith(Platform.pathSeparator)
        ? '${Platform.pathSeparator}$result'
        : result;
  }

  /// 確保目錄存在
  static Future<Directory> ensureDirectoryExists(String path) async {
    validatePath(path);
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// 從完整路徑提取相對路徑（相對於 app 文件目錄）
  static String? extractRelativePath(String fullPath) {
    final appPath = appDocDir.path;
    if (fullPath.startsWith(appPath)) {
      return fullPath.substring(appPath.length);
    }
    return null;
  }
}
