/// App 全域常數定義
class AppConstants {
  AppConstants._();

  // App 資訊
  static const String appName = 'Expense Snap';
  static const String appVersion = '1.0.0';

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
}
