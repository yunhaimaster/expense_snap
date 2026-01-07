/// App 異常基礎類別 - 使用 sealed class 確保窮盡匹配
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// 錯誤訊息
  final String message;

  /// 錯誤代碼（可選）
  final String? code;

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

/// 網絡相關異常
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    this.statusCode,
  });

  /// HTTP 狀態碼
  final int? statusCode;

  /// 無網絡連線
  factory NetworkException.noConnection() =>
      const NetworkException('無網絡連線', code: 'NO_CONNECTION');

  /// 請求逾時
  factory NetworkException.timeout() =>
      const NetworkException('請求逾時', code: 'TIMEOUT');

  /// 伺服器錯誤
  factory NetworkException.serverError({int? statusCode}) => NetworkException(
        '伺服器錯誤',
        code: 'SERVER_ERROR',
        statusCode: statusCode,
      );
}

/// 儲存相關異常
class StorageException extends AppException {
  const StorageException(super.message, {super.code});

  /// 儲存空間不足
  factory StorageException.insufficientSpace() =>
      const StorageException('儲存空間不足', code: 'INSUFFICIENT_SPACE');

  /// 檔案不存在
  factory StorageException.fileNotFound(String path) =>
      StorageException('檔案不存在: $path', code: 'FILE_NOT_FOUND');

  /// 無法寫入檔案
  factory StorageException.writeError(String path) =>
      StorageException('無法寫入檔案: $path', code: 'WRITE_ERROR');

  /// 無法讀取檔案
  factory StorageException.readError(String path) =>
      StorageException('無法讀取檔案: $path', code: 'READ_ERROR');

  /// 路徑不安全（目錄遍歷攻擊）
  factory StorageException.unsafePath(String path) =>
      StorageException('不安全的路徑: $path', code: 'UNSAFE_PATH');
}

/// 資料庫相關異常
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});

  /// 資料庫鎖定
  factory DatabaseException.locked() =>
      const DatabaseException('資料庫鎖定中', code: 'DB_LOCKED');

  /// 資料庫損壞
  factory DatabaseException.corrupted() =>
      const DatabaseException('資料庫損壞', code: 'DB_CORRUPTED');

  /// 查詢失敗
  factory DatabaseException.queryFailed(String reason) =>
      DatabaseException('查詢失敗: $reason', code: 'QUERY_FAILED');

  /// 插入失敗
  factory DatabaseException.insertFailed(String reason) =>
      DatabaseException('插入失敗: $reason', code: 'INSERT_FAILED');

  /// 更新失敗
  factory DatabaseException.updateFailed(String reason) =>
      DatabaseException('更新失敗: $reason', code: 'UPDATE_FAILED');

  /// 刪除失敗
  factory DatabaseException.deleteFailed(String reason) =>
      DatabaseException('刪除失敗: $reason', code: 'DELETE_FAILED');
}

/// 驗證相關異常
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, this.field});

  /// 驗證失敗的欄位名稱
  final String? field;

  /// 必填欄位為空
  factory ValidationException.required(String field) =>
      ValidationException('$field 為必填欄位', code: 'REQUIRED', field: field);

  /// 數值超出範圍
  factory ValidationException.outOfRange(String field, num min, num max) =>
      ValidationException(
        '$field 必須介於 $min 和 $max 之間',
        code: 'OUT_OF_RANGE',
        field: field,
      );

  /// 長度超出限制
  factory ValidationException.lengthExceeded(String field, int maxLength) =>
      ValidationException(
        '$field 長度不得超過 $maxLength 個字元',
        code: 'LENGTH_EXCEEDED',
        field: field,
      );

  /// 格式不正確
  factory ValidationException.invalidFormat(String field) =>
      ValidationException('$field 格式不正確', code: 'INVALID_FORMAT', field: field);

  /// 日期不合法
  factory ValidationException.invalidDate(String field) =>
      ValidationException('$field 日期不合法', code: 'INVALID_DATE', field: field);
}

/// 認證相關異常
class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  /// 未登入
  factory AuthException.notSignedIn() =>
      const AuthException('尚未登入', code: 'NOT_SIGNED_IN');

  /// 登入取消
  factory AuthException.cancelled() =>
      const AuthException('登入已取消', code: 'CANCELLED');

  /// Token 過期
  factory AuthException.tokenExpired() =>
      const AuthException('授權已過期，請重新登入', code: 'TOKEN_EXPIRED');

  /// 權限不足
  factory AuthException.insufficientPermission() =>
      const AuthException('權限不足', code: 'INSUFFICIENT_PERMISSION');
}

/// 匯出相關異常
class ExportException extends AppException {
  const ExportException(super.message, {super.code});

  /// 無資料可匯出
  factory ExportException.noData() =>
      const ExportException('無資料可匯出', code: 'NO_DATA');

  /// Excel 生成失敗
  factory ExportException.excelGenerationFailed(String reason) =>
      ExportException('Excel 生成失敗: $reason', code: 'EXCEL_FAILED');

  /// ZIP 壓縮失敗
  factory ExportException.zipFailed(String reason) =>
      ExportException('ZIP 壓縮失敗: $reason', code: 'ZIP_FAILED');

  /// 分享失敗
  factory ExportException.shareFailed() =>
      const ExportException('分享失敗', code: 'SHARE_FAILED');
}

/// 圖片處理相關異常
class ImageException extends AppException {
  const ImageException(super.message, {super.code});

  /// 圖片壓縮失敗
  factory ImageException.compressionFailed() =>
      const ImageException('圖片壓縮失敗', code: 'COMPRESSION_FAILED');

  /// 縮圖生成失敗
  factory ImageException.thumbnailFailed() =>
      const ImageException('縮圖生成失敗', code: 'THUMBNAIL_FAILED');

  /// 圖片格式不支援
  factory ImageException.unsupportedFormat() =>
      const ImageException('不支援的圖片格式', code: 'UNSUPPORTED_FORMAT');

  /// 圖片損壞
  factory ImageException.corrupted() =>
      const ImageException('圖片已損壞', code: 'CORRUPTED');
}

/// OCR 文字識別相關異常
class OcrException extends AppException {
  const OcrException(super.message, {super.code});

  /// 識別超時
  factory OcrException.timeout() =>
      const OcrException('文字識別超時', code: 'OCR_TIMEOUT');

  /// 無法識別文字
  factory OcrException.noTextFound() =>
      const OcrException('無法識別文字', code: 'NO_TEXT_FOUND');
}
