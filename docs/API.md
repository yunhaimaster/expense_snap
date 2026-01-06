# API Documentation

## Core Models

### Expense

支出記錄資料模型。金額以「分」儲存避免浮點誤差。

```dart
class Expense {
  final int? id;                    // 資料庫 ID（新建時為 null）
  final DateTime date;              // 支出日期
  final int originalAmountCents;    // 原始金額（分）
  final String originalCurrency;    // 原始幣種 (HKD/CNY/USD)
  final int exchangeRate;           // 匯率（×10⁶ 精度）
  final ExchangeRateSource exchangeRateSource;
  final int hkdAmountCents;         // 港幣金額（分）
  final String description;         // 描述
  final String? receiptImagePath;   // 原圖路徑
  final String? thumbnailPath;      // 縮圖路徑
  final bool isDeleted;             // 軟刪除標記
  final DateTime? deletedAt;        // 刪除時間
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Computed Properties:**
- `originalAmount` - 原始金額（元）
- `hkdAmount` - 港幣金額（元）
- `formattedOriginalAmount` - 格式化原始金額
- `formattedHkdAmount` - 格式化港幣金額
- `hasReceipt` - 是否有收據圖片
- `daysUntilPermanentDelete` - 距離永久刪除天數

---

### MonthSummary

月份摘要資料。

```dart
class MonthSummary {
  final int year;
  final int month;
  final int totalCount;
  final int totalHkdAmountCents;
}
```

---

## Repositories

### IExpenseRepository

支出資料存取介面。

```dart
abstract class IExpenseRepository {
  // 查詢
  Future<Result<List<Expense>>> getExpensesByMonth(int year, int month);
  Future<Result<Expense?>> getExpenseById(int id);
  Future<Result<MonthSummary>> getMonthSummary(int year, int month);
  Future<Result<List<Expense>>> getDeletedExpenses();

  // 新增/更新
  Future<Result<Expense>> createExpense(Expense expense);
  Future<Result<Expense>> updateExpense(Expense expense);

  // 刪除
  Future<Result<void>> softDeleteExpense(int id);
  Future<Result<void>> restoreExpense(int id);
  Future<Result<void>> permanentlyDeleteExpense(int id);
  Future<Result<int>> cleanupExpiredDeletedExpenses();
}
```

### ExchangeRateRepository

匯率查詢與快取。

```dart
class ExchangeRateRepository {
  // 取得匯率（優先快取，次網路）
  Future<Result<double>> getExchangeRate(String from, String to);

  // 強制刷新
  Future<Result<double>> refreshExchangeRate(String from, String to);

  // 快取管理
  Future<void> clearCache();
}
```

### BackupRepository

Google Drive 備份。

```dart
class BackupRepository {
  // 認證
  Future<Result<bool>> signIn();
  Future<Result<void>> signOut();
  Future<bool> get isSignedIn;

  // 備份
  Future<Result<BackupStatus>> backup();
  Future<Result<void>> restore();
  Future<Result<BackupStatus?>> getLastBackupStatus();
}
```

---

## Providers

### ExpenseProvider

支出列表狀態管理。

```dart
class ExpenseProvider extends ChangeNotifier {
  // 狀態
  List<Expense> get expenses;
  MonthSummary get currentMonthSummary;
  bool get isLoading;
  String? get errorMessage;

  // 月份導航
  int get selectedYear;
  int get selectedMonth;
  void selectMonth(int year, int month);
  void goToPreviousMonth();
  void goToNextMonth();

  // 操作
  Future<void> loadExpenses();
  Future<Result<Expense>> addExpense(Expense expense);
  Future<Result<void>> deleteExpense(int id);
  Future<Result<void>> restoreExpense(int id);
}
```

### ExchangeRateProvider

匯率狀態管理。

```dart
class ExchangeRateProvider extends ChangeNotifier {
  // 狀態
  double? getRate(String from, String to);
  bool get isLoading;
  bool get isOffline;

  // 操作
  Future<void> fetchRate(String from, String to);
  Future<void> refreshRate(String from, String to);
}
```

### SettingsProvider

應用程式設定。

```dart
class SettingsProvider extends ChangeNotifier {
  // 設定值
  String get defaultCurrency;
  bool get autoBackupEnabled;
  BackupStatus? get lastBackupStatus;

  // 操作
  Future<void> setDefaultCurrency(String currency);
  Future<void> setAutoBackup(bool enabled);
  Future<Result<void>> performBackup();
  Future<Result<void>> performRestore();
}
```

### ConnectivityProvider

網路狀態。

```dart
class ConnectivityProvider extends ChangeNotifier {
  bool get isOnline;
  ConnectivityResult get connectivityResult;
}
```

### ThemeProvider

主題切換。

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode;  // system, light, dark
  ThemeMode get materialThemeMode;

  void setThemeMode(ThemeMode mode);
}
```

---

## Services

### ImageService

圖片處理服務。

```dart
class ImageService {
  // 壓縮並儲存
  Future<String?> saveReceiptImage(String sourcePath);

  // 生成縮圖
  Future<String?> generateThumbnail(String imagePath);

  // 刪除圖片
  Future<void> deleteImage(String? path);

  // 清理臨時檔案
  Future<void> cleanupTempFiles();
}
```

**壓縮規格:**
- 原圖: 1920×1080, 85% quality
- 縮圖: 200px width

### ExportService

Excel 匯出服務。

```dart
class ExportService {
  // 匯出月份報銷單
  Future<Result<String>> exportMonthlyReport(
    int year,
    int month,
    List<Expense> expenses,
  );

  // 分享匯出檔案
  Future<void> shareExportedFile(String filePath);
}
```

**匯出格式:**
- Excel (.xlsx) 含支出明細
- ZIP 包含收據圖片
- 檔名: `報銷單_YYYY年MM月.zip`

### BackgroundService

背景任務（WorkManager）。

```dart
// 任務 ID
static const String cleanupTaskId = 'expense_cleanup';
static const String cleanupTaskName = 'cleanup_deleted_expenses';

// WorkManager callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 清理過期刪除項目
    // 清理臨時檔案
  });
}
```

---

## Error Handling

### Result<T>

函數式錯誤處理。

```dart
sealed class Result<T> {
  const Result();

  // 建構
  factory Result.success(T value);
  factory Result.failure(AppException exception);

  // 解構
  T? get valueOrNull;
  AppException? get exceptionOrNull;
  bool get isSuccess;
  bool get isFailure;

  // 變換
  Result<R> map<R>(R Function(T) transform);
  Result<R> flatMap<R>(Result<R> Function(T) transform);

  // 處理
  R fold<R>({
    required R Function(AppException) onFailure,
    required R Function(T) onSuccess,
  });
}
```

### AppException

應用程式例外。

```dart
class AppException implements Exception {
  final String code;
  final String message;
  final Object? originalError;

  // 預定義錯誤碼
  static const networkError = 'NETWORK_ERROR';
  static const databaseError = 'DATABASE_ERROR';
  static const validationError = 'VALIDATION_ERROR';
  static const authError = 'AUTH_ERROR';
}
```

---

## External APIs

### Exchange Rate API

**Primary:**
```
GET https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{base}.json
```

**Fallback:**
```
GET https://latest.currency-api.pages.dev/v1/currencies/{base}.json
```

**Response:**
```json
{
  "date": "2026-01-06",
  "hkd": {
    "cny": 0.92,
    "usd": 0.128
  }
}
```

### Google Drive API

- **Auth**: OAuth 2.0 (google_sign_in)
- **Scopes**: `drive.appdata`
- **Backup file**: JSON in app data folder
- **Token storage**: flutter_secure_storage

---

## Database Schema

### expenses

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| date | TEXT | ISO 8601 日期 |
| original_amount | INTEGER | 原始金額（分） |
| original_currency | TEXT | 幣種 |
| exchange_rate | INTEGER | 匯率（×10⁶） |
| exchange_rate_source | TEXT | 匯率來源 |
| hkd_amount | INTEGER | 港幣金額（分） |
| description | TEXT | 描述 |
| receipt_image_path | TEXT | 原圖路徑 |
| thumbnail_path | TEXT | 縮圖路徑 |
| is_deleted | INTEGER | 軟刪除 (0/1) |
| deleted_at | TEXT | 刪除時間 |
| created_at | TEXT | 建立時間 |
| updated_at | TEXT | 更新時間 |

### exchange_rate_cache

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| from_currency | TEXT | 來源幣種 |
| to_currency | TEXT | 目標幣種 |
| rate | INTEGER | 匯率（×10⁶） |
| fetched_at | TEXT | 抓取時間 |

### settings

| Column | Type | Description |
|--------|------|-------------|
| key | TEXT | Primary key |
| value | TEXT | 設定值 |
