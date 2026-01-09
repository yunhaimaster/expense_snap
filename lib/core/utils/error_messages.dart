/// 錯誤代碼對應用戶友善訊息的映射表
///
/// 將技術性的錯誤代碼轉換為用戶能理解的繁體中文訊息
class ErrorMessages {
  ErrorMessages._();

  /// 錯誤代碼對應的用戶友善訊息
  static const Map<String, String> _codeToMessage = {
    // 網絡錯誤
    'NO_CONNECTION': '請檢查網絡連線後再試',
    'TIMEOUT': '請求逾時，請稍後再試',
    'SERVER_ERROR': '伺服器暫時無法回應，請稍後再試',

    // 儲存錯誤
    'INSUFFICIENT_SPACE': '儲存空間不足，請清理後再試',
    'FILE_NOT_FOUND': '找不到檔案，請重新操作',
    'WRITE_ERROR': '無法儲存檔案，請檢查權限',
    'READ_ERROR': '無法讀取檔案，請重新操作',
    'UNSAFE_PATH': '檔案路徑不安全，操作已取消',

    // 資料庫錯誤
    'DB_LOCKED': '資料正在處理中，請稍後再試',
    'DB_CORRUPTED': '資料庫損壞，請嘗試從備份還原',
    'QUERY_FAILED': '查詢資料失敗，請重新操作',
    'INSERT_FAILED': '儲存資料失敗，請重新操作',
    'UPDATE_FAILED': '更新資料失敗，請重新操作',
    'DELETE_FAILED': '刪除資料失敗，請重新操作',

    // 驗證錯誤
    'REQUIRED': '請填寫必填欄位',
    'OUT_OF_RANGE': '輸入的數值超出有效範圍',
    'LENGTH_EXCEEDED': '輸入的內容過長',
    'INVALID_FORMAT': '輸入的格式不正確',
    'INVALID_DATE': '請選擇有效的日期',
    'INVALID_MONTH': '月份必須介於 1 到 12 之間',
    'INVALID_YEAR': '年份必須介於 2000 到 2100 之間',

    // 認證錯誤
    'NOT_SIGNED_IN': '請先登入 Google 帳號',
    'CANCELLED': '操作已取消',
    'TOKEN_EXPIRED': '登入已過期，請重新登入',
    'INSUFFICIENT_PERMISSION': '權限不足，請重新授權',

    // 匯出錯誤
    'NO_DATA': '沒有資料可以匯出',
    'EXCEL_FAILED': 'Excel 檔案生成失敗，請重新操作',
    'ZIP_FAILED': 'ZIP 壓縮失敗，請重新操作',
    'SHARE_FAILED': '分享失敗，請重新操作',

    // 圖片錯誤
    'COMPRESSION_FAILED': '圖片壓縮失敗，請選擇其他圖片',
    'THUMBNAIL_FAILED': '縮圖生成失敗',
    'UNSUPPORTED_FORMAT': '不支援此圖片格式',
    'CORRUPTED': '圖片已損壞，請選擇其他圖片',
  };

  /// 根據錯誤代碼獲取用戶友善訊息
  ///
  /// [code] 錯誤代碼
  /// [fallbackMessage] 如果找不到對應訊息，使用此備用訊息
  static String getMessage(String? code, {String? fallbackMessage}) {
    if (code == null) {
      return fallbackMessage ?? '發生未知錯誤';
    }
    return _codeToMessage[code] ?? fallbackMessage ?? '發生未知錯誤';
  }

  /// 根據錯誤代碼判斷是否可重試
  static bool isRetryable(String? code) {
    const retryableCodes = {
      'NO_CONNECTION',
      'TIMEOUT',
      'SERVER_ERROR',
      'DB_LOCKED',
      'QUERY_FAILED',
    };
    return code != null && retryableCodes.contains(code);
  }

  /// 根據錯誤代碼獲取建議動作
  static String? getSuggestedAction(String? code) {
    const actionMap = {
      'NO_CONNECTION': '請連接網絡後點擊重試',
      'INSUFFICIENT_SPACE': '請刪除一些檔案後重試',
      'DB_CORRUPTED': '前往設定頁面從雲端備份還原',
      'TOKEN_EXPIRED': '前往設定頁面重新登入',
      'INSUFFICIENT_PERMISSION': '前往設定頁面重新授權',
    };
    return actionMap[code];
  }
}
