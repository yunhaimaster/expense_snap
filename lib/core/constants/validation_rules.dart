/// 輸入驗證規則常數
class ValidationRules {
  ValidationRules._();

  // 金額驗證
  static const double minAmount = 0.01;
  static const double maxAmount = 9999999.99;
  static const int maxDecimalPlaces = 2;

  // 描述驗證
  static const int minDescriptionLength = 1;
  static const int maxDescriptionLength = 500;

  // 匯率驗證（手動輸入）
  static const double minExchangeRate = 0.0001;
  static const double maxExchangeRate = 9999.9999;
  static const int maxExchangeRateDecimalPlaces = 4;

  // 使用者名稱驗證
  static const int minUserNameLength = 1;
  static const int maxUserNameLength = 50;

  // 檔案路徑驗證（安全性）
  static const List<String> forbiddenPathPatterns = [
    '..',       // 目錄遍歷
    '//',       // 雙斜線
    '~',        // Home 目錄
    '\\',       // Windows 反斜線
    '\x00',     // Null byte 攻擊
    '%2e',      // URL 編碼的 .
    '%2E',      // URL 編碼的 . (大寫)
    '%2f',      // URL 編碼的 /
    '%2F',      // URL 編碼的 / (大寫)
  ];

  // 安全檔案名稱正則（僅限 ASCII 字母數字、底線、連字符、點）
  static final RegExp safeFileNamePattern = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
}
