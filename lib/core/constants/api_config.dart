/// API 設定常數
class ApiConfig {
  ApiConfig._();

  // 匯率 API（主要）
  static const String primaryExchangeRateApi =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';

  // 匯率 API（備用）
  static const String fallbackExchangeRateApi =
      'https://latest.currency-api.pages.dev/v1/currencies';

  // 請求逾時設定
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // 重試設定
  static const int retryAttempts = 2;
  static const Duration retryDelay = Duration(seconds: 1);

  // Google Drive API
  static const String googleDriveScope =
      'https://www.googleapis.com/auth/drive.file';
  static const String driveAppFolderName = 'ExpenseSnap';

  // 大檔案上傳閾值（超過此大小使用 resumable upload）
  static const int resumableUploadThreshold = 5 * 1024 * 1024; // 5MB
}
