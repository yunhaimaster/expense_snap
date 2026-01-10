/// App 全域常數定義
class AppConstants {
  AppConstants._();

  // App 資訊
  static const String appName = 'Expense Snap';
  static const String appVersion = '1.2.0';

  // 圖片設定
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1080;
  static const int imageQuality = 75;
  static const int thumbnailSize = 200;

  // 快取設定
  static const int thumbnailCacheSizeMb = 50;
  static const Duration exchangeRateCacheDuration = Duration(hours: 24);
  static const Duration minExchangeRateRefreshInterval = Duration(seconds: 30);

  // 資料保留期限
  static const int deletedExpenseRetentionDays = 30;
  static const Duration cleanupCheckInterval = Duration(days: 7);

  // 分頁設定
  static const int defaultPageSize = 20;

  // 圖片儲存路徑格式
  static const String receiptFolderName = 'receipts';
  static const String fullImageSuffix = '_full.jpg';
  static const String thumbnailSuffix = '_thumb.jpg';

  // 匯出檔案格式
  static const String exportExcelFilename = 'expense_report';
  static const String exportZipFilename = 'expense_backup';

  // 預設使用者名稱
  static const String defaultUserName = '員工';

  // UUID 設定
  /// 短 UUID 長度（用於檔案命名等場景）
  static const int shortUuidLength = 8;

  // 金額閾值
  /// 大額支出警告閾值（以分為單位，100000 分 = 1000 元）
  static const int largeAmountThresholdCents = 100000;

  // 超時設定
  /// 圖片處理超時
  static const Duration imageProcessingTimeout = Duration(seconds: 5);

  /// OCR 處理超時
  static const Duration ocrTimeout = Duration(seconds: 5);

  /// OCR 速率限制間隔
  static const Duration ocrRateLimitInterval = Duration(seconds: 2);

  /// 一般操作超時
  static const Duration defaultOperationTimeout = Duration(seconds: 10);

  /// 資料庫操作超時
  static const Duration databaseOperationTimeout = Duration(seconds: 30);

  // 麵包屑設定
  /// 最大麵包屑數量
  static const int maxBreadcrumbs = 10;

  // 重試設定
  /// API 最大重試次數
  static const int maxApiRetries = 3;

  /// 重試延遲
  static const Duration retryDelay = Duration(seconds: 1);

  // 背景服務
  /// 背景清理任務名稱
  static const String cleanupTaskId = 'expense_snap_cleanup';
  static const String cleanupTaskName = 'cleanupExpiredExpenses';
}
